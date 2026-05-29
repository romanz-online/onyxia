import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

bool _onyxiaReadyDispatched = false;

class AppShell extends ConsumerStatefulWidget {
  final String vaultId;
  final String? selectedId;
  final LandingMode initialLandingMode;
  final String? inviteToken;
  final String? inviteDestPath;

  const AppShell({
    super.key,
    required this.vaultId,
    this.selectedId,
    this.initialLandingMode = LandingMode.signIn,
    this.inviteToken,
    this.inviteDestPath,
  });

  @override
  ConsumerState createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const double _defaultArtifactsSidebarWidth = 260;
  final _artifactsSidebarWidth = ValueNotifier<double>(
    _defaultArtifactsSidebarWidth,
  );
  final _isArtifactsSidebarCollapsed = ValueNotifier<bool>(false);
  final _animateNextCollapseChange = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _artifactsSidebarWidth.dispose();
    _isArtifactsSidebarCollapsed.dispose();
    _animateNextCollapseChange.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);

    if (widget.vaultId.isNotEmpty) {
      final vaultsAsync = ref.watch(vaultsProvider);
      if (vaultsAsync.isLoading) {
        return Scaffold(body: Center(child: OnyxiaLoadingIndicator()));
      }
      final vaults = vaultsAsync.value ?? const <Vault>[];
      final vaultExists = vaults.any((p) => p.id == widget.vaultId);
      if (!vaultExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.replace(Routes.home);
        });
        return Scaffold(body: Center(child: OnyxiaLoadingIndicator()));
      }
    }

    if (!_onyxiaReadyDispatched) {
      _onyxiaReadyDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        web.window.dispatchEvent(web.Event('onyxia-ready'));
      });
    }

    return Scaffold(
      backgroundColor: ThemeHelper.background1(),
      body: Stack(
        children: [
          Row(
            children: [
              MasterSidebar(
                vaultId: widget.vaultId,
                isArtifactsSidebarCollapsed: _isArtifactsSidebarCollapsed,
                animateNextCollapseChange: _animateNextCollapseChange,
              ),
              ArtifactsSidebar(
                width: _artifactsSidebarWidth,
                isCollapsed: _isArtifactsSidebarCollapsed,
                animateNextCollapseChange: _animateNextCollapseChange,
              ),
              Expanded(
                child: ColoredBox(
                  color: ThemeHelper.background1(),
                  child: WorkspaceHost(
                    vaultId: widget.vaultId,
                    selectedId: widget.selectedId,
                  ),
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: Listenable.merge([
              _artifactsSidebarWidth,
              _isArtifactsSidebarCollapsed,
              _animateNextCollapseChange,
            ]),
            builder: (context, _) {
              final artifactsW = _isArtifactsSidebarCollapsed.value
                  ? ArtifactsSidebar.dividerStripWidth
                  : _artifactsSidebarWidth.value;
              final boundaryX = MasterSidebar.width + artifactsW;
              final animate = _animateNextCollapseChange.value;
              final duration = animate
                  ? const Duration(milliseconds: 150)
                  : Duration.zero;

              return AnimatedPositioned(
                duration: duration,
                curve: Curves.easeInOut,
                left:
                    boundaryX -
                    (ArtifactsSidebar.dividerStripWidth * 1.5).ceil(),
                top: 0,
                bottom: 0,
                width: ArtifactsSidebar.dividerStripWidth,
                child: _ResizeDivider(
                  onDragStart: () {
                    _animateNextCollapseChange.value = false;
                  },
                  onDragUpdate: (globalDx) {
                    final maxWidth =
                        MediaQuery.of(context).size.width - 46 - 300;
                    _artifactsSidebarWidth.value =
                        (globalDx -
                                MasterSidebar.width +
                                ArtifactsSidebar.dividerStripWidth)
                            .clamp(ArtifactsSidebar.minWidth, maxWidth);
                    _isArtifactsSidebarCollapsed.value =
                        globalDx < ArtifactsSidebar.collapseThreshold;
                  },
                ),
              );
            },
          ),
          if (widget.vaultId.isEmpty)
            LandingOverlay(
              initialMode: widget.initialLandingMode,
              inviteToken: widget.inviteToken,
              inviteDestPath: widget.inviteDestPath,
            ),
        ],
      ),
    );
  }
}

class _ResizeDivider extends ConsumerStatefulWidget {
  final VoidCallback onDragStart;
  final void Function(double globalDx) onDragUpdate;

  const _ResizeDivider({required this.onDragStart, required this.onDragUpdate});

  @override
  ConsumerState<_ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends ConsumerState<_ResizeDivider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: .translucent,
            onHorizontalDragStart: (_) {
              widget.onDragStart();
              setState(() => _isDragging = true);
            },
            onHorizontalDragUpdate: (details) =>
                widget.onDragUpdate(details.globalPosition.dx),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_isDragging || isHovered) ? 3 : 1,
                color: (_isDragging || isHovered)
                    ? ThemeHelper.accent()
                    : ThemeHelper.auxiliary(),
              ),
            ),
          ),
        );
      },
    );
  }
}
