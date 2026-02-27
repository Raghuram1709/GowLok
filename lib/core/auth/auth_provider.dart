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

    // Listen to auth state changes
    _authService.authStateChanges.listen((event) {
      _user = event.session?.user;
      _isAuthenticated = event.session != null;
      notifyListeners();
    });

    notifyListeners();
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      _user = response.user;
      _isAuthenticated = response.session != null;
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
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please confirm your email first';
    } else if (error.contains('User already registered')) {
      return 'Email already registered';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email';
    }
    return error;
  }
}
