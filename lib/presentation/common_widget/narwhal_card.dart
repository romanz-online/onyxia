import 'package:onyxia/export.dart';

/// A generic card widget that provides consistent styling and behavior
/// for cards throughout the application (canvas cards, folder cards, note cards, etc.)
/// @ponder ponder/NarwhalCard.gif
class NarwhalCard extends StatelessWidget {
  /// The content to display inside the card
  final Widget child;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;

  /// Callback function when the card is double tapped
  final VoidCallback? onDoubleTap;

  /// Callback function for secondary tap (right-click)
  final VoidCallback? onSecondaryTap;

  /// Callback function for tap down event
  final GestureTapDownCallback? onTapDown;

  /// Callback function for tap up event
  final GestureTapUpCallback? onTapUp;

  /// Callback function for tap cancel event
  final VoidCallback? onTapCancel;

  /// Callback function for secondary tap down event
  final GestureTapDownCallback? onSecondaryTapDown;

  /// Callback function for secondary tap up event
  final GestureTapUpCallback? onSecondaryTapUp;

  /// Callback function for secondary tap cancel event
  final VoidCallback? onSecondaryTapCancel;

  /// Callback function for long press event
  final VoidCallback? onLongPress;

  /// Callback function for long press start event
  final GestureLongPressStartCallback? onLongPressStart;

  /// Callback function for long press move update event
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  /// Callback function for long press up event
  final VoidCallback? onLongPressUp;

  /// Callback function for long press end event
  final GestureLongPressEndCallback? onLongPressEnd;

  /// Callback function for secondary long press event
  final VoidCallback? onSecondaryLongPress;

  /// Callback function for pan down event
  final GestureDragDownCallback? onPanDown;

  /// Callback function for pan start event
  final GestureDragStartCallback? onPanStart;

  /// Callback function for pan update event
  final GestureDragUpdateCallback? onPanUpdate;

  /// Callback function for pan end event
  final GestureDragEndCallback? onPanEnd;

  /// Callback function for pan cancel event
  final VoidCallback? onPanCancel;

  /// Whether this card should be draggable
  final bool isDraggable;

  /// Custom data to pass when dragging (only used if isDraggable is true)
  final Object? dragData;

  /// Custom feedback widget to show when dragging (only used if isDraggable is true)
  final Widget? dragFeedback;

  /// Custom drag anchor strategy (only used if isDraggable is true)
  final DragAnchorStrategy? dragAnchorStrategy;

  /// Callback when drag starts (only used if isDraggable is true)
  final VoidCallback? onDragStarted;

  /// Callback when drag ends (only used if isDraggable is true)
  final DragEndCallback? onDragEnd;

  /// Optional width constraint
  final double? width;

  /// Optional height constraint
  final double? height;

  /// Internal padding for the card content
  final EdgeInsets? padding;

  /// Optional custom border color (overrides default selection/divider logic)
  final Color? borderColor;

  /// Optional custom border width
  final double? borderWidth;

  /// Optional custom border radius (defaults to 5)
  final double? borderRadius;

  const NarwhalCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onSecondaryLongPress,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.isDraggable = false,
    this.dragData,
    this.dragFeedback,
    this.dragAnchorStrategy,
    this.onDragStarted,
    this.onDragEnd,
    this.width,
    this.height,
    this.padding,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onSecondaryTap: onSecondaryTap,
            onTapDown: onTapDown,
            onTapUp: onTapUp,
            onTapCancel: onTapCancel,
            onSecondaryTapDown: onSecondaryTapDown,
            onSecondaryTapUp: onSecondaryTapUp,
            onSecondaryTapCancel: onSecondaryTapCancel,
            onLongPress: onLongPress,
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate,
            onLongPressUp: onLongPressUp,
            onLongPressEnd: onLongPressEnd,
            onSecondaryLongPress: onSecondaryLongPress,
            onPanDown: onPanDown,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            onPanCancel: onPanCancel,
            child: Container(
              width: width,
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: (isHovered || isSelected) ? ThemeHelper.neutral300(context) : ThemeHelper.neutral200(context),
                borderRadius: BorderRadius.circular(borderRadius ?? 5),
                border: Border.all(
                  color: borderColor ?? (isSelected ? ThemeHelper.blue400(context) : ThemeHelper.neutral400(context)),
                  width: borderWidth ?? (isSelected ? 1.5 : 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeHelper.black(context).withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );

    // Conditionally wrap with Draggable if isDraggable is true
    if (isDraggable) {
      return Draggable<Object>(
        data: dragData,
        feedback: dragFeedback ?? Container(),
        dragAnchorStrategy: dragAnchorStrategy ?? (draggable, context, position) => Offset.zero,
        onDragStarted: onDragStarted,
        onDragEnd: onDragEnd,
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: cardWidget,
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
