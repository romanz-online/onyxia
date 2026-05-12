import 'package:onyxia/export.dart';
import 'dart:async';

/// The current logged-in user's role in the currently selected project.
/// Returns null if the user is not a member of the selected project
/// or if no project is selected.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u.id));
  final members = ref.watch(projectMembersProvider(null)
      .select((async) => async.asData?.value ?? []));
  return members.firstWhereOrNull((m) => m.userId == userId)?.role;
});

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, User>(CurrentUserNotifier.new);

class CurrentUserNotifier extends Notifier<User> {
  late AuthRepository _repository;

  @override
  User build() {
    _repository = ref.read(authRepositoryProvider);

    final sub = _repository.authStateChanges.listen((authState) {
      final session = authState.session;
      if (session == null) {
        state = User.initial();
      } else {
        _loadUserFromTable(session.user.id);
      }
    });
    ref.onDispose(sub.cancel);

    // On hot-reload / cold start the auth event stream may have already fired —
    // seed state from the current session.
    final session = _repository.currentSession;
    if (session != null) _loadUserFromTable(session.user.id);

    return User.initial();
  }

  /// Read the row from the `public.users` view (a thin projection over
  /// `auth.users`). The view always resolves for any signed-in user.
  Future<void> _loadUserFromTable(String userId) async {
    final user = await UsersRepository().get(userId);
    if (user != null) state = user.copyWith(isLogged: true);
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
