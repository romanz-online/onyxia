import 'dart:math';
import 'package:touchable/touchable.dart';
import 'package:onyxia/export.dart';
import '../../gestures/gestures.dart';
import '../../providers/providers.dart';
import 'touchy_object_painter.dart';
import 'touchy_dashed_painter.dart';

class CanvasObjectPaintContext {
  final TouchyObjectPainter touchyObjectPainter;
  final Canvas canvas;
  final CanvasObject object;
  final WidgetRef ref;
  final BuildContext context;
  final Paint fillPaint;
  final Paint strokePaint;
  final bool drawGaps;
  final double gapLength;
  final bool isGhost;
  final CanvasGestureRouter? gestureRouter;
  final ObjectFillInteractionContext interactionContext;
  final bool isInteractive;

  CanvasObjectPaintContext({
    required touchyCanvas,
    required this.canvas,
    required this.object,
    required this.ref,
    required this.context,
    required this.fillPaint,
    required this.strokePaint,
    required this.gestureRouter,
    required this.interactionContext,
    required this.isInteractive,
    this.drawGaps = false,
    this.gapLength = 0,
    this.isGhost = false,
  }) : touchyObjectPainter = TouchyObjectPainter(
         touchyCanvas,
         gestureRouter: gestureRouter,
         interactionContext: interactionContext,
         isInteractive: isInteractive,
       );
}

class CanvasObjectPainter {
  static void paint(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    CanvasObject object,
    BuildContext context,
    WidgetRef ref, {
    bool drawGaps = false,
    double gapLength = 0,
    bool isGhost = false,
    required CanvasGestureRouter? gestureRouter,
    required ObjectFillInteractionContext interactionContext,
    required bool isInteractive,
  }) {
    final painter = CanvasObjectPainter._(context);
    painter._paintObject(
      touchyCanvas,
      canvas,
      object,
      ref,
      drawGaps: drawGaps,
      gapLength: gapLength,
      isGhost: isGhost,
      gestureRouter: gestureRouter,
      interactionContext: interactionContext,
      isInteractive: isInteractive,
    );
  }

  final BuildContext context;

  CanvasObjectPainter._(this.context);

  void _paintObject(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    CanvasObject object,
    WidgetRef ref, {
    bool drawGaps = false,
    double gapLength = 0,
    bool isGhost = false,
    required CanvasGestureRouter? gestureRouter,
    required ObjectFillInteractionContext interactionContext,
    required bool isInteractive,
  }) {
    final fillPaint = Paint()
      ..color = object.color
      ..style = .fill;

    final strokePaint = Paint()
      ..color = _getStrokeColor(object, drawGaps)
      ..style = .stroke
      ..strokeWidth = _getStrokeWidth(object);

    final paintContext = CanvasObjectPaintContext(
      touchyCanvas: touchyCanvas,
      canvas: canvas,
      object: object,
      ref: ref,
      context: context,
      fillPaint: fillPaint,
      strokePaint: strokePaint,
      gestureRouter: gestureRouter,
      interactionContext: interactionContext,
      drawGaps: drawGaps,
      gapLength: gapLength,
      isGhost: isGhost,
      isInteractive: isInteractive,
    );

    switch (paintContext.object.type) {
      case CanvasObjectType.artifact:
      case CanvasObjectType.rectangle:
        _drawRectangle(paintContext);
        break;
      case CanvasObjectType.diamond:
        _drawDiamond(paintContext);
        break;
      case CanvasObjectType.oblong:
        _drawOblong(paintContext);
        break;
      case CanvasObjectType.circle:
        _drawCircle(paintContext);
        break;
      case CanvasObjectType.rhombus:
        _drawRhombus(paintContext);
        break;
      case CanvasObjectType.trapezoid:
        _drawTrapezoid(paintContext);
        break;
      case CanvasObjectType.cylinder:
        _drawCylinder(paintContext);
        break;
      case CanvasObjectType.house:
        _drawHouse(paintContext);
        break;
      case CanvasObjectType.reverseHouse:
        _drawReverseHouse(paintContext);
        break;
      case CanvasObjectType.brush:
        _drawBrush(paintContext);
        break;
      case CanvasObjectType.image:
        _drawImage(paintContext);
        break;
      case CanvasObjectType.arrow:
        _drawArrow(paintContext);
        break;
      case CanvasObjectType.text:
        break;
    }
  }

