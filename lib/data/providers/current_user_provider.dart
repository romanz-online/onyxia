import 'package:onyxia/export.dart';

/// The current logged-in user's role in the currently selected project.
/// Returns null if the user is not a member of the selected project
/// or if no project is selected.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u.id));
  final members = ref.watch(userReferencesProvider(null)
      .select((async) => async.asData?.value ?? []));
  return members.firstWhereOrNull((m) => m.definitionId == userId)?.role;
});

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserDefinition>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(authRepository);
});

class CurrentUserNotifier extends StateNotifier<UserDefinition> {
  final AuthRepository repository;
  StreamSubscription<AuthState>? _authSub;

  CurrentUserNotifier(this.repository) : super(UserDefinition.initial()) {
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
        state = UserDefinition.initial();
      }
    });
  }

  /// Read the public.users row populated by the auth → public mirror trigger.
  Future<void> _loadUserFromTable(String userId) async {
    try {
      final user = await UserDefinitionsRepository().get(userId);
      if (!mounted) return;
      if (user != null) {
        state = user.copyWith(isLogged: true);
      } else {
        // Mirror trigger hasn't run yet (rare race) — fall back to the auth
        // user fields so the UI doesn't render an empty state.
        final authUser = repository.currentUser;
        if (authUser != null) {
          state = state.copyWith(
            id: authUser.id,
            email: authUser.email ?? '',
            name: authUser.userMetadata?['name'] ??
                authUser.userMetadata?['full_name'] ??
                '',
            isLogged: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading user data from public.users: $e');
    }
  }

  Future<void> signOut() async => await repository.signOut();

  Future<bool> signInWithGoogle() async => repository.signInWithGoogle();

  Future<bool> signInWithFakeAccount() async =>
      repository.signInWithFakeAccount();

  /// Updates the user's complete profile in public.users.
  Future<void> updateUserProfile(UserDefinition updatedUser) async {
    final ok = await repository.updateUserProfile(updatedUser);
    if (ok && mounted) {
      state = updatedUser.copyWith(isLogged: state.isLogged);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
