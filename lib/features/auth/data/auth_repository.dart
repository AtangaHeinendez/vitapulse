import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Redirect target for auth emails (confirmation, password recovery) on
/// Android. Registered as a deep link in AndroidManifest and in the Supabase
/// dashboard's redirect URL allowlist.
const kAuthCallbackUrl = 'vitapulse://auth-callback';

abstract class AuthRepository {
  Session? get currentSession;
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;

  Future<AuthResponse> signUp({required String email, required String password});
  Future<AuthResponse> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> resendConfirmation(String email);
  Future<void> updatePassword(String newPassword);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  String? get _redirect => kIsWeb ? null : kAuthCallbackUrl;

  @override
  Session? get currentSession => _auth.currentSession;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  @override
  Future<AuthResponse> signUp({required String email, required String password}) =>
      _auth.signUp(email: email, password: password, emailRedirectTo: _redirect);

  @override
  Future<AuthResponse> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email, redirectTo: _redirect);

  @override
  Future<void> resendConfirmation(String email) =>
      _auth.resend(type: OtpType.signup, email: email);

  @override
  Future<void> updatePassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword));
}
