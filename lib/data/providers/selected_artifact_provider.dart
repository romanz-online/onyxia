import 'package:onyxia/export.dart';

final selectedArtifactProvider = Provider<Artifact?>((ref) {
  final name = ref.watch(_selectedArtifactNameFromUrlProvider);
  if (name == null || name.isEmpty) return null;
  return (ref.watch(artifactsProvider).value ?? const <Artifact>[])
      .firstWhereOrNull((a) => a.name == name);
});

final _selectedArtifactNameFromUrlProvider =
    NotifierProvider<_SelectedArtifactNameFromUrlNotifier, String?>(
  _SelectedArtifactNameFromUrlNotifier.new,
);

class _SelectedArtifactNameFromUrlNotifier extends Notifier<String?> {
  @override
  String? build() {
    final router = ref.watch(routerProvider);
    void listener() {
      state = _readSelectedId(router);
    }

    router.routeInformationProvider.addListener(listener);
    ref.onDispose(() {
      router.routeInformationProvider.removeListener(listener);
    });
    return _readSelectedId(router);
  }

  static String? _readSelectedId(GoRouter router) =>
      router.routerDelegate.currentConfiguration.pathParameters['selectedId'];
}
