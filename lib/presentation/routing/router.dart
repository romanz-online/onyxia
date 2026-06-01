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
    accessibleVaultIds = ref
        .read(vaultsProvider)
        .value
        ?.map((p) => p.id)
        .toList();

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

/// Maps a matched route location to the [LandingMode] the [LandingOverlay]
/// should open in. The invite/reset-password/login routes render the same
/// screen — only the overlay's content differs.
LandingMode _landingModeFor(String location) {
  if (location == Routes.resetPassword) return .resetPassword;
  return .signIn;
}

/// Shared builder for every route under the [ShellRoute]. The routes exist only
/// for URL matching, path-parameter extraction, and redirect/mode logic — the
/// actual content is rendered once by [AppShell] -> [WorkspaceHost], so the
/// matched sub-route's own widget is intentionally empty.
Widget _routeAnchor(BuildContext context, GoRouterState state) =>
    const SizedBox.shrink();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    initialLocation: Routes.home,
    refreshListenable: notifier,
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(Routes.home),
      );
      return Scaffold(body: Center(child: OnyxiaLoadingIndicator()));
    },
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, _) {
          final destParam = state.uri.queryParameters['dest'];
          return AppShell(
            vaultId: state.pathParameters['id'] ?? '',
            // TODO: reloading while in a vault keeps kicking me out of the vault
            selectedId: state.pathParameters['selectedId'],
            initialLandingMode: _landingModeFor(state.matchedLocation),
            inviteToken: state.uri.queryParameters['token'],
            inviteDestPath: destParam != null
                ? Uri.decodeComponent(destParam)
                : null,
          );
        },
        routes: [
          // TODO: need a different way to do password reset that doesn't rely so much on supabase. worst comes to worst, just put it into the server and implement later
          GoRoute(
            path: Routes.resetPassword,
            name: 'resetPassword',
            builder: _routeAnchor,
          ),
          GoRoute(path: Routes.home, name: 'home', builder: _routeAnchor),
          GoRoute(
            path: '/vault/:id',
            name: 'vault',
            builder: _routeAnchor,
            routes: [
              GoRoute(
                path: ':selectedId',
                name: 'vaultItem',
                builder: _routeAnchor,
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (notifier.isAuthLoading) return null;
      final isAuth = notifier.isAuth;

      if (!isAuth &&
          state.matchedLocation != Routes.home &&
          state.matchedLocation != Routes.resetPassword) {
        return Routes.home;
      }

      final pathvaultId = state.pathParameters['id'];
      if (pathvaultId != null && pathvaultId.isNotEmpty) {
        // null means vaults haven't loaded yet — don't false-kick on cold boot.
        if (notifier.accessibleVaultIds == null) return null;
        if (!notifier.accessibleVaultIds!.contains(pathvaultId)) {
          return Routes.home;
        }
      }

      return null;
    },
  );
});
