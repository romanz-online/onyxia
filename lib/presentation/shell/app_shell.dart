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
  void initState() {
    super.initState();
    _syncProject();
    _syncSelectedName();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _syncProject();
    }
    if (widget.selectedId != oldWidget.selectedId) {
      _syncSelectedName();
    }
  }

  void _syncProject() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.projectId.isNotEmpty) {
        ref.read(projectsProvider.notifier).selectProjectById(widget.projectId);
      } else {
        ref.read(projectsProvider.notifier).clearSelectedProject();
      }
    });
  }

  void _syncSelectedName() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedArtifactNameProvider.notifier).set(widget.selectedId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);

    if (widget.projectId.isNotEmpty) {
      ref.listen<Projects>(projectsProvider, (previous, next) {
        final wasLoading = previous?.isLoading ?? true;
        if (wasLoading &&
            !next.isLoading &&
            (next.selectedProject == null ||
                next.selectedProject!.id != widget.projectId)) {
          ref
              .read(projectsProvider.notifier)
              .selectProjectById(widget.projectId);
        }
      });
      final currentProjects = ref.watch(projectsProvider);
      if (currentProjects.isLoading) {
        return Scaffold(body: Center(child: NarwhalSpinner()));
      }
      final projectExists =
          currentProjects.projects.any((p) => p.id == widget.projectId);
      if (!projectExists && !currentProjects.isLoading) {
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
