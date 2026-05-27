import 'package:onyxia/export.dart';

class MasterSidebar extends ConsumerWidget {
  static const double width = 42;

  final String vaultId;
  final ValueNotifier<bool> isArtifactsSidebarCollapsed;
  final ValueNotifier<bool> animateNextCollapseChange;

  const MasterSidebar({
    super.key,
    required this.vaultId,
    required this.isArtifactsSidebarCollapsed,
    required this.animateNextCollapseChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: .infinity,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        border: Border(
          right: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
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
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  tooltipDirection: OnyxiaTooltipDirection.right,
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
                tooltip: 'Open graph',
                tooltipDirection: OnyxiaTooltipDirection.right,
                onPressed: () {
                  if (vaultId.isEmpty) return;
                  context.go('/vault/$vaultId/${Routes.graph}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
