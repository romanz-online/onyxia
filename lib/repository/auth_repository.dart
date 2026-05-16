import 'package:onyxia/export.dart';

/// Thin wrapper over Supabase Auth. `auth.users` is the source of truth;
/// `public.users` is a thin view over it (no mirror table, no app-side writes).
class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Initiates the Google OAuth flow. On web this triggers a popup (or
  /// redirect) and the auth state stream emits the new session asynchronously.
  Future<bool> signInWithGoogle() async {
    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }

  /// Email + password sign-in for the staging test account.
  Future<bool> signInWithFakeAccount() async {
    try {
      await _client.auth.signInWithPassword(
        email: 'onyxia@test.com',
        password: '123456',
      );
      return true;
    } catch (e) {
      debugPrint('Error signing in with fake account: $e');
      return false;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: '${Uri.base.origin}/${Routes.vaults}',
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${Uri.base.origin}${Routes.resetPassword}',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
