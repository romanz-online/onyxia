import 'package:onyxia/export.dart';
import '../gestures/gestures.dart';
import 'canvas_gesture_detector.dart';

class ArrowWell extends ConsumerStatefulWidget {
  final ConnectionPoint connectionPoint;
  final double scale;
  final CanvasObject sourceObject;
  final CanvasGestureRouter? gestureRouter;
  final Function(bool) onTargetChanged;
  final bool isSourceSelected;
  final bool isSourceHovered;
  final bool isArrowToolActive;
  final bool isGesturing;

  const ArrowWell({
    super.key,
    required this.connectionPoint,
    required this.scale,
    required this.sourceObject,
    required this.gestureRouter,
    required this.onTargetChanged,
    required this.isSourceSelected,
    required this.isSourceHovered,
    required this.isArrowToolActive,
    required this.isGesturing,
  });

  @override
  ConsumerState<ArrowWell> createState() => _ArrowWellState();
}

class _ArrowWellState extends ConsumerState<ArrowWell> {
  bool _isAreaHovered = false;
  bool _isIconHovered = false;

  void _setAreaHovered(bool hovered) {
    setState(() {
      _isAreaHovered = hovered;
    });
  }

  void _setIconHovered(bool hovered) {
    setState(() {
      _isIconHovered = hovered;
      widget.onTargetChanged(hovered);
    });
  }

  /// Check if this arrow well is currently the active one (arrow creation in progress from this well)
  bool get _isCurrentlyActive {
    final arrow = ref.read(canvasGestureStateProvider).activeObject;
    return arrow != null &&
        arrow.isArrow &&
        arrow.arrowProps.startObjectId == widget.sourceObject.id &&
        arrow.arrowProps.startPoint == widget.connectionPoint;
  }

  /// Determine if this arrow well should be visible and interactive
  bool get _shouldBeVisible =>
      !widget.isGesturing &&
      (widget.isSourceSelected || (widget.isSourceHovered && widget.isArrowToolActive) || _isCurrentlyActive);

  Offset _getConnectionPointPosition() {
    final margin = 24.0 / widget.scale;

    Offset position = widget.connectionPoint.getBoundingBoxOffset(
      widget.sourceObject.topLeft,
      widget.sourceObject.bottomRight,
    );

    return switch (widget.connectionPoint) {
      ConnectionPoint.top => position.translate(0, -margin),
      ConnectionPoint.right => position.translate(margin, 0),
      ConnectionPoint.bottom => position.translate(0, margin),
      ConnectionPoint.left => position.translate(-margin, 0),
      ConnectionPoint.none => Offset.zero
    };
  }

  @override
  Widget build(BuildContext context) {
    final wellPosition = _getConnectionPointPosition();

    final objWidth = (widget.sourceObject.topLeft.dx - widget.sourceObject.bottomRight.dx).abs();
    final objHeight = (widget.sourceObject.topLeft.dy - widget.sourceObject.bottomRight.dy).abs();

    IconData arrowIcon = LucideIcons.x;
    double width, height;
    const double thickness = 30.0;
    switch (widget.connectionPoint) {
      case ConnectionPoint.top:
        arrowIcon = LucideIcons.arrowUp;
        width = objWidth;
        height = thickness;
        break;
      case ConnectionPoint.left:
        arrowIcon = LucideIcons.arrowLeft;
        width = thickness;
        height = objHeight;
        break;
      case ConnectionPoint.right:
        arrowIcon = LucideIcons.arrowRight;
        width = thickness;
        height = objHeight;
        break;
      case ConnectionPoint.bottom:
        arrowIcon = LucideIcons.arrowDown;
        width = objWidth;
        height = thickness;
        break;
      case ConnectionPoint.none:
        width = 0.0;
        height = 0.0;
        break;
    }

    width = width * widget.scale;
    height = height * widget.scale;

    const double wellSize = 8.0;
    const double enlargedScale = 3.0;
    final IconData displayIcon = arrowIcon;
    final Color primaryColor = ThemeHelper.blue500(context);
    final Color secondaryColor = ThemeHelper.neutral100(context);

    final isVisible = _shouldBeVisible;
    final opacity = isVisible ? 1.0 : 0.0;

    return Positioned(
      left: wellPosition.dx - (width / 2),
      top: wellPosition.dy - (height / 2),
      child: Transform.scale(
        scale: 1 / widget.scale,
        child: SizedBox(
          width: width,
          height: height,
          child: Opacity(
            opacity: opacity,
            child: MouseRegion(
              // necessary for it to be translucent because this allows the gesture to pass through to the canvas painter
              hitTestBehavior: isVisible ? HitTestBehavior.translucent : HitTestBehavior.deferToChild,
              onEnter: isVisible ? (_) => _setAreaHovered(true) : null,
              onExit: isVisible ? (_) => _setAreaHovered(false) : null,
              child: AnimatedScale(
                scale: _isAreaHovered ? enlargedScale : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: AnimatedContainer(
                        width: wellSize,
                        height: wellSize,
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: _isIconHovered || !_isAreaHovered ? primaryColor : secondaryColor,
                          border: _isIconHovered
                              ? null
                              : Border.all(
                                  color: primaryColor,
                                  width: 0.75,
                                ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          displayIcon,
                          size: wellSize - 2,
                          color: _isIconHovered ? secondaryColor : primaryColor,
                        ),
                      ),
                    ),
                    if ((_isAreaHovered && isVisible) || _isCurrentlyActive)
                      MouseRegion(
                        // necessary for it to be translucent because this allows the gesture to pass through to the canvas painter
                        hitTestBehavior: HitTestBehavior.translucent,
                        onEnter: (_) => _setIconHovered(true),
                        onExit: (_) => _setIconHovered(false),
                        child: CanvasGestureDetector(
                          gestureRouter: widget.gestureRouter!,
                          interactionContext: ArrowWellInteraction(
                            sourceObject: widget.sourceObject,
                            connectionPoint: widget.connectionPoint,
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: wellSize,
                            height: wellSize,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
