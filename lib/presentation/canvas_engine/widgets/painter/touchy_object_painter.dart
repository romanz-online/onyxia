import 'package:touchable/touchable.dart';
import 'package:onyxia/export.dart';
import '../../gestures/gestures.dart';

class TouchyObjectPainter {
  final TouchyCanvas touchyCanvas;
  final CanvasGestureRouter? gestureRouter;
  final CanvasInteractionContext interactionContext;
  final bool isInteractive;

  TouchyObjectPainter(
    this.touchyCanvas, {
    required this.gestureRouter,
    required this.interactionContext,
    required this.isInteractive,
  });

  // Note: TouchyCanvas doesn't support drawImageRect

  /// Routes between non-interactive and touch-enabled drawing.
  /// Returns true if the caller should execute its touch-enabled branch.
  bool _shouldDrawInteractive(VoidCallback drawPlain) {
    if (!isInteractive) {
      drawPlain();
      return false;
    }
    return gestureRouter != null;
  }

  void drawCircle(Offset c, double radius, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawCircle(c, radius, paint))) return;
    touchyCanvas.drawCircle(
      c,
      radius,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }

  void drawRect(Rect rect, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawRect(rect, paint))) return;
    touchyCanvas.drawRect(
      rect,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }

  void drawRRect(RRect rrect, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawRRect(rrect, paint))) return;
    touchyCanvas.drawRRect(
      rrect,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }

  void drawPath(Path path, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawPath(path, paint))) return;
    touchyCanvas.drawPath(
      path,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }

  void drawOval(Rect oval, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawOval(oval, paint))) return;
    touchyCanvas.drawOval(
      oval,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }

  void drawLine(Offset p1, Offset p2, Paint paint) {
    if (!_shouldDrawInteractive(
        () => touchyCanvas.canvas.drawLine(p1, p2, paint))) return;
    touchyCanvas.drawLine(
      p1,
      p2,
      paint,
      hitTestBehavior: HitTestBehavior.opaque,
      onTapDown: gestureRouter!.getHandleTapDown(interactionContext),
      onTapUp: gestureRouter!.getHandleTapUp(interactionContext),
      onPanDown: gestureRouter!.getHandlePanDown(interactionContext),
      onPanStart: gestureRouter!.getHandlePanStart(interactionContext),
      onPanUpdate: gestureRouter!.getHandlePanUpdate(),
      onPanEnd: gestureRouter!.getHandlePanEnd(),
      onSecondaryTapDown: gestureRouter!.getHandleSecondaryTapDown(interactionContext),
      onSecondaryTapUp: gestureRouter!.getHandleSecondaryTapUp(interactionContext),
      onHover: gestureRouter!.getHandleHover(interactionContext),
      onEnter: gestureRouter!.getHandleEnter(interactionContext),
      onExit: gestureRouter!.getHandleExit(interactionContext),
      interactionContext: interactionContext,
    );
  }
}
