import 'package:onyxia/export.dart';
import '../gestures/gestures.dart';

/// A wrapper around GestureDetector that automatically maps Flutter gestures
/// to CanvasGestureRouter handlers with optional CanvasInteractionContext
class CanvasGestureDetector extends StatelessWidget {
  final CanvasGestureRouter gestureRouter;
  final CanvasInteractionContext interactionContext;
  final Widget child;
  final HitTestBehavior? behavior;
  final GlobalKey? gestureKey;

  // Optional conditional handlers for custom logic
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;
  final void Function(TapDownDetails)? onSecondaryTapDown;

  const CanvasGestureDetector({
    super.key,
    required this.gestureRouter,
    required this.interactionContext,
    required this.child,
    this.behavior,
    this.gestureKey,
    this.onTapDown,
    this.onTapUp,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: gestureKey,
      behavior: behavior ?? HitTestBehavior.deferToChild,
      onTapDown: onTapDown ?? gestureRouter.getHandleTapDown(interactionContext),
      onTapUp: onTapUp ?? gestureRouter.getHandleTapUp(interactionContext),
      onPanStart: onPanStart ?? gestureRouter.getHandlePanStart(interactionContext),
      onPanUpdate: onPanUpdate ?? gestureRouter.getHandlePanUpdate(),
      onPanEnd: onPanEnd ?? gestureRouter.getHandlePanEnd(),
      onSecondaryTapDown: onSecondaryTapDown ?? gestureRouter.getHandleSecondaryTapDown(interactionContext),
      child: child,
    );
  }
}
