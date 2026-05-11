import 'package:onyxia/export.dart';

class ArtifactEditorScreen extends ConsumerStatefulWidget {
  const ArtifactEditorScreen({super.key});

  @override
  ConsumerState<ArtifactEditorScreen> createState() =>
      _ArtifactEditorScreenState();
}

class _ArtifactEditorScreenState extends ConsumerState<ArtifactEditorScreen>
    with SingleTickerProviderStateMixin {
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
    final selectedTitle =
        GoRouterState.of(context).pathParameters['selectedId'];
    if (selectedTitle == null || selectedTitle.isEmpty) return;

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
    if (!isDataLoaded || !mounted) return;

    final item = ref
        .read(artifactsProvider)
        .firstWhereOrNull((e) => e.name == selectedTitle);
    if (item != null) {
      ref.read(selectedArtifactProvider.notifier).state = item;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArtifactEditor(promptNotify: true);
  }
}
