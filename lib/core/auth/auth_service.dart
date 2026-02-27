import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService(this.supabase);

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => supabase.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  // Get current user email
  String? get currentUserEmail => currentUser?.email;

  // Email sign up
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (_) {
      rethrow;
    }
  }

  // Email sign in
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on SocketException catch (e) {
      // wrap and rethrow so provider can catch
      throw e;
    } catch (_) {
      rethrow;
    }
  }

  // Password reset
  Future<void> resetPassword({required String email}) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
    } catch (_) {
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (_) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {
      rethrow;
    }
  }

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

  // Get auth state changes
  Future<List<AuthState>> getAuthStateChanges() async {
    return supabase.auth.onAuthStateChange.toList();
  }
}
