import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  // State variables
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => user?.email;

  // Initialize provider with current session
  void initialize() {
    _user = _authService.currentUser;
    _isAuthenticated = _authService.isAuthenticated;

    bool isFirstEvent = true;

    // Listen to auth state changes. We use WidgetsBinding to ensure we never
    // trigger a synchronous rebuild during an active frame, which would cause
    // a widget lifecycle assertion error.
    _authService.authStateChanges.listen((event) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _user = event.session?.user;
        _isAuthenticated = event.session != null;
        // Only notify if there are actual listeners attached to avoid unnecessary builds
        if (hasListeners) {
          notifyListeners();
        }
      });
    });
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      _user = response.user;
      _isAuthenticated = response.session != null;

      // The Supabase trigger creates a profile using only the email.
      // Update the new profile with the user's full name.
      if (_user != null) {
        try {
          await _authService.supabase
              .from('profiles')
              .update({'full_name': fullName.trim()})
              .eq('id', _user!.id);
        } catch (e) {
          debugPrint('Failed to update profile name: $e');
        }
      }

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.signInWithGoogle();
      // Browser OAuth handles redirect back to app which triggers authStateChange.
      _setLoading(false);
      return success;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _user = response.user;
      _isAuthenticated = response.session != null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(_parseAuthError(e.message));
      _setLoading(false);
      return false;
    } catch (e) {
      if (e is SocketException) {
        _setError('Network error – please check your internet connection.');
      } else {
        _setError(e.toString());
      }
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email: email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates the user's display name
  Future<void> updateUsername(String newName) async {
    _setLoading(true);
    _clearError();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      // Force a re-fetch of the session to get the latest metadata into _user
      // This will also trigger notifyListeners via the authStateChanges listener
      initialize();
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the user's avatar URL
  Future<void> updateAvatar(String publicUrl) async {
    _setLoading(true);
    _clearError();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      // Force a re-fetch of the session to get the latest metadata into _user
      initialize();
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Parse Supabase auth errors to user-friendly messages
  String _parseAuthError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Invalid email or password';
    } else if (lower.contains('email not confirmed') ||
               lower.contains('email_not_confirmed')) {
      return 'Please confirm your email first. Check your inbox for a confirmation link.';
    } else if (lower.contains('user already registered')) {
      return 'Email already registered';
    } else if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters';
    } else if (lower.contains('invalid email')) {
      return 'Please enter a valid email';
    } else if (lower.contains('too many requests') ||
               lower.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }
    return error;
  }
}
