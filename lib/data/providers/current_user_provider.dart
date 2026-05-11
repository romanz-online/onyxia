import 'package:onyxia/export.dart';

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
    StateNotifierProvider<CurrentUserNotifier, User>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(authRepository);
});

class CurrentUserNotifier extends StateNotifier<User> {
  final AuthRepository repository;
  StreamSubscription<AuthState>? _authSub;

  CurrentUserNotifier(this.repository) : super(User.initial()) {
    _listenToAuthChanges();
    // On hot-reload / cold start the auth event stream may have already fired —
    // seed state from the current session.
    final session = repository.currentSession;
    if (session != null) _loadUserFromTable(session.user.id);
  }

  void _listenToAuthChanges() {
    _authSub = repository.authStateChanges.listen((authState) {
      final session = authState.session;
      if (session != null) {
        _loadUserFromTable(session.user.id);
      } else {
        state = User.initial();
      }
    });
  }

  /// Read the row from the `public.users` view (a thin projection over
  /// `auth.users`). The view always resolves for any signed-in user.
  Future<void> _loadUserFromTable(String userId) async {
    try {
      final user = await UsersRepository().get(userId);
      if (!mounted) return;
      if (user != null) state = user.copyWith(isLogged: true);
    } catch (e) {
      debugPrint('Error loading user from public.users view: $e');
    }
  }

  Future<void> signOut() async => await repository.signOut();

  Future<bool> signInWithGoogle() async => repository.signInWithGoogle();

  Future<bool> signInWithFakeAccount() async =>
      repository.signInWithFakeAccount();

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
