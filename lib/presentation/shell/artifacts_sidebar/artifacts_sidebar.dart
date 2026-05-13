import 'package:onyxia/export.dart';

class ArtifactsSidebar extends StatelessWidget {
  static const double _minWidth = 200;
  static const double _defaultWidth = 260;

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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        width,
        isCollapsed,
        animateNextCollapseChange,
      ]),
      builder: (context, _) {
        final w = width.value;
        final collapsed = isCollapsed.value;
        final animate = animateNextCollapseChange.value;

        return ClipRect(
          child: AnimatedSize(
            duration: animate
                ? const Duration(milliseconds: 150)
                : Duration.zero,
            curve: Curves.easeInOut,
            alignment: Alignment.centerLeft,
            onEnd: () {
              if (animateNextCollapseChange.value) {
                animateNextCollapseChange.value = false;
              }
            },
            child: SizedBox(
              width: collapsed ? 0 : w,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: w,
                maxWidth: w,
                child: SizedBox(
                  width: w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        color: ThemeHelper.neutral100(context),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(right: 7),
                              child: const ArtifactsSidebarHeader(),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: ThemeHelper.neutral100(context),
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  top: 6,
                                  bottom: 6,
                                  right: 13,
                                ),
                                child: ArtifactsTreeView(),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(right: 7),
                              child: const ArtifactsSidebarFooter(),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 0,
                        bottom: 0,
                        width: 9,
                        child: _ResizeDivider(
                          onDragStart: () {
                            animateNextCollapseChange.value = false;
                          },
                          onDragUpdate: (delta, globalDx) {
                            final maxWidth =
                                MediaQuery.of(context).size.width - 46 - 300;
                            width.value = (width.value + delta).clamp(
                              _minWidth,
                              maxWidth,
                            );
                            if (globalDx <= 84) {
                              width.value = _defaultWidth;
                              isCollapsed.value = true;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResizeDivider extends StatefulWidget {
  final VoidCallback onDragStart;
  final void Function(double delta, double globalDx) onDragUpdate;

  const _ResizeDivider({required this.onDragStart, required this.onDragUpdate});

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
            onHorizontalDragStart: (_) {
              widget.onDragStart();
              setState(() => _isDragging = true);
            },
            onHorizontalDragUpdate: (details) => widget.onDragUpdate(
              details.delta.dx,
              details.globalPosition.dx,
            ),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_isDragging || isHovered) ? 3 : 1,
                color: (_isDragging || isHovered)
                    ? ThemeHelper.accentColor()
                    : ThemeHelper.neutral300(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
