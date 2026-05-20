import 'package:onyxia/export.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod providers into a [ChangeNotifier] so GoRouter can
/// re-evaluate its redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  bool isAuth = false;
  bool isAuthLoading = true;

  /// null = vaults haven't loaded yet (suppress membership kickback);
  /// list = loaded set of vault ids the current user can access.
  List<String>? accessibleVaultIds;

  _RouterNotifier(Ref ref) {
    final initialAuth = ref.read(authProvider);
    isAuth = initialAuth.value != null;
    isAuthLoading = initialAuth is AsyncLoading;
    accessibleVaultIds =
        ref.read(vaultsProvider).value?.map((p) => p.id).toList();

    ref.listen<AsyncValue<Session?>>(authProvider, (_, next) {
      isAuth = next.value != null;
      isAuthLoading = next is AsyncLoading;
      notifyListeners();
    });
    ref.listen<AsyncValue<List<Vault>>>(vaultsProvider, (_, next) {
      accessibleVaultIds = next.value?.map((p) => p.id).toList();
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    initialLocation: '/${Routes.vaults}',
    refreshListenable: notifier,
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/${Routes.vaults}');
      });
      return Scaffold(body: Center(child: NarwhalSpinner()));
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.invite,
        name: 'invite',
        builder: (context, state) => InviteScreen(
          destinationPath: Uri.decodeComponent(
              state.uri.queryParameters['dest'] ?? '/${Routes.vaults}'),
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/${Routes.vaults}',
        name: Routes.vaults,
        builder: (context, state) => const AppShell(vaultId: ''),
      ),
      GoRoute(
        path: '/vault/:id',
        name: 'vault',
        builder: (context, state) =>
            AppShell(vaultId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: ':selectedId',
            name: 'vaultItem',
            builder: (context, state) => AppShell(
              selectedId: state.pathParameters['selectedId'],
              vaultId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (notifier.isAuthLoading) return null;
      final isAuth = notifier.isAuth;
      final isOnInvite = state.matchedLocation == Routes.invite;
      final hasInvite = state.uri.queryParameters['invite'] == 'true';

      if (isOnInvite) {
        // When a token is present, InviteScreen runs accept_vault_invitation
        // and navigates itself — don't preempt it.
        if (state.uri.queryParameters.containsKey('token')) return null;
        if (isAuth) {
          return Uri.decodeComponent(
              state.uri.queryParameters['dest'] ?? '/${Routes.vaults}');
        }
        return null;
      }

      if (hasInvite) {
        if (!isAuth) {
          final params = Map<String, String>.from(state.uri.queryParameters)
            ..remove('invite');
          final path = state.matchedLocation;
          final dest = params.isEmpty
              ? path
              : '$path?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
          return '${Routes.invite}?dest=${Uri.encodeComponent(dest)}';
        } else {
          final params = Map<String, String>.from(state.uri.queryParameters)
            ..remove('invite');
          final path = state.matchedLocation;
          final stripped = params.isEmpty
              ? path
              : '$path?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
          return stripped;
        }
      }

      if (!isAuth &&
          state.matchedLocation != '/${Routes.vaults}' &&
          state.matchedLocation != Routes.resetPassword) {
        return '/${Routes.vaults}';
      }

      final pathvaultId = state.pathParameters['id'];
      if (pathvaultId != null && pathvaultId.isNotEmpty) {
        // null means vaults haven't loaded yet — don't false-kick on cold boot.
        if (notifier.accessibleVaultIds == null) return null;
        if (!notifier.accessibleVaultIds!.contains(pathvaultId)) {
          return '/${Routes.vaults}';
        }
      }

      return null;
    },
  );
});