  void _drawDiamond(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final center = rect.center;

    final path = Path();
    path.moveTo(center.dx, rect.top); // Top point
    path.lineTo(rect.right, center.dy); // Right point
    path.lineTo(center.dx, rect.bottom); // Bottom point
    path.lineTo(rect.left, center.dy); // Left point
    path.close();

    paintContext.touchyObjectPainter.drawPath(path, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.drawGaps) {
      final halfGap = paintContext.gapLength / 2 - 1;

      // Top edge with gap
      final topGapStart = Offset(center.dx - halfGap, rect.top + halfGap);
      final topGapEnd = Offset(center.dx + halfGap, rect.top + halfGap);

      // Right edge with gap
      final rightGapStart = Offset(rect.right - halfGap, center.dy - halfGap);
      final rightGapEnd = Offset(rect.right - halfGap, center.dy + halfGap);

      // Bottom edge with gap
      final bottomGapStart = Offset(center.dx + halfGap, rect.bottom - halfGap);
      final bottomGapEnd = Offset(center.dx - halfGap, rect.bottom - halfGap);

      // Left edge with gap
      final leftGapStart = Offset(rect.left + halfGap, center.dy + halfGap);
      final leftGapEnd = Offset(rect.left + halfGap, center.dy - halfGap);

      final strokePath = Path()
        ..moveTo(topGapEnd.dx, topGapEnd.dy)
        ..lineTo(rightGapStart.dx, rightGapStart.dy)
        ..moveTo(rightGapEnd.dx, rightGapEnd.dy)
        ..lineTo(bottomGapStart.dx, bottomGapStart.dy)
        ..moveTo(bottomGapEnd.dx, bottomGapEnd.dy)
        ..lineTo(leftGapStart.dx, leftGapStart.dy)
        ..moveTo(leftGapEnd.dx, leftGapEnd.dy)
        ..lineTo(topGapStart.dx, topGapStart.dy);

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          strokePath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          strokePath,
          paintContext.strokePaint,
        );
      }
    } else {
      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          path,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawOblong(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );

    // If the oblong is close to being spherical, treat it as a circle
    if ((rect.width - rect.height).abs() <= CanvasBounds.gridSpacing) {
      return _drawCircle(paintContext);
    }

    final radius = rect.height / 2;
    final roundedRect = RRect.fromRectAndRadius(rect, .circular(radius));

    paintContext.touchyObjectPainter.drawRRect(
      roundedRect,
      paintContext.fillPaint,
    );

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;
      final Path path = Path()..addRRect(roundedRect);
      TouchyDashedPainter.paint(
        paintContext,
        path,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final path = Path();

        // For tall oblongs (height >= width), use width/2 as radius to maintain oblong shape
        final effectiveRadius = rect.width <= rect.height
            ? rect.width / 2
            : radius;

        // Calculate gap positions (center of each edge)
        final topGapStart = rect.center.dx - paintContext.gapLength / 2;
        final topGapEnd = rect.center.dx + paintContext.gapLength / 2;
        final bottomGapStart = rect.center.dx - paintContext.gapLength / 2;
        final bottomGapEnd = rect.center.dx + paintContext.gapLength / 2;
        final leftGapStart = rect.center.dy - paintContext.gapLength / 2;
        final leftGapEnd = rect.center.dy + paintContext.gapLength / 2;
        final rightGapStart = rect.center.dy - paintContext.gapLength / 2;
        final rightGapEnd = rect.center.dy + paintContext.gapLength / 2;

        if (rect.width <= rect.height) {
          // Tall oblong - top and bottom edges are semicircles, left and right are straight

          // Left edge - top part (from top semicircle to gap)
          if (leftGapStart > rect.top + effectiveRadius) {
            path.moveTo(rect.left, rect.top + effectiveRadius);
            path.lineTo(rect.left, leftGapStart);
          }

          // Left edge - bottom part (from gap to bottom semicircle)
          if (leftGapEnd < rect.bottom - effectiveRadius) {
            path.moveTo(rect.left, leftGapEnd);
            path.lineTo(rect.left, rect.bottom - effectiveRadius);
          }

          // Bottom semicircle - left part (from left to gap)
          path.arcToPoint(
            Offset(bottomGapStart, rect.bottom),
            radius: .circular(effectiveRadius),
            clockwise: false,
          );

          // Bottom semicircle - right part (from gap to right)
          path.moveTo(bottomGapEnd, rect.bottom);
          path.arcToPoint(
            Offset(rect.right, rect.bottom - effectiveRadius),
            radius: .circular(effectiveRadius),
            clockwise: false,
          );

          // Right edge - bottom part (from bottom semicircle to gap)
          if (rightGapEnd < rect.bottom - effectiveRadius) {
            path.lineTo(rect.right, rightGapEnd);
          }

          // Right edge - top part (from gap to top semicircle)
          if (rightGapStart > rect.top + effectiveRadius) {
            path.moveTo(rect.right, rightGapStart);
            path.lineTo(rect.right, rect.top + effectiveRadius);
          }

          // Top semicircle - right part (from right to gap)
          path.arcToPoint(
            Offset(topGapEnd, rect.top),
            radius: .circular(effectiveRadius),
            clockwise: false,
          );

          // Top semicircle - left part (from gap to left)
          path.moveTo(topGapStart, rect.top);
          path.arcToPoint(
            Offset(rect.left, rect.top + effectiveRadius),
            radius: .circular(effectiveRadius),
            clockwise: false,
          );
        } else {
          // Wide oblong - top and bottom edges are straight, left and right are semicircles

          // Top edge - left part (from left semicircle to gap)
          if (topGapStart > rect.left + effectiveRadius) {
            path.moveTo(rect.left + effectiveRadius, rect.top);
            path.lineTo(topGapStart, rect.top);
          }

          // Top edge - right part (from gap to right semicircle)
          if (topGapEnd < rect.right - effectiveRadius) {
            path.moveTo(topGapEnd, rect.top);
            path.lineTo(rect.right - effectiveRadius, rect.top);
          }

          // Right semicircle - top part (from top to gap)
          path.arcToPoint(
            Offset(rect.right, rightGapStart),
            radius: .circular(effectiveRadius),
            clockwise: true,
          );

          // Right semicircle - bottom part (from gap to bottom)
          path.moveTo(rect.right, rightGapEnd);
          path.arcToPoint(
            Offset(rect.right - effectiveRadius, rect.bottom),
            radius: .circular(effectiveRadius),
            clockwise: true,
          );

          // Bottom edge - right part (from right semicircle to gap)
          if (bottomGapEnd > rect.left + effectiveRadius) {
            path.lineTo(bottomGapEnd, rect.bottom);
          }

          // Bottom edge - left part (from gap to left semicircle)
          if (bottomGapStart < rect.right - effectiveRadius) {
            path.moveTo(bottomGapStart, rect.bottom);
            path.lineTo(rect.left + effectiveRadius, rect.bottom);
          }

          // Left semicircle - bottom part (from bottom to gap)
          path.arcToPoint(
            Offset(rect.left, leftGapEnd),
            radius: .circular(effectiveRadius),
            clockwise: true,
          );

          // Left semicircle - top part (from gap to top)
          path.moveTo(rect.left, leftGapStart);
          path.arcToPoint(
            Offset(rect.left + effectiveRadius, rect.top),
            radius: .circular(effectiveRadius),
            clockwise: true,
          );
        }

        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      } else {
        paintContext.touchyObjectPainter.drawRRect(
          roundedRect,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawRhombus(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final offset = rect.width * 0.2; // 20% offset for slant

    // Define the four vertices of the rhombus
    final topLeft = Offset(rect.left + offset, rect.top);
    final topRight = Offset(rect.right, rect.top);
    final bottomRight = Offset(rect.right - offset, rect.bottom);
    final bottomLeft = Offset(rect.left, rect.bottom);

    final path = Path();
    path.moveTo(topLeft.dx, topLeft.dy);
    path.lineTo(topRight.dx, topRight.dy);
    path.lineTo(bottomRight.dx, bottomRight.dy);
    path.lineTo(bottomLeft.dx, bottomLeft.dy);
    path.close();

    paintContext.touchyObjectPainter.drawPath(path, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;
      TouchyDashedPainter.paint(
        paintContext,
        path,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final strokePath = Path();

        // Calculate the center points of each actual edge
        final topEdgeCenter = Offset(
          (paintContext.object.topLeft.dx +
                  paintContext.object.bottomRight.dx) /
              2,
          topLeft.dy,
        );
        final rightEdgeCenter = Offset(
          (topRight.dx + bottomRight.dx) / 2,
          (topRight.dy + bottomRight.dy) / 2,
        );
        final bottomEdgeCenter = Offset(
          (paintContext.object.topLeft.dx +
                  paintContext.object.bottomRight.dx) /
              2,
          bottomRight.dy,
        );
        final leftEdgeCenter = Offset(
          (bottomLeft.dx + topLeft.dx) / 2,
          (bottomLeft.dy + topLeft.dy) / 2,
        );

        // Calculate gap half-length along each edge
        final halfGap = paintContext.gapLength / 2;

        // Top edge (flat horizontal)
        final topGapStart = Offset(
          topEdgeCenter.dx - halfGap,
          topEdgeCenter.dy,
        );
        final topGapEnd = Offset(topEdgeCenter.dx + halfGap, topEdgeCenter.dy);

        // Right edge (diagonal)
        final rightEdgeVector = bottomRight - topRight;
        final rightEdgeLength = rightEdgeVector.distance;
        final rightEdgeUnit = rightEdgeVector / rightEdgeLength;
        final rightGapStart = rightEdgeCenter - (rightEdgeUnit * halfGap);
        final rightGapEnd = rightEdgeCenter + (rightEdgeUnit * halfGap);

        // Bottom edge (flat horizontal)
        final bottomGapStart = Offset(
          bottomEdgeCenter.dx + halfGap,
          bottomEdgeCenter.dy,
        );
        final bottomGapEnd = Offset(
          bottomEdgeCenter.dx - halfGap,
          bottomEdgeCenter.dy,
        );

        // Left edge (diagonal)
        final leftEdgeVector = topLeft - bottomLeft;
        final leftEdgeLength = leftEdgeVector.distance;
        final leftEdgeUnit = leftEdgeVector / leftEdgeLength;
        final leftGapStart = leftEdgeCenter - (leftEdgeUnit * halfGap);
        final leftGapEnd = leftEdgeCenter + (leftEdgeUnit * halfGap);

        // Draw top edge with gap
        strokePath.moveTo(topLeft.dx, topLeft.dy);
        strokePath.lineTo(topGapStart.dx, topGapStart.dy);
        strokePath.moveTo(topGapEnd.dx, topGapEnd.dy);
        strokePath.lineTo(topRight.dx, topRight.dy);

        // Draw right edge with gap
        strokePath.lineTo(rightGapStart.dx, rightGapStart.dy);
        strokePath.moveTo(rightGapEnd.dx, rightGapEnd.dy);
        strokePath.lineTo(bottomRight.dx, bottomRight.dy);

        // Draw bottom edge with gap
        strokePath.lineTo(bottomGapStart.dx, bottomGapStart.dy);
        strokePath.moveTo(bottomGapEnd.dx, bottomGapEnd.dy);
        strokePath.lineTo(bottomLeft.dx, bottomLeft.dy);

        // Draw left edge with gap
        strokePath.lineTo(leftGapStart.dx, leftGapStart.dy);
        strokePath.moveTo(leftGapEnd.dx, leftGapEnd.dy);
        strokePath.lineTo(topLeft.dx, topLeft.dy);

        paintContext.touchyObjectPainter.drawPath(
          strokePath,
          paintContext.strokePaint,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawTrapezoid(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final topInset = rect.width * 0.2; // Top is 20% narrower

    // Define the four vertices of the trapezoid
    final topLeft = Offset(rect.left + topInset, rect.top);
    final topRight = Offset(rect.right - topInset, rect.top);
    final bottomRight = Offset(rect.right, rect.bottom);
    final bottomLeft = Offset(rect.left, rect.bottom);

    final path = Path();
    path.moveTo(topLeft.dx, topLeft.dy);
    path.lineTo(topRight.dx, topRight.dy);
    path.lineTo(bottomRight.dx, bottomRight.dy);
    path.lineTo(bottomLeft.dx, bottomLeft.dy);
    path.close();

    paintContext.touchyObjectPainter.drawPath(path, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;
      TouchyDashedPainter.paint(
        paintContext,
        path,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final strokePath = Path();

        // Calculate the center points of each actual edge
        final topEdgeCenter = Offset(
          (topLeft.dx + topRight.dx) / 2,
          (topLeft.dy + topRight.dy) / 2,
        );
        final rightEdgeCenter = Offset(
          (topRight.dx + bottomRight.dx) / 2,
          (topRight.dy + bottomRight.dy) / 2,
        );
        final bottomEdgeCenter = Offset(
          (bottomRight.dx + bottomLeft.dx) / 2,
          (bottomRight.dy + bottomLeft.dy) / 2,
        );
        final leftEdgeCenter = Offset(
          (bottomLeft.dx + topLeft.dx) / 2,
          (bottomLeft.dy + topLeft.dy) / 2,
        );

        // Calculate gap half-length along each edge
        final halfGap = paintContext.gapLength / 2;

        // Top edge (flat horizontal, narrower)
        final topGapStart = Offset(
          topEdgeCenter.dx - halfGap,
          topEdgeCenter.dy,
        );
        final topGapEnd = Offset(topEdgeCenter.dx + halfGap, topEdgeCenter.dy);

        // Right edge (diagonal from narrow top to wide bottom)
        final rightEdgeVector = bottomRight - topRight;
        final rightEdgeLength = rightEdgeVector.distance;
        final rightEdgeUnit = rightEdgeVector / rightEdgeLength;
        final rightGapStart = rightEdgeCenter - (rightEdgeUnit * halfGap);
        final rightGapEnd = rightEdgeCenter + (rightEdgeUnit * halfGap);

        // Bottom edge (flat horizontal, wider)
        final bottomGapStart = Offset(
          bottomEdgeCenter.dx + halfGap,
          bottomEdgeCenter.dy,
        );
        final bottomGapEnd = Offset(
          bottomEdgeCenter.dx - halfGap,
          bottomEdgeCenter.dy,
        );

        // Left edge (diagonal from narrow top to wide bottom)
        final leftEdgeVector = topLeft - bottomLeft;
        final leftEdgeLength = leftEdgeVector.distance;
        final leftEdgeUnit = leftEdgeVector / leftEdgeLength;
        final leftGapStart = leftEdgeCenter - (leftEdgeUnit * halfGap);
        final leftGapEnd = leftEdgeCenter + (leftEdgeUnit * halfGap);

        // Draw top edge with gap
        strokePath.moveTo(topLeft.dx, topLeft.dy);
        strokePath.lineTo(topGapStart.dx, topGapStart.dy);
        strokePath.moveTo(topGapEnd.dx, topGapEnd.dy);
        strokePath.lineTo(topRight.dx, topRight.dy);

        // Draw right edge with gap
        strokePath.lineTo(rightGapStart.dx, rightGapStart.dy);
        strokePath.moveTo(rightGapEnd.dx, rightGapEnd.dy);
        strokePath.lineTo(bottomRight.dx, bottomRight.dy);

        // Draw bottom edge with gap
        strokePath.lineTo(bottomGapStart.dx, bottomGapStart.dy);
        strokePath.moveTo(bottomGapEnd.dx, bottomGapEnd.dy);
        strokePath.lineTo(bottomLeft.dx, bottomLeft.dy);

        // Draw left edge with gap
        strokePath.lineTo(leftGapStart.dx, leftGapStart.dy);
        strokePath.moveTo(leftGapEnd.dx, leftGapEnd.dy);
        strokePath.lineTo(topLeft.dx, topLeft.dy);

        paintContext.touchyObjectPainter.drawPath(
          strokePath,
          paintContext.strokePaint,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawHouse(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final roofHeight = rect.height * 0.4; // Roof is 40% of total height
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top + roofHeight,
      rect.width,
      rect.height - roofHeight,
    );

    final seamOffset = 1;

    // Define key points
    final bottom = Offset(houseRect.left, houseRect.bottom);
    final bottomRight = Offset(houseRect.right, houseRect.bottom);
    final topRight = Offset(houseRect.right, houseRect.top + seamOffset / 2);
    final topLeft = Offset(houseRect.left, houseRect.top + seamOffset / 2);
    final roofPeak = Offset(rect.center.dx, rect.top);
    final roofBottomLeft = Offset(
      rect.left,
      rect.top + roofHeight + seamOffset,
    );
    final roofBottomRight = Offset(
      rect.right,
      rect.top + roofHeight + seamOffset,
    );

    // Draw house base (rectangle) fill
    paintContext.touchyObjectPainter.drawRect(
      houseRect,
      paintContext.fillPaint,
    );

    // Draw roof fill
    final roofPath = Path();
    roofPath.moveTo(roofBottomLeft.dx, roofBottomLeft.dy);
    roofPath.lineTo(roofPeak.dx, roofPeak.dy);
    roofPath.lineTo(roofBottomRight.dx, roofBottomRight.dy);
    paintContext.touchyObjectPainter.drawPath(roofPath, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;

      // Create combined path for dashed strokes
      final combinedPath = Path();
      combinedPath.moveTo(topLeft.dx, topLeft.dy);
      combinedPath.lineTo(bottom.dx, bottom.dy);
      combinedPath.lineTo(bottomRight.dx, bottomRight.dy);
      combinedPath.lineTo(topRight.dx, topRight.dy);
      combinedPath.lineTo(roofBottomRight.dx, roofBottomRight.dy);
      combinedPath.lineTo(roofPeak.dx, roofPeak.dy);
      combinedPath.lineTo(roofBottomLeft.dx, roofBottomLeft.dy);
      combinedPath.lineTo(topLeft.dx, topLeft.dy);

      TouchyDashedPainter.paint(
        paintContext,
        combinedPath,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final strokePath = Path();
        final halfGap = paintContext.gapLength / 2;

        // Calculate edge centers
        final leftEdgeCenter = Offset(
          (topLeft.dx + bottom.dx) / 2,
          (topLeft.dy + bottom.dy) / 2,
        );
        final bottomEdgeCenter = Offset(
          (bottom.dx + bottomRight.dx) / 2,
          (bottom.dy + bottomRight.dy) / 2,
        );
        final rightEdgeCenter = Offset(
          (bottomRight.dx + topRight.dx) / 2,
          (bottomRight.dy + topRight.dy) / 2,
        );

        // Left edge (vertical) gap
        final leftGapStart = Offset(
          leftEdgeCenter.dx,
          leftEdgeCenter.dy - halfGap,
        );
        final leftGapEnd = Offset(
          leftEdgeCenter.dx,
          leftEdgeCenter.dy + halfGap,
        );

        // Bottom edge (horizontal) gap
        final bottomGapStart = Offset(
          bottomEdgeCenter.dx - halfGap,
          bottomEdgeCenter.dy,
        );
        final bottomGapEnd = Offset(
          bottomEdgeCenter.dx + halfGap,
          bottomEdgeCenter.dy,
        );

        // Right edge (vertical) gap
        final rightGapStart = Offset(
          rightEdgeCenter.dx,
          rightEdgeCenter.dy + halfGap,
        );
        final rightGapEnd = Offset(
          rightEdgeCenter.dx,
          rightEdgeCenter.dy - halfGap,
        );

        // For roof edges, calculate diagonal gap positions
        final leftRoofEdgeCenter = Offset(
          (roofBottomLeft.dx + roofPeak.dx) / 2,
          (roofBottomLeft.dy + roofPeak.dy) / 2,
        );
        final rightRoofEdgeCenter = Offset(
          (roofPeak.dx + roofBottomRight.dx) / 2,
          (roofPeak.dy + roofBottomRight.dy) / 2,
        );

        // Left roof edge (diagonal)
        final leftRoofVector = roofPeak - roofBottomLeft;
        final leftRoofUnit = leftRoofVector / leftRoofVector.distance;
        final leftRoofGapStart = leftRoofEdgeCenter - (leftRoofUnit * halfGap);
        final leftRoofGapEnd = leftRoofEdgeCenter + (leftRoofUnit * halfGap);

        // Right roof edge (diagonal)
        final rightRoofVector = roofBottomRight - roofPeak;
        final rightRoofUnit = rightRoofVector / rightRoofVector.distance;
        final rightRoofGapStart =
            rightRoofEdgeCenter - (rightRoofUnit * halfGap);
        final rightRoofGapEnd = rightRoofEdgeCenter + (rightRoofUnit * halfGap);

        // Draw left edge with gap
        strokePath.moveTo(topLeft.dx, topLeft.dy);
        strokePath.lineTo(leftGapStart.dx, leftGapStart.dy);
        strokePath.moveTo(leftGapEnd.dx, leftGapEnd.dy);
        strokePath.lineTo(bottom.dx, bottom.dy);

        // Draw bottom edge with gap
        strokePath.lineTo(bottomGapStart.dx, bottomGapStart.dy);
        strokePath.moveTo(bottomGapEnd.dx, bottomGapEnd.dy);
        strokePath.lineTo(bottomRight.dx, bottomRight.dy);

        // Draw right edge with gap
        strokePath.lineTo(rightGapStart.dx, rightGapStart.dy);
        strokePath.moveTo(rightGapEnd.dx, rightGapEnd.dy);
        strokePath.lineTo(topRight.dx, topRight.dy);

        // Start drawing roof from right side
        strokePath.moveTo(roofBottomRight.dx, roofBottomRight.dy);
        strokePath.lineTo(rightRoofGapStart.dx, rightRoofGapStart.dy);
        strokePath.moveTo(rightRoofGapEnd.dx, rightRoofGapEnd.dy);

        // Calculate roof peak gap
        final leftRoofToPeakVector = roofPeak - roofBottomLeft;
        final rightRoofToPeakVector = roofPeak - roofBottomRight;
        final leftRoofToPeakUnit =
            leftRoofToPeakVector / leftRoofToPeakVector.distance;
        final rightRoofToPeakUnit =
            rightRoofToPeakVector / rightRoofToPeakVector.distance;

        // Create gap at the peak vertex
        final peakGapLeft = roofPeak - (leftRoofToPeakUnit * halfGap);
        final peakGapRight = roofPeak - (rightRoofToPeakUnit * halfGap);

        // Draw to peak gap start
        strokePath.lineTo(peakGapRight.dx, peakGapRight.dy);

        // Gap at peak - move to other side
        strokePath.moveTo(peakGapLeft.dx, peakGapLeft.dy);

        // Draw left roof edge with gap
        strokePath.lineTo(leftRoofGapStart.dx, leftRoofGapStart.dy);
        strokePath.moveTo(leftRoofGapEnd.dx, leftRoofGapEnd.dy);
        strokePath.lineTo(roofBottomLeft.dx, roofBottomLeft.dy);

        paintContext.touchyObjectPainter.drawPath(
          strokePath,
          paintContext.strokePaint,
        );
      } else {
        // Draw without gaps
        paintContext.touchyObjectPainter.drawLine(
          topLeft,
          bottom,
          paintContext.strokePaint,
        ); // Left
        paintContext.touchyObjectPainter.drawLine(
          bottom,
          bottomRight,
          paintContext.strokePaint,
        ); // Bottom
        paintContext.touchyObjectPainter.drawLine(
          bottomRight,
          topRight,
          paintContext.strokePaint,
        ); // Right
        paintContext.touchyObjectPainter.drawPath(
          roofPath,
          paintContext.strokePaint,
        ); // Roof
      }
    }
  }

  void _drawReverseHouse(CanvasObjectPaintContext paintContext) {
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final roofHeight = rect.height * 0.4; // Roof is 40% of total height
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - roofHeight,
    );

    final seamOffset = 1;

    // Define key points
    final top = Offset(houseRect.left, houseRect.top);
    final topRight = Offset(houseRect.right, houseRect.top);
    final topLeft = Offset(houseRect.left, houseRect.top);
    final bottomRight = Offset(
      houseRect.right,
      houseRect.bottom - seamOffset / 2,
    );
    final bottomLeft = Offset(
      houseRect.left,
      houseRect.bottom - seamOffset / 2,
    );
    final roofPeak = Offset(rect.center.dx, rect.bottom);
    final roofTopLeft = Offset(
      rect.left,
      rect.bottom - roofHeight - seamOffset,
    );
    final roofTopRight = Offset(
      rect.right,
      rect.bottom - roofHeight - seamOffset,
    );

    // Draw house base (rectangle) fill
    paintContext.touchyObjectPainter.drawRect(
      houseRect,
      paintContext.fillPaint,
    );

    // Draw roof fill (downward triangle)
    final roofPath = Path();
    roofPath.moveTo(roofTopLeft.dx, roofTopLeft.dy);
    roofPath.lineTo(roofPeak.dx, roofPeak.dy);
    roofPath.lineTo(roofTopRight.dx, roofTopRight.dy);
    paintContext.touchyObjectPainter.drawPath(roofPath, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;

      // Create combined path for dashed strokes
      final combinedPath = Path();
      combinedPath.moveTo(top.dx, top.dy);
      combinedPath.lineTo(topRight.dx, topRight.dy);
      combinedPath.lineTo(bottomRight.dx, bottomRight.dy);
      combinedPath.lineTo(roofPeak.dx, roofPeak.dy);
      combinedPath.lineTo(bottomLeft.dx, bottomLeft.dy);
      combinedPath.lineTo(topLeft.dx, topLeft.dy);
      combinedPath.lineTo(top.dx, top.dy);

      TouchyDashedPainter.paint(
        paintContext,
        combinedPath,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final strokePath = Path();
        final halfGap = paintContext.gapLength / 2;

        // Calculate edge centers for house base
        final topEdgeCenter = Offset(
          (top.dx + topRight.dx) / 2,
          (top.dy + topRight.dy) / 2,
        );
        final leftEdgeCenter = Offset(
          (top.dx + bottomLeft.dx) / 2,
          (top.dy + bottomLeft.dy) / 2,
        );
        final rightEdgeCenter = Offset(
          (topRight.dx + bottomRight.dx) / 2,
          (topRight.dy + bottomRight.dy) / 2,
        );

        // Top edge (horizontal) gap
        final topGapStart = Offset(
          topEdgeCenter.dx - halfGap,
          topEdgeCenter.dy,
        );
        final topGapEnd = Offset(topEdgeCenter.dx + halfGap, topEdgeCenter.dy);

        // Left edge (vertical) gap
        final leftGapStart = Offset(
          leftEdgeCenter.dx,
          leftEdgeCenter.dy - halfGap,
        );
        final leftGapEnd = Offset(
          leftEdgeCenter.dx,
          leftEdgeCenter.dy + halfGap,
        );

        // Right edge (vertical) gap
        final rightGapStart = Offset(
          rightEdgeCenter.dx,
          rightEdgeCenter.dy - halfGap,
        );
        final rightGapEnd = Offset(
          rightEdgeCenter.dx,
          rightEdgeCenter.dy + halfGap,
        );

        // Draw top edge with gap
        strokePath.moveTo(top.dx, top.dy);
        strokePath.lineTo(topGapStart.dx, topGapStart.dy);
        strokePath.moveTo(topGapEnd.dx, topGapEnd.dy);
        strokePath.lineTo(topRight.dx, topRight.dy);

        // Draw right edge with gap
        strokePath.lineTo(rightGapStart.dx, rightGapStart.dy);
        strokePath.moveTo(rightGapEnd.dx, rightGapEnd.dy);
        strokePath.lineTo(bottomRight.dx, bottomRight.dy);

        // Draw left edge with gap
        strokePath.moveTo(top.dx, top.dy);
        strokePath.lineTo(leftGapStart.dx, leftGapStart.dy);
        strokePath.moveTo(leftGapEnd.dx, leftGapEnd.dy);
        strokePath.lineTo(bottomLeft.dx, bottomLeft.dy);

        // Start drawing roof from left side (no gaps in diagonal edges)
        strokePath.moveTo(roofTopLeft.dx, roofTopLeft.dy);

        // Calculate roof peak gap
        final leftRoofToPeakVector = roofPeak - roofTopLeft;
        final rightRoofToPeakVector = roofPeak - roofTopRight;
        final leftRoofToPeakUnit =
            leftRoofToPeakVector / leftRoofToPeakVector.distance;
        final rightRoofToPeakUnit =
            rightRoofToPeakVector / rightRoofToPeakVector.distance;

        // Create gap at the peak vertex
        final peakGapLeft = roofPeak - (leftRoofToPeakUnit * halfGap);
        final peakGapRight = roofPeak - (rightRoofToPeakUnit * halfGap);

        // Draw left roof edge to peak gap start
        strokePath.lineTo(peakGapLeft.dx, peakGapLeft.dy);

        // Gap at peak - move to other side
        strokePath.moveTo(peakGapRight.dx, peakGapRight.dy);

        // Draw right roof edge from peak gap end
        strokePath.lineTo(roofTopRight.dx, roofTopRight.dy);

        paintContext.touchyObjectPainter.drawPath(
          strokePath,
          paintContext.strokePaint,
        );
      } else {
        // Draw without gaps
        paintContext.touchyObjectPainter.drawLine(
          top,
          topRight,
          paintContext.strokePaint,
        ); // Top
        paintContext.touchyObjectPainter.drawLine(
          top,
          bottomLeft,
          paintContext.strokePaint,
        ); // Left
        paintContext.touchyObjectPainter.drawLine(
          topRight,
          bottomRight,
          paintContext.strokePaint,
        ); // Right
        paintContext.touchyObjectPainter.drawPath(
          roofPath,
          paintContext.strokePaint,
        ); // Roof
      }
    }
  }

  void _drawImage(CanvasObjectPaintContext paintContext) {
    if (!paintContext.object.isImage) return;

    final url = paintContext.object.imageProps.imageUrl;

    var image = ImageService.getImageSync(url);

    // Configure Paint for better image quality
    Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    if (paintContext.isGhost) {
      paint = Paint()
        ..color = ThemeHelper.foreground2().withValues(alpha: 0.5)
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;
    }

    if (image != null) {
      // Draw the image using regular Canvas
      paintContext.canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromPoints(
          paintContext.object.topLeft,
          paintContext.object.bottomRight,
        ),
        paint,
      );

      // Add an invisible TouchyCanvas rectangle over the image for hit detection
      final hitDetectionRect = Rect.fromPoints(
        paintContext.object.topLeft,
        paintContext.object.bottomRight,
      );
      final invisiblePaint = Paint()
        ..color = Colors.transparent
        ..style = .fill;

      paintContext.touchyObjectPainter.drawRect(
        hitDetectionRect,
        invisiblePaint,
      );
    }
  }

  void _drawArrow(CanvasObjectPaintContext paintContext) {
    if (!paintContext.object.isArrow) return;

    Paint paint = Paint()
      ..strokeWidth = _getStrokeWidth(paintContext.object)
      ..color = paintContext.object.color
      ..style = .stroke
      ..strokeCap = .round;

    final points = paintContext.object.arrowProps.points;
    if (points.isEmpty) return;

    final startObj = paintContext.object.getStartObject(paintContext.ref);
    final endObj = paintContext.object.getEndObject(paintContext.ref);
    if ((startObj != null && startObj.isPointInObject(points.last)) ||
        (endObj != null && endObj.isPointInObject(points.first))) {
      return;
    }

    if (paintContext.object.arrowProps.arrowType == ArrowType.curved) {
      _drawCurvedArrow(paintContext, paint, points.first, points.last);
      return;
    }

    final arrowSize = 16.0;
    final startPoint = points.first;
    final secondPoint = points[1];
    final endpoint = points.last;
    final secondLastPoint = points[points.length - 2];

    final endDirectionVector = Offset(
      endpoint.dx - secondLastPoint.dx,
      endpoint.dy - secondLastPoint.dy,
    );
    final endMagnitude = sqrt(
      endDirectionVector.dx * endDirectionVector.dx +
          endDirectionVector.dy * endDirectionVector.dy,
    );
    if (endMagnitude == 0) return;
    final endNormalizedDirection = Offset(
      endDirectionVector.dx / endMagnitude,
      endDirectionVector.dy / endMagnitude,
    );

    final startDirectionVector = Offset(
      secondPoint.dx - startPoint.dx,
      secondPoint.dy - startPoint.dy,
    );
    final startMagnitude = sqrt(
      startDirectionVector.dx * startDirectionVector.dx +
          startDirectionVector.dy * startDirectionVector.dy,
    );
    if (startMagnitude == 0) return;
    final startNormalizedDirection = Offset(
      startDirectionVector.dx / startMagnitude,
      startDirectionVector.dy / startMagnitude,
    );

    Offset adjustedEndpoint = endpoint;
    Offset adjustedStartPoint = startPoint;
    if (paintContext.object.arrowProps.endTip != ArrowTip.none) {
      adjustedEndpoint = endpoint - endNormalizedDirection * arrowSize * 0.4;
    }
    if (paintContext.object.arrowProps.startTip != ArrowTip.none) {
      adjustedStartPoint =
          startPoint + startNormalizedDirection * arrowSize * 0.5;
    }

    adjustedEndpoint = adjustedEndpoint - endNormalizedDirection;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 8.0;
      final dashSpace = 6.0;
      for (int i = 0; i < points.length - 1; i++) {
        final current = i == 0 ? adjustedStartPoint : points[i];
        final next = i == points.length - 2 ? adjustedEndpoint : points[i + 1];

        final vector = Offset(next.dx - current.dx, next.dy - current.dy);
        final distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy);
        if (distance <= 0) continue;

        final normalized = Offset(vector.dx / distance, vector.dy / distance);

        // Draw visible dashed segments on regular canvas
        double drawn = 0.0;
        bool isDash = true;
        while (drawn < distance) {
          final remaining = distance - drawn;
          final segmentLength = isDash
              ? min(dashWidth, remaining)
              : min(dashSpace, remaining);

          final start = current + normalized * drawn;
          final end = current + normalized * (drawn + segmentLength);

          if (isDash) {
            paintContext.canvas.drawLine(start, end, paint);
          }

          drawn += segmentLength;
          isDash = !isDash;
        }

        // Draw invisible hitbox for the entire segment
        _drawArrowSegmentHitbox(paintContext, current, next);
      }
    } else {
      final cornerRadius = 6.0;
      final path = Path()..moveTo(adjustedStartPoint.dx, adjustedStartPoint.dy);
      for (int i = 1; i < points.length - 1; i++) {
        final prev = i == 1 ? adjustedStartPoint : points[i - 1];
        final current = points[i];
        final next = points[i + 1];

        final v1 = Offset(current.dx - prev.dx, current.dy - prev.dy);
        final v2 = Offset(next.dx - current.dx, next.dy - current.dy);

        if (v1.distance > 0 && v2.distance > 0) {
          final p1 = current - (v1 / v1.distance) * cornerRadius;
          final p2 = current + (v2 / v2.distance) * cornerRadius;

          path.lineTo(p1.dx, p1.dy);
          path.quadraticBezierTo(current.dx, current.dy, p2.dx, p2.dy);
        } else {
          path.lineTo(current.dx, current.dy);
        }
      }
      path.lineTo(adjustedEndpoint.dx, adjustedEndpoint.dy);

      // Draw visible arrow path on regular canvas
      paintContext.canvas.drawPath(path, paint);

      // Draw invisible hitboxes for each segment
      for (int i = 0; i < points.length - 1; i++) {
        final current = i == 0 ? adjustedStartPoint : points[i];
        final next = i == points.length - 2 ? adjustedEndpoint : points[i + 1];
        _drawArrowSegmentHitbox(paintContext, current, next);
      }
    }

    _drawArrowTip(
      paintContext,
      endpoint,
      endNormalizedDirection,
      paintContext.object.arrowProps.endTip,
      arrowSize,
      isGhost: paintContext.isGhost,
    );

    _drawArrowTip(
      paintContext,
      startPoint,
      -startNormalizedDirection, // Reverse direction for start tip
      paintContext.object.arrowProps.startTip,
      arrowSize,
      isGhost: paintContext.isGhost,
    );
  }

  void _drawCurvedArrow(
    CanvasObjectPaintContext paintContext,
    Paint paint,
    Offset start,
    Offset end,
  ) {
    // Calculate direction vector and distance
    final direction = end - start;
    final distance = direction.distance;

    // Control point offset based on distance
    final controlPointOffset = distance * 0.2; // Adjusted for gentler curve

    ConnectionPoint startPoint = paintContext.object.arrowProps.startPoint;
    ConnectionPoint endPoint = paintContext.object.arrowProps.endPoint;

    // Determine if we should flip the connection direction based on end position
    bool shouldFlip = false;
    switch (startPoint) {
      case ConnectionPoint.right:
        shouldFlip = direction.dx < 0;
        break;
      case ConnectionPoint.left:
        shouldFlip = direction.dx > 0;
        break;
      case ConnectionPoint.top:
        shouldFlip = direction.dy > 0;
        break;
      case ConnectionPoint.bottom:
        shouldFlip = direction.dy < 0;
        break;
      case ConnectionPoint.none:
        break;
    }

    // Use the appropriate connection direction
    ConnectionPoint effectiveStartPoint = startPoint;
    if (shouldFlip) {
      effectiveStartPoint = switch (startPoint) {
        ConnectionPoint.right => ConnectionPoint.left,
        ConnectionPoint.left => ConnectionPoint.right,
        ConnectionPoint.top => ConnectionPoint.bottom,
        ConnectionPoint.bottom => ConnectionPoint.top,
        ConnectionPoint.none => ConnectionPoint.none,
      };
    }

    // Determine the initial direction based on effective start connection point
    Offset initialDirection;
    switch (effectiveStartPoint) {
      case ConnectionPoint.right:
        initialDirection = Offset(1, 0);
        break;
      case ConnectionPoint.left:
        initialDirection = Offset(-1, 0);
        break;
      case ConnectionPoint.top:
        initialDirection = Offset(0, -1);
        break;
      case ConnectionPoint.bottom:
        initialDirection = Offset(0, 1);
        break;
      case ConnectionPoint.none:
        initialDirection = Offset(1, 1);
        break;
    }

    // Determine the final direction based on end connection point
    Offset finalDirection;
    switch (endPoint) {
      case ConnectionPoint.right:
        finalDirection = Offset(-1, 0);
        break;
      case ConnectionPoint.left:
        finalDirection = Offset(1, 0);
        break;
      case ConnectionPoint.top:
        finalDirection = Offset(0, 1);
        break;
      case ConnectionPoint.bottom:
        finalDirection = Offset(0, -1);
        break;
      case ConnectionPoint.none:
        // If no end point specified, use opposite of initial direction
        finalDirection = Offset(initialDirection.dx, initialDirection.dy);
        break;
    }

    // Calculate a shortened end point to avoid interfering with arrowhead
    const arrowHeadLength = 16.0;
    final shortenedEnd = Offset(
      end.dx - (arrowHeadLength / 2) * finalDirection.dx,
      end.dy - (arrowHeadLength / 2) * finalDirection.dy,
    );

    // First control point extends from start in the initial direction
    final controlPoint1 = Offset(
      start.dx + controlPointOffset * initialDirection.dx,
      start.dy + controlPointOffset * initialDirection.dy,
    );

    // Second control point approaches the SHORTENED end from the final direction
    final controlPoint2 = Offset(
      shortenedEnd.dx - controlPointOffset * finalDirection.dx,
      shortenedEnd.dy - controlPointOffset * finalDirection.dy,
    );

    // Draw the curved path to the shortened end point
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      shortenedEnd.dx, // Use shortened end instead of original end
      shortenedEnd.dy,
    );

    paintContext.touchyObjectPainter.drawPath(path, paint);

    // Calculate arrowhead direction from the final direction (still use original end)
    final angle = atan2(finalDirection.dy, finalDirection.dx);
    const arrowHeadAngle = pi / 6; // 30 degrees

    final arrowHeadPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = .fill;

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy); // Arrowhead still at original end
    arrowPath.lineTo(
      end.dx - arrowHeadLength * cos(angle - arrowHeadAngle),
      end.dy - arrowHeadLength * sin(angle - arrowHeadAngle),
    );
    arrowPath.lineTo(
      end.dx - arrowHeadLength * cos(angle + arrowHeadAngle),
      end.dy - arrowHeadLength * sin(angle + arrowHeadAngle),
    );
    arrowPath.close();

    paintContext.touchyObjectPainter.drawPath(arrowPath, arrowHeadPaint);
  }

  void _drawArrowTip(
    CanvasObjectPaintContext paintContext,
    Offset point,
    Offset direction,
    ArrowTip tipType,
    double arrowSize, {
    bool isGhost = false,
  }) {
    final CanvasObject arrow = paintContext.object;
    if (!arrow.isArrow) return;

    Paint paint = Paint()
      ..strokeWidth = arrow.stroke == StrokeType.thick ? 5 : 4
      ..color = arrow.color
      ..style = .stroke
      ..strokeCap = .round;

    switch (tipType) {
      case ArrowTip.none:
        break;
      case ArrowTip.triangle:
        final angle = atan2(direction.dy, direction.dx);
        final arrowAngle1 = angle - pi / 5, arrowAngle2 = angle + pi / 5;
        final arrowHeadPath = Path()
          ..moveTo(point.dx, point.dy)
          ..lineTo(
            point.dx - arrowSize * cos(arrowAngle1),
            point.dy - arrowSize * sin(arrowAngle1),
          )
          ..lineTo(
            point.dx - arrowSize * cos(arrowAngle2),
            point.dy - arrowSize * sin(arrowAngle2),
          )
          ..close();

        if (isGhost) {
          final clearPaint = Paint()
            ..blendMode = BlendMode.clear
            ..style = .fill;
          paintContext.canvas.drawPath(arrowHeadPath, clearPaint);
        }

        paintContext.canvas.drawPath(arrowHeadPath, paint..style = .fill);
        break;
      case ArrowTip.circle:
        final circleRadius = 6.0;

        paintContext.canvas.drawCircle(point, circleRadius, paint);

        final innerPaint = Paint()
          ..style = .fill
          ..color = Colors.black;
        paintContext.canvas.drawCircle(
          point,
          circleRadius - paint.strokeWidth / 2 + 1,
          innerPaint,
        );
        break;
    }
  }

  void _drawArrowSegmentHitbox(
    CanvasObjectPaintContext paintContext,
    Offset start,
    Offset end,
  ) {
    final hitboxThickness = 16.0;
    final vector = end - start;
    final isVertical = vector.dy.abs() > vector.dx.abs();

    final Rect hitboxRect;
    if (isVertical) {
      // Vertical segment - add horizontal padding
      hitboxRect = Rect.fromLTWH(
        min(start.dx, end.dx) - hitboxThickness / 2,
        min(start.dy, end.dy),
        hitboxThickness,
        (end.dy - start.dy).abs(),
      );
    } else {
      // Horizontal segment - add vertical padding
      hitboxRect = Rect.fromLTWH(
        min(start.dx, end.dx),
        min(start.dy, end.dy) - hitboxThickness / 2,
        (end.dx - start.dx).abs(),
        hitboxThickness,
      );
    }

    paintContext.touchyObjectPainter.drawRect(
      hitboxRect,
      Paint()..color = Colors.transparent,
    );
  }

  void _drawCircle(CanvasObjectPaintContext paintContext) {
    final center = Offset(
      (paintContext.object.topLeft.dx + paintContext.object.bottomRight.dx) / 2,
      (paintContext.object.topLeft.dy + paintContext.object.bottomRight.dy) / 2,
    );

    final width =
        (paintContext.object.bottomRight.dx - paintContext.object.topLeft.dx)
            .abs();
    final height =
        (paintContext.object.bottomRight.dy - paintContext.object.topLeft.dy)
            .abs();

    final ovalRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    paintContext.touchyObjectPainter.drawOval(ovalRect, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      final dashWidth = 4.0;
      final dashSpace = 4.0;
      final Path path = Path()..addOval(ovalRect);
      TouchyDashedPainter.paint(
        paintContext,
        path,
        paintContext.strokePaint,
        span: dashWidth,
        step: dashSpace,
      );
    } else {
      if (paintContext.drawGaps) {
        final path = Path();
        final halfGap = paintContext.gapLength / 2;

        // Calculate gap positions at the cardinal points (top, right, bottom, left)
        final radiusX = width / 2;
        final radiusY = height / 2;

        // Gap angles in radians (top, right, bottom, left)
        final topAngle = -pi / 2;
        final rightAngle = 0.0;
        final bottomAngle = pi / 2;
        final leftAngle = pi;

        // Calculate gap arc lengths
        final gapAngleX = halfGap / radiusX; // Arc angle for horizontal gaps
        final gapAngleY = halfGap / radiusY; // Arc angle for vertical gaps

        // Draw oval with gaps at cardinal points
        // Start from top gap end, go clockwise
        path.addArc(
          ovalRect,
          topAngle + gapAngleY,
          rightAngle - topAngle - gapAngleY - gapAngleX,
        );

        // Skip right gap, continue from right gap end
        path.moveTo(
          center.dx + radiusX * cos(rightAngle + gapAngleX),
          center.dy + radiusY * sin(rightAngle + gapAngleX),
        );
        path.addArc(
          ovalRect,
          rightAngle + gapAngleX,
          bottomAngle - rightAngle - gapAngleX - gapAngleY,
        );

        // Skip bottom gap, continue from bottom gap end
        path.moveTo(
          center.dx + radiusX * cos(bottomAngle + gapAngleY),
          center.dy + radiusY * sin(bottomAngle + gapAngleY),
        );
        path.addArc(
          ovalRect,
          bottomAngle + gapAngleY,
          leftAngle - bottomAngle - gapAngleY - gapAngleX,
        );

        // Skip left gap, continue from left gap end
        path.moveTo(
          center.dx + radiusX * cos(leftAngle + gapAngleX),
          center.dy + radiusY * sin(leftAngle + gapAngleX),
        );
        path.addArc(
          ovalRect,
          leftAngle + gapAngleX,
          topAngle + 2 * pi - leftAngle - gapAngleX - gapAngleY,
        );

        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      } else {
        paintContext.touchyObjectPainter.drawOval(
          ovalRect,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawRectangle(CanvasObjectPaintContext paintContext) {
    final radius = 8.0;
    final rect = Rect.fromPoints(
      paintContext.object.topLeft,
      paintContext.object.bottomRight,
    );
    final rrect = RRect.fromRectAndRadius(rect, .circular(radius));

    paintContext.touchyObjectPainter.drawRRect(rrect, paintContext.fillPaint);

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.object.stroke == StrokeType.dashed) {
      TouchyDashedPainter.paint(
        paintContext,
        Path()..addRRect(rrect),
        paintContext.strokePaint,
        span: 4,
        step: 4,
      );
    } else {
      if (paintContext.drawGaps) {
        final path = Path();

        // Calculate gap positions (center of each edge)
        final topGapStart = rect.center.dx - paintContext.gapLength / 2;
        final topGapEnd = rect.center.dx + paintContext.gapLength / 2;
        final bottomGapStart = rect.center.dx - paintContext.gapLength / 2;
        final bottomGapEnd = rect.center.dx + paintContext.gapLength / 2;
        final leftGapStart = rect.center.dy - paintContext.gapLength / 2;
        final leftGapEnd = rect.center.dy + paintContext.gapLength / 2;
        final rightGapStart = rect.center.dy - paintContext.gapLength / 2;
        final rightGapEnd = rect.center.dy + paintContext.gapLength / 2;

        // Top edge - left part (from top-left corner to gap)
        path.moveTo(rect.left + radius, rect.top);
        path.lineTo(topGapStart, rect.top);

        // Top edge - right part (from gap to top-right corner)
        path.moveTo(topGapEnd, rect.top);
        path.lineTo(rect.right - radius, rect.top);

        // Top-right corner
        path.arcToPoint(
          Offset(rect.right, rect.top + radius),
          radius: .circular(radius),
        );

        // Right edge - top part (from corner to gap)
        path.lineTo(rect.right, rightGapStart);

        // Right edge - bottom part (from gap to corner)
        path.moveTo(rect.right, rightGapEnd);
        path.lineTo(rect.right, rect.bottom - radius);

        // Bottom-right corner
        path.arcToPoint(
          Offset(rect.right - radius, rect.bottom),
          radius: .circular(radius),
        );

        // Bottom edge - right part (from corner to gap)
        path.lineTo(bottomGapEnd, rect.bottom);

        // Bottom edge - left part (from gap to corner)
        path.moveTo(bottomGapStart, rect.bottom);
        path.lineTo(rect.left + radius, rect.bottom);

        // Bottom-left corner
        path.arcToPoint(
          Offset(rect.left, rect.bottom - radius),
          radius: .circular(radius),
        );

        // Left edge - bottom part (from corner to gap)
        path.lineTo(rect.left, leftGapEnd);

        // Left edge - top part (from gap to corner)
        path.moveTo(rect.left, leftGapStart);
        path.lineTo(rect.left, rect.top + radius);

        // Top-left corner
        path.arcToPoint(
          Offset(rect.left + radius, rect.top),
          radius: .circular(radius),
        );

        paintContext.touchyObjectPainter.drawPath(
          path,
          paintContext.strokePaint,
        );
      } else {
        paintContext.touchyObjectPainter.drawRRect(
          rrect,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawCylinder(CanvasObjectPaintContext paintContext) {
    // Calculate dimensions
    final double width =
        paintContext.object.bottomRight.dx - paintContext.object.topLeft.dx;
    final double height =
        paintContext.object.bottomRight.dy - paintContext.object.topLeft.dy;

    // Define the radius of the cylinder's ends (for barrel shape)
    final double radiusX = width / 2;
    final double radiusY = height / 6; // Makes the ends oval

    // Top and bottom center points
    final Offset topCenter = Offset(
      paintContext.object.topLeft.dx + radiusX,
      paintContext.object.topLeft.dy + radiusY,
    );
    final Offset bottomCenter = Offset(
      paintContext.object.topLeft.dx + radiusX,
      paintContext.object.bottomRight.dy - radiusY,
    );

    // Draw the body (middle rectangle)
    final Rect bodyRect = Rect.fromLTRB(
      paintContext.object.topLeft.dx,
      paintContext.object.topLeft.dy + radiusY,
      paintContext.object.bottomRight.dx,
      paintContext.object.bottomRight.dy - radiusY,
    );

    paintContext.touchyObjectPainter.drawRect(bodyRect, paintContext.fillPaint);

    // Draw the top and bottom oval ends
    final Rect topOvalRect = Rect.fromCenter(
      center: topCenter,
      width: width,
      height: radiusY * 2,
    );
    final Rect bottomOvalRect = Rect.fromCenter(
      center: bottomCenter,
      width: width,
      height: radiusY * 2,
    );

    paintContext.touchyObjectPainter.drawOval(
      topOvalRect,
      paintContext.fillPaint,
    );
    paintContext.touchyObjectPainter.drawOval(
      bottomOvalRect,
      paintContext.fillPaint,
    );

    if (paintContext.object.stroke == StrokeType.none) return;

    if (paintContext.drawGaps) {
      // Calculate gap positions for bounding rect edge centers
      final Rect boundingRect = Rect.fromLTRB(
        paintContext.object.topLeft.dx,
        paintContext.object.topLeft.dy,
        paintContext.object.bottomRight.dx,
        paintContext.object.bottomRight.dy,
      );

      final double halfGap = paintContext.gapLength / 2;

      // Right edge center
      final Offset rightEdgeCenter = Offset(
        boundingRect.right,
        boundingRect.center.dy,
      );
      final double rightGapTop = rightEdgeCenter.dy - halfGap;
      final double rightGapBottom = rightEdgeCenter.dy + halfGap;

      // Left edge center
      final Offset leftEdgeCenter = Offset(
        boundingRect.left,
        boundingRect.center.dy,
      );
      final double leftGapTop = leftEdgeCenter.dy - halfGap;
      final double leftGapBottom = leftEdgeCenter.dy + halfGap;

      // Draw top oval with gap (only the top half, visible part)
      final Path topOvalPath = Path();
      final double radiusXDouble = radiusX;

      // Calculate gap angles for top oval
      final double gapAngleX = halfGap / radiusXDouble;

      // Top oval - only draw the upward arc (top half) with gap at top center
      final double topAngle = -pi / 2; // Top
      final double leftAngle = pi; // Left

      // Draw top half arc with small gap at top center
      // Calculate proper gap angle for the arc
      final double topGapAngle = gapAngleX;

      // Draw from left to just before top gap (going clockwise, positive direction)
      topOvalPath.addArc(topOvalRect, leftAngle, pi / 2 - topGapAngle);
      // Draw from just after top gap to right
      topOvalPath.addArc(
        topOvalRect,
        topAngle + topGapAngle,
        pi / 2 + topGapAngle,
      );

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          topOvalPath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          topOvalPath,
          paintContext.strokePaint,
        );
      }

      // Draw bottom oval with gap (only the bottom half, visible part)
      final Path bottomOvalPath = Path();

      // Bottom oval - only draw the bottom half with gap at bottom center (mimic non-gap pattern)
      final double bottomRightAngle = 0;
      final double bottomBottomAngle = pi / 2;
      final double bottomLeftAngle = pi;

      // Draw bottom half arc with small gap at bottom center
      // Calculate proper gap angle for the arc
      final double bottomGapAngle = gapAngleX;

      // Draw from right to just before bottom gap
      bottomOvalPath.addArc(
        bottomOvalRect,
        bottomRightAngle,
        bottomBottomAngle - bottomRightAngle - bottomGapAngle,
      );
      // Draw from just after bottom gap to left
      bottomOvalPath.addArc(
        bottomOvalRect,
        bottomBottomAngle + bottomGapAngle,
        bottomLeftAngle - bottomBottomAngle - bottomGapAngle,
      );

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          bottomOvalPath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          bottomOvalPath,
          paintContext.strokePaint,
        );
      }

      // Draw left border of rectangle body with gap
      final Path leftBorderPath = Path();
      leftBorderPath.moveTo(bodyRect.left, bodyRect.top);
      leftBorderPath.lineTo(bodyRect.left, leftGapTop);
      leftBorderPath.moveTo(bodyRect.left, leftGapBottom);
      leftBorderPath.lineTo(bodyRect.left, bodyRect.bottom);

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          leftBorderPath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          leftBorderPath,
          paintContext.strokePaint,
        );
      }

      // Draw right border of rectangle body with gap
      final Path rightBorderPath = Path();
      rightBorderPath.moveTo(bodyRect.right, bodyRect.top);
      rightBorderPath.lineTo(bodyRect.right, rightGapTop);
      rightBorderPath.moveTo(bodyRect.right, rightGapBottom);
      rightBorderPath.lineTo(bodyRect.right, bodyRect.bottom);

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          rightBorderPath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          rightBorderPath,
          paintContext.strokePaint,
        );
      }
    } else {
      // Draw top and bottom ovals with borders (only visible halves)
      final Path topOvalPathNoGap = Path();
      final Path bottomOvalPathNoGap = Path();

      final double rightAngle = 0;
      final double leftAngle = pi;

      // Draw top half arc
      topOvalPathNoGap.addArc(topOvalRect, leftAngle, rightAngle + leftAngle);

      // Bottom oval - only the bottom half (from right to left through bottom)
      final double bottomRightAngle = 0;
      final double bottomLeftAngle = pi;

      bottomOvalPathNoGap.addArc(
        bottomOvalRect,
        bottomRightAngle,
        bottomLeftAngle - bottomRightAngle,
      );

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          topOvalPathNoGap,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
        TouchyDashedPainter.paint(
          paintContext,
          bottomOvalPathNoGap,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          topOvalPathNoGap,
          paintContext.strokePaint,
        );
        paintContext.touchyObjectPainter.drawPath(
          bottomOvalPathNoGap,
          paintContext.strokePaint,
        );
      }

      // Draw left and right borders of rectangle body only
      final Path bodyBorderPath = Path();
      bodyBorderPath.moveTo(bodyRect.left, bodyRect.top);
      bodyBorderPath.lineTo(bodyRect.left, bodyRect.bottom);
      bodyBorderPath.moveTo(bodyRect.right, bodyRect.top);
      bodyBorderPath.lineTo(bodyRect.right, bodyRect.bottom);

      if (paintContext.object.stroke == StrokeType.dashed) {
        TouchyDashedPainter.paint(
          paintContext,
          bodyBorderPath,
          paintContext.strokePaint,
          span: 4,
          step: 8,
        );
      } else {
        paintContext.touchyObjectPainter.drawPath(
          bodyBorderPath,
          paintContext.strokePaint,
        );
      }
    }
  }

  void _drawBrush(CanvasObjectPaintContext paintContext) {
    if (!paintContext.object.isBrush ||
        paintContext.object.brushProps.points.isEmpty)
      return;

    final points = paintContext.object.brushProps.points;

    final strokePaint = Paint()
      ..color = paintContext.object.color
      ..style = .stroke
      ..strokeWidth = _getStrokeWidth(paintContext.object)
      ..strokeCap = .round
      ..strokeJoin = .round;

    // Create a path from all points
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    paintContext.touchyObjectPainter.drawPath(path, strokePaint);
  }

  Color _getStrokeColor(CanvasObject object, bool drawGaps) {
    if (drawGaps) {
      return ThemeHelper.accent();
    } else if (object.color == ThemeHelper.background1()) {
      return ThemeHelper.foreground2();
    }

    final hsl = HSLColor.fromColor(object.color);
    final hslDark = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  double _getStrokeWidth(CanvasObject object) => switch (object.stroke) {
    .dashed || .solid => 3.5,
    .thick => 6.0,
    .none => 2.0,
  };
}
