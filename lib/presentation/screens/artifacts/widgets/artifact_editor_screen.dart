import 'package:onyxia/export.dart';

class ArtifactEditorScreen extends ConsumerStatefulWidget {
  const ArtifactEditorScreen({super.key});

  @override
  ConsumerState<ArtifactEditorScreen> createState() => _ArtifactEditorScreenState();
}

class _ArtifactEditorScreenState extends ConsumerState<ArtifactEditorScreen> with SingleTickerProviderStateMixin {
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueryParameterWithSelection();

      if (_isFirstBuild) {
        setState(() {
          _isFirstBuild = false;
        });
      }
    });
  }

  void _syncQueryParameterWithSelection() async {
    final goRouterState = GoRouterState.of(context);
    final selectedId = goRouterState.pathParameters['selectedId'];
    final currentProjectId = ref.read(projectsProvider).selectedProject.id;
    final persistedId = ref.read(itemPersistenceProvider);

    final idToSync = selectedId ?? persistedId;

    if (idToSync != null && idToSync.isNotEmpty) {
      bool isDataLoaded = ref.read(artifactsLoadedProvider);

      if (!isDataLoaded) {
        int attempts = 0;
        const maxAttempts = 50;

        while (!isDataLoaded && attempts < maxAttempts && context.mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!context.mounted) return;
          isDataLoaded = ref.read(artifactsLoadedProvider);
          attempts++;
        }
      }

      if (isDataLoaded) {
        final item = ref.read(artifactsProvider).firstWhereOrNull((e) => e.id == idToSync);

        if (item != null) {
          ref.read(selectedArtifactProvider.notifier).state = item;

          if (!mounted) return;

          if (selectedId == null && persistedId != null) {
            final projectId = GoRouterState.of(context).pathParameters['id'] ?? currentProjectId;
            context.go('/project/$projectId/$persistedId');
          }

          if (selectedId != null && selectedId != persistedId) {
            ref.read(itemPersistenceProvider.notifier).save(selectedId);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArtifactEditor(promptNotify: true);
  }
}
