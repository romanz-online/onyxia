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
  if (location == Routes.invite) return .invite;
  if (location == Routes.resetPassword) return .resetPassword;
  return .signIn;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    initialLocation: Routes.home,
    refreshListenable: notifier,
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.home);
      });
      return Scaffold(body: Center(child: OnyxiaLoadingIndicator()));
    },
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          final vaultId = state.pathParameters['id'] ?? '';
          final landingMode = _landingModeFor(state.matchedLocation);
          final destParam = state.uri.queryParameters['dest'];
          return AppShell(
            vaultId: vaultId,
            initialLandingMode: landingMode,
            inviteToken: state.uri.queryParameters['token'],
            inviteDestPath: destParam != null
                ? Uri.decodeComponent(destParam)
                : null,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.invite,
            name: 'invite',
            builder: (_, __) =>
                const WorkspaceHost(vaultId: '', selectedId: null),
          ),
          // TODO: need a different way to do password reset that doesn't rely so much on supabase. worst comes to worst, just put it into the server and implement later
          GoRoute(
            path: Routes.resetPassword,
            name: 'resetPassword',
            builder: (_, __) =>
                const WorkspaceHost(vaultId: '', selectedId: null),
          ),
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (_, __) =>
                const WorkspaceHost(vaultId: '', selectedId: null),
          ),
          GoRoute(
            path: '/vault/:id',
            name: 'vault',
            builder: (context, state) => WorkspaceHost(
              vaultId: state.pathParameters['id']!,
              selectedId: null,
            ),
            routes: [
              GoRoute(
                path: ':selectedId',
                name: 'vaultItem',
                builder: (context, state) => WorkspaceHost(
                  vaultId: state.pathParameters['id']!,
                  selectedId: state.pathParameters['selectedId'],
                ),
              ),
            ],
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
        // When a token is present, LandingOverlay (invite mode) runs
        // accept_vault_invitation and navigates itself — don't preempt it.
        if (state.uri.queryParameters.containsKey('token')) return null;
        if (isAuth) {
          return Uri.decodeComponent(
            state.uri.queryParameters['dest'] ?? Routes.home,
          );
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
