import 'package:onyxia/export.dart';

class AppShell extends ConsumerStatefulWidget {
  final String? selectedId;
  final String projectId;

  const AppShell({super.key, this.selectedId, required this.projectId});

  @override
  ConsumerState createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);

    if (widget.projectId.isNotEmpty) {
      final projectsAsync = ref.watch(projectsProvider);
      if (projectsAsync.isLoading) {
        return Scaffold(body: Center(child: NarwhalSpinner()));
      }
      final projects = projectsAsync.value ?? const <Project>[];
      final projectExists = projects.any((p) => p.id == widget.projectId);
      if (!projectExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.replace('/${Routes.projects}');
        });
        return Scaffold(body: Center(child: NarwhalSpinner()));
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Row(
            children: [
              MasterSidebar(projectId: widget.projectId),
              const ArtifactsSidebar(),
              Expanded(
                child: ColoredBox(
                  color: ThemeHelper.neutral100(context),
                  child: WorkspaceHost(
                    projectId: widget.projectId,
                    selectedId: widget.selectedId,
                  ),
                ),
              ),
            ],
          ),
          if (widget.projectId.isEmpty) const LandingOverlay(),
        ],
      ),
    );
  }
}
