import 'package:onyxia/export.dart';

class ArtifactsSidebar extends StatelessWidget {
  static const double _minWidth = 170;
  static const double _sidebarWidth = 42;
  static const double _collapseThreshold = _sidebarWidth * 2;
  // Width of the always-present divider strip: 9px divider + 2px right padding.
  // When collapsed the artifacts column shrinks to this strip so the divider
  // hugs the master sidebar's right edge and stays draggable.
  static const double _dividerStripWidth = 11;

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
        // TODO: this is a little complicated. there's a gap that appears to the left of the master sidebar because it and this sidebar are in a Row
        // TODO: cont. i'd probably need the master sidebar itself to be aware of the artifacts sidebar state, or have a global sidebar manager, or
        // TODO: cont. have the resize divider in a stack above both sidebars and somehow have a system that ties it to the artifacts sidebar
        final w = isCollapsed.value ? _dividerStripWidth : width.value;
        final animate = animateNextCollapseChange.value;
        final duration =
            animate ? const Duration(milliseconds: 150) : Duration.zero;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topLeft,
          children: [
            ClipRect(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeInOut,
                width: w,
                onEnd: () {
                  if (animateNextCollapseChange.value) {
                    animateNextCollapseChange.value = false;
                  }
                },
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: w,
                  maxWidth: w,
                  child: SizedBox(
                    width: w,
                    child: Container(
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
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: duration,
              curve: Curves.easeInOut,
              left: w - _dividerStripWidth,
              top: 0,
              bottom: 0,
              width: _dividerStripWidth,
              child: _ResizeDivider(
                onDragStart: () {
                  animateNextCollapseChange.value = false;
                },
                onDragUpdate: (_, globalDx) {
                  final maxWidth = MediaQuery.of(context).size.width - 46 - 300;
                  // Track absolute cursor position so the divider follows
                  // the cursor rather than drifting via accumulated deltas
                  // across collapse transitions.
                  width.value =
                      (globalDx - _sidebarWidth).clamp(_minWidth, maxWidth);
                  isCollapsed.value = globalDx < _collapseThreshold;
                },
              ),
            ),
          ],
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
