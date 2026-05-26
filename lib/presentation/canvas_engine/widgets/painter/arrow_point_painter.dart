import 'package:touchable/touchable.dart';
import 'package:onyxia/export.dart';
import '../../gestures/gestures.dart';
import 'touchy_object_painter.dart';

class ArrowPointPainter {
  static void paint({
    required TouchyCanvas touchyCanvas,
    required BuildContext context,
    required CanvasGestureRouter? gestureRouter,
    required CanvasInteractionContext interactionContext,
    required Offset center,
    required double scale,
    required bool isInteractive,
  }) {
    const circleSize = 17.0;
    const borderSize = 3.0;

    // Create the TouchyObjectPainter for interaction
    final painter = TouchyObjectPainter(
      touchyCanvas,
      gestureRouter: gestureRouter,
      interactionContext: interactionContext,
      isInteractive: isInteractive,
    );

    final borderPaint = Paint()
      ..color = ThemeHelper.blue500(context)
      ..style = .fill;

    painter.drawCircle(center, circleSize / 2, borderPaint);

    final fillPaint = Paint()
      ..color = ThemeHelper.neutral100(context)
      ..style = .fill;

    painter.drawCircle(center, circleSize / 2 - borderSize, fillPaint);
  }
}
