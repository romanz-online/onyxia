import 'package:onyxia/export.dart';

class ArtifactEditorWorkspace extends ConsumerStatefulWidget {
  const ArtifactEditorWorkspace({super.key});

  @override
  ConsumerState<ArtifactEditorWorkspace> createState() =>
      _ArtifactEditorWorkspaceState();
}

class _ArtifactEditorWorkspaceState extends ConsumerState<ArtifactEditorWorkspace>
    with SingleTickerProviderStateMixin {
  bool _hasSyncedSelection = false;

  void _syncSelectionFromRoute() {
    if (_hasSyncedSelection) return;
    final selectedTitle =
        GoRouterState.of(context).pathParameters['selectedId'];
    if (selectedTitle == null || selectedTitle.isEmpty) return;
    final item = ref
        .read(artifactsProvider)
        .firstWhereOrNull((e) => e.name == selectedTitle);
    if (item == null) return;
    ref.read(selectedArtifactProvider.notifier).set(item);
    _hasSyncedSelection = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(artifactsLoadedProvider, (_, isLoaded) {
      if (isLoaded) _syncSelectionFromRoute();
    });
    // Handle the case where data was already loaded before this widget mounted.
    if (ref.read(artifactsLoadedProvider)) _syncSelectionFromRoute();
    return ArtifactEditor();
  }
}
