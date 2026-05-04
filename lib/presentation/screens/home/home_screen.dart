import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/screens/artifacts/widgets/artifact_editor_screen.dart';
import '../project_settings/project_settings_screen.dart';
import 'widgets/projects_landing_overlay.dart';
import 'package:onyxia/presentation/screens/artifacts/widgets/sidebar_footer.dart';

class Home extends ConsumerStatefulWidget {
  final String? selectedId;
  final String projectId;

  const Home({super.key, this.selectedId, required this.projectId});

  @override
  ConsumerState createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  static const double _minTreeSidebarWidth = 200;
  final _treeSidebarWidth = ValueNotifier<double>(260);

  @override
  void initState() {
    super.initState();
    _syncProject();
  }

  @override
  void didUpdateWidget(Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _syncProject();
    }
  }

  @override
  void dispose() {
    _treeSidebarWidth.dispose();
    super.dispose();
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

  Widget _getPageForId(String? id) {
    if (widget.projectId.isEmpty) return const ProjectsPage();
    if (id == Routes.graph) return const GraphScreen();
    if (id == Routes.settings) return const ProjectSettingsScreen();
    return const ArtifactEditorScreen();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);
    ref.watch(memberDefinitionsProvider);

    if (widget.projectId.isNotEmpty) {
      ref.listen<Projects>(projectsProvider, (previous, next) {
        final wasLoading = previous?.isLoading ?? true;
        if (wasLoading && !next.isLoading && next.selectedProject.id != widget.projectId) {
          ref.read(projectsProvider.notifier).selectProjectById(widget.projectId);
        }
      });
      final currentProjects = ref.watch(projectsProvider);
      if (currentProjects.isLoading) {
        return Scaffold(body: Center(child: NarwhalSpinner()));
      }
      final projectExists = currentProjects.projects.any((p) => p.id == widget.projectId);
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
              Sidebar(projectId: widget.projectId),
              ValueListenableBuilder<double>(
                valueListenable: _treeSidebarWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: ArtifactsTreeView(
                        contextMenuOptions: artifactsContextMenuOptions(),
                      ),
                    ),
                    const SidebarFooter(),
                  ],
                ),
                builder: (context, width, child) => SizedBox(
                  width: width,
                  child: Container(
                    color: ThemeHelper.neutral100(context),
                    child: child,
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: ThemeHelper.neutral100(context),
                  child: _getPageForId(widget.selectedId),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: _treeSidebarWidth,
            builder: (context, width, _) => Positioned(
              left: 46.0 + width - 11,
              top: 0,
              bottom: 0,
              width: 9,
              child: _ResizeDivider(
                onDragUpdate: (delta) {
                  final maxWidth = MediaQuery.of(context).size.width - 46 - 300;
                  _treeSidebarWidth.value = (_treeSidebarWidth.value + delta).clamp(_minTreeSidebarWidth, maxWidth);
                },
              ),
            ),
          ),
          if (widget.projectId.isEmpty) const ProjectsLandingOverlay(),
        ],
      ),
    );
  }
}

class _ResizeDivider extends StatefulWidget {
  final void Function(double delta) onDragUpdate;

  const _ResizeDivider({required this.onDragUpdate});

  @override
  State<_ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends State<_ResizeDivider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) => widget.onDragUpdate(details.delta.dx),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_isDragging || isHovered) ? 3 : 1,
                color: (_isDragging || isHovered) ? ThemeHelper.accentColor() : ThemeHelper.neutral300(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
