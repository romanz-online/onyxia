import 'package:onyxia/export.dart';

class AppShell extends ConsumerStatefulWidget {
  final String? selectedId;
  final String vaultId;

  const AppShell({super.key, this.selectedId, required this.vaultId});

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
        return Scaffold(body: Center(child: NarwhalSpinner()));
      }
      final vaults = vaultsAsync.value ?? const <Vault>[];
      final vaultExists = vaults.any((p) => p.id == widget.vaultId);
      if (!vaultExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.replace('/${Routes.vaults}');
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
                  color: ThemeHelper.neutral100(context),
                  child: WorkspaceHost(
                    vaultId: widget.vaultId,
                    selectedId: widget.selectedId,
                  ),
                ),
              ),
            ],
          ),
          if (widget.vaultId.isEmpty) const LandingOverlay(),
        ],
      ),
    );
  }
}
