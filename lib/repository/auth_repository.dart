import 'package:onyxia/export.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Thin wrapper over Supabase Auth. The Phase B trigger
/// `mirror_auth_user_to_public()` creates the matching `public.users` row on
/// every sign-up — no app-side reconciliation needed.
class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

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

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Update the public.users row for this user. The schema's update trigger
  /// sets `updated_at` / `updated_by` automatically.
  Future<bool> updateUserProfile(UserDefinition user) async {
    try {
      await UserDefinitionsRepository().update(user);
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
}
