import 'package:onyxia/export.dart';

/// The current logged-in user's role in the currently selected project.
/// Returns null if the user is not a member of the selected project
/// or if no project is selected.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u.value?.id));
  final members = ref.watch(
      projectMembersProvider.select((async) => async.asData?.value ?? []));
  return members.firstWhereOrNull((m) => m.userId == userId)?.role;
});

final currentUserProvider =
    StreamNotifierProvider<CurrentUserNotifier, User>(CurrentUserNotifier.new);

class CurrentUserNotifier extends StreamNotifier<User> {
  final _repository = AuthRepository();

  @override
  Stream<User> build() {
    return _repository.authStateChanges.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) return User.initial();
      final user = await UsersRepository().get(session.user.id);
      return user?.copyWith(isLogged: true) ?? User.initial();
    });
  }

  Future<void> signOut() async => await _repository.signOut();

  Future<bool> signInWithGoogle() async => _repository.signInWithGoogle();

  Future<bool> signInWithFakeAccount() async =>
      _repository.signInWithFakeAccount();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async =>
      _repository.signUpWithEmail(email: email, password: password);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _repository.signInWithEmail(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) async =>
      _repository.sendPasswordResetEmail(email);

  Future<void> updatePassword(String newPassword) async =>
      _repository.updatePassword(newPassword);
}
