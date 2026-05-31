import 'package:onyxia/export.dart';

class MasterSidebar extends ConsumerWidget {
  static const double width = 42;

  final String vaultId;
  final ValueNotifier<bool> isArtifactsSidebarCollapsed;
  final ValueNotifier<bool> animateNextCollapseChange;
  final String? selectedId;

  const MasterSidebar({
    super.key,
    required this.vaultId,
    required this.isArtifactsSidebarCollapsed,
    required this.animateNextCollapseChange,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: .infinity,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        border: Border(
          right: BorderSide(color: ThemeHelper.auxiliary(), width: 1),
        ),
      ),
      child: Padding(
        padding: .symmetric(horizontal: 4, vertical: 8),
        child: Column(
          spacing: 8,
          crossAxisAlignment: .start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isArtifactsSidebarCollapsed,
              builder: (context, collapsed, _) {
                return OnyxiaIconButton(
                  icon: collapsed
                      ? LucideIcons.panelLeftOpen
                      : LucideIcons.panelLeftClose,
                  iconColor: ThemeHelper.foreground2(),
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  tooltipDirection: .right,
                  onPressed: () {
                    animateNextCollapseChange.value = true;
                    isArtifactsSidebarCollapsed.value = !collapsed;
                  },
                );
              },
            ),
            if (vaultId.isNotEmpty) ...[
              OnyxiaIconButton(
                icon: LucideIcons.share2,
                iconColor: ThemeHelper.foreground2(),
                tooltip: 'Open graph',
                tooltipDirection: .right,
                onPressed: () {
                  if (vaultId.isEmpty) return;
                  context.go(
                    selectedId == Routes.graph
                        ? Routes.vaultUrl(vaultId)
                        : Routes.graphUrl(vaultId),
                  );
                },
                isSelected: selectedId == Routes.graph,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
