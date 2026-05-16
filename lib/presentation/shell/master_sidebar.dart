import 'package:onyxia/export.dart';

class MasterSidebar extends ConsumerWidget {
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
      width: 42,
      height: double.infinity,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        border: Border(
          right: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isArtifactsSidebarCollapsed,
              builder: (context, collapsed, _) {
                return NarwhalIconButton(
                  icon: collapsed
                      ? LucideIcons.panelLeftOpen
                      : LucideIcons.panelLeftClose,
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () {
                    animateNextCollapseChange.value = true;
                    isArtifactsSidebarCollapsed.value = !collapsed;
                  },
                );
              },
            ),
            if (vaultId.isNotEmpty) ...[
              NarwhalIconButton(
                icon: LucideIcons.share2,
                tooltip: 'Open graph',
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
