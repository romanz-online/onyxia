import 'package:onyxia/export.dart';

class ArtifactsSidebar extends StatefulWidget {
  const ArtifactsSidebar({super.key});

  @override
  State<ArtifactsSidebar> createState() => _ArtifactsSidebarState();
}

class _ArtifactsSidebarState extends State<ArtifactsSidebar> {
  static const double _minWidth = 200;
  final _width = ValueNotifier<double>(260);

  @override
  void dispose() {
    _width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _width,
      builder: (context, width, _) {
        return SizedBox(
          width: width,
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
                  onDragUpdate: (delta) {
                    final maxWidth =
                        MediaQuery.of(context).size.width - 46 - 300;
                    _width.value =
                        (_width.value + delta).clamp(_minWidth, maxWidth);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            onHorizontalDragUpdate: (details) =>
                widget.onDragUpdate(details.delta.dx),
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
