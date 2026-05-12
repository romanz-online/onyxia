import 'package:onyxia/export.dart';

final _selectedProjectIdFromUrlProvider =
    NotifierProvider<_SelectedProjectIdFromUrlNotifier, String?>(
  _SelectedProjectIdFromUrlNotifier.new,
);

class _SelectedProjectIdFromUrlNotifier extends Notifier<String?> {
  @override
  String? build() {
    final router = ref.watch(routerProvider);
    void listener() {
      state = _readProjectId(router);
    }

    router.routeInformationProvider.addListener(listener);
    ref.onDispose(() {
      router.routeInformationProvider.removeListener(listener);
    });
    return _readProjectId(router);
  }

  static String? _readProjectId(GoRouter router) =>
      router.routerDelegate.currentConfiguration.pathParameters['id'];
}

final selectedProjectProvider = Provider<Project?>((ref) {
  final id = ref.watch(_selectedProjectIdFromUrlProvider);
  if (id == null || id.isEmpty) return null;
  final projects = ref.watch(projectsProvider).value ?? const [];
  return projects.firstWhereOrNull((p) => p.id == id);
});
