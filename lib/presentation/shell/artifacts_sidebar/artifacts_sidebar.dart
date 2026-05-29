import 'package:onyxia/export.dart';

class ArtifactsSidebar extends ConsumerWidget {
  static const double minWidth = 170;
  // Width of the always-present divider strip. When collapsed the artifacts
  // column shrinks to this strip so the divider (which now lives in AppShell)
  // straddles the master-sidebar boundary cleanly.
  static const double dividerStripWidth = 11;
  static const double collapseThreshold = 84;

  final ValueNotifier<double> width;
  final ValueNotifier<bool> isCollapsed;
  final ValueNotifier<bool> animateNextCollapseChange;

  const ArtifactsSidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.animateNextCollapseChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: .merge([width, isCollapsed, animateNextCollapseChange]),
      builder: (context, _) {
        final w = isCollapsed.value ? dividerStripWidth : width.value;
        final animate = animateNextCollapseChange.value;
        final Duration duration = animate
            ? const Duration(milliseconds: 300)
            : .zero;

        return ClipRect(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOut,
            width: w,
            color: ThemeHelper.background1(),
            onEnd: () {
              if (animateNextCollapseChange.value) {
                animateNextCollapseChange.value = false;
              }
            },
            child: OverflowBox(
              alignment: .topLeft,
              minWidth: w,
              maxWidth: w,
              child: SizedBox(
                width: w,
                child: Column(
                  children: [
                    Container(
                      width: .infinity,
                      padding: .only(right: dividerStripWidth),
                      child: const ArtifactsSidebarHeader(),
                    ),
                    Expanded(
                      child: Container(
                        width: .infinity,
                        padding: .only(left: 6, top: 6, bottom: 6, right: 18),
                        child: const ArtifactsTreeView(),
                      ),
                    ),
                    Container(
                      width: .infinity,
                      padding: .only(right: dividerStripWidth),
                      child: const ArtifactsSidebarFooter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
