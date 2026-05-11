import 'dart:ui' as ui;
import 'package:onyxia/export.dart';
import 'canvas_object_painter.dart';

/// A helper class that mimics DashedPainter functionality but works with TouchyCanvas
/// to enable touch detection on dashed strokes
class TouchyDashedPainter {
  static void paint(
    CanvasObjectPaintContext paintContext,
    Path path,
    Paint paint, {
    required double span,
    required double step,
  }) {
    final ui.PathMetrics pathMetrics = path.computeMetrics();

    for (final ui.PathMetric metric in pathMetrics) {
      double distance = 0.0;

      while (distance < metric.length) {
        final double nextDash = distance + span;
        final double nextEnd = nextDash > metric.length ? metric.length : nextDash;

        // Extract the dash segment
        final Path dashPath = metric.extractPath(distance, nextEnd);

        // Draw the dash using TouchyCanvas with gesture callbacks
        paintContext.touchyObjectPainter.drawPath(dashPath, paint);

        // Move to next dash position (skip the gap)
        distance = nextDash + step;
      }
    }
  }
}
