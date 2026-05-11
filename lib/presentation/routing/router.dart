import 'package:onyxia/export.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod providers into a [ChangeNotifier] so GoRouter can
/// re-evaluate its redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  bool isAuth = false;
  bool isPending = false;
  bool isAuthLoading = true;

  _RouterNotifier(Ref ref) {
    final initialAuth = ref.read(authProvider);
    isAuth = initialAuth.valueOrNull != null;
    isAuthLoading = initialAuth is AsyncLoading;

    ref.listen<AsyncValue<Session?>>(authProvider, (_, next) {
      isAuth = next.valueOrNull != null;
      isAuthLoading = next is AsyncLoading;
      notifyListeners();
    });
    ref.listen<User>(currentUserProvider, (_, next) {
      isPending = next.pending;
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    initialLocation: '/${Routes.projects}',
    refreshListenable: notifier,
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/${Routes.projects}');
      });
      return Scaffold(body: Center(child: NarwhalSpinner()));
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.invite,
        name: 'invite',
        builder: (context, state) => InviteScreen(
          destinationPath: Uri.decodeComponent(state.uri.queryParameters['dest'] ?? '/${Routes.projects}'),
        ),
      ),
      GoRoute(
        path: '/${Routes.projects}',
        name: Routes.projects,
        builder: (context, state) => const Home(projectId: ''),
      ),
      GoRoute(
        path: '/project/:id',
        name: 'project',
        builder: (context, state) => Home(projectId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: ':selectedId',
            name: 'projectItem',
            builder: (context, state) => Home(
              selectedId: state.pathParameters['selectedId'],
              projectId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (notifier.isAuthLoading) return null;
      final isAuth = notifier.isAuth;
      final isPending = notifier.isPending;
      final isOnInvite = state.matchedLocation == Routes.invite;
      final hasInvite = state.uri.queryParameters['invite'] == 'true';

      if (isOnInvite) {
        if (isAuth && !isPending) {
          return Uri.decodeComponent(state.uri.queryParameters['dest'] ?? '/${Routes.projects}');
        }
        return null;
      }

      if (hasInvite) {
        if (!isAuth || isPending) {
          final params = Map<String, String>.from(state.uri.queryParameters)..remove('invite');
          final path = state.matchedLocation;
          final dest = params.isEmpty
              ? path
              : '$path?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
          return '${Routes.invite}?dest=${Uri.encodeComponent(dest)}';
        } else {
          final params = Map<String, String>.from(state.uri.queryParameters)..remove('invite');
          final path = state.matchedLocation;
          final stripped =
              params.isEmpty ? path : '$path?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
          return stripped;
        }
      }

      if (!isAuth && state.matchedLocation != '/${Routes.projects}') return '/${Routes.projects}';

      return null;
    },
  );
});
