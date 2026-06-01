import 'package:onyxia/export.dart';

/// The current logged-in user's role in the currently selected vault.
/// Returns null if the user is not a member of the selected vault
/// or if no vault is selected.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u.value?.id));
  final members = ref.watch(
    vaultMembersProvider.select((async) => async.asData?.value ?? []),
  );
  return members.firstWhereOrNull((m) => m.userId == userId)?.role;
});

final currentUserProvider = StreamNotifierProvider<CurrentUserNotifier, User>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends StreamNotifier<User> {
  final _authRepository = AuthRepository();
  final _usersRepository = UsersRepository();

  @override
  Stream<User> build() {
    return _authRepository.authStateChanges.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) return .initial();
      final user = await _usersRepository.get(session.user.id);
      return user?.copyWith(isLogged: true) ?? .initial();
    });
  }

  Future<void> signOut() async => await _authRepository.signOut();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async => _authRepository.signUpWithEmail(email: email, password: password);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async => _authRepository.signInWithEmail(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) async =>
      _authRepository.sendPasswordResetEmail(email);

  Future<void> updatePassword(String newPassword) async =>
      _authRepository.updatePassword(newPassword);
}
