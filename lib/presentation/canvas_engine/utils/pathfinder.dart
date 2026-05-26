import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/canvas_engine/providers/providers.dart';

class Pathfinder {
  final double spacing = CanvasBounds.gridSpacing;

  static List<Offset> findPath(
    Offset startOffset,
    Offset endOffset,
    CanvasObject? startObject,
    CanvasObject? endObject,
    ConnectionPoint startPoint,
    ConnectionPoint endPoint,
  ) {
    final pathfinder = Pathfinder._internal();
    return pathfinder._executeFindPath(
      startOffset,
      endOffset,
      startObject,
      endObject,
      startPoint,
      endPoint,
    );
  }

  Pathfinder._internal();

  Offset _calculateJutPoint(
    Offset connectionOffset,
    CanvasObject? object,
    ConnectionPoint connectionPoint,
  ) {
    if (object == null || connectionPoint == ConnectionPoint.none) {
      return connectionOffset;
    }

    switch (connectionPoint) {
      case ConnectionPoint.top:
        return Offset(connectionOffset.dx, object.topLeft.dy - spacing);
      case ConnectionPoint.bottom:
        return Offset(connectionOffset.dx, object.bottomRight.dy + spacing);
      case ConnectionPoint.left:
        return Offset(object.topLeft.dx - spacing, connectionOffset.dy);
      case ConnectionPoint.right:
        return Offset(object.bottomRight.dx + spacing, connectionOffset.dy);
      case ConnectionPoint.none:
        throw UnimplementedError('Connection point should be defined.');
    }
  }

  List<Offset> _executeFindPath(
    Offset startOffset,
    Offset endOffset,
    CanvasObject? startObject,
    CanvasObject? endObject,
    ConnectionPoint startPoint,
    ConnectionPoint endPoint,
  ) {
    final List<Offset> path = [];

    final Offset startJut = _calculateJutPoint(
      startOffset,
      startObject,
      startPoint,
    );

    // print('startOffset $startOffset');
    path.add(startOffset);
    // print('startJut $startJut');
    path.add(startJut);

    final Offset endJut = _calculateJutPoint(endOffset, endObject, endPoint);

    // Try direct vision first
    final Offset? directVision = _getVisionOffset(
      startJut,
      endJut,
      startObject,
      endObject,
      horizontal: _isMovementHorizontal(startJut, startOffset),
    );

    if (directVision != null) {
      // print('Direct vision found: $directVision');
      if (directVision != startJut && directVision != endJut) {
        path.add(directVision);
      }
    } else {
      // print('No direct vision, wrapping around start object');
      try {
        _wrapAroundStartObject(
          startJut,
          endJut,
          startObject,
          endObject,
          startPoint,
          path,
        );
      } catch (e) {
        return [];
      }
    }

    if (endJut != endOffset) {
      // print('endJut $endJut');
      path.add(endJut);
    }
    // print('endOffset $endOffset');
    path.add(endOffset);

    return path;
  }

  void _wrapAroundStartObject(
    Offset startJut,
    Offset endJut,
    CanvasObject? startObject,
    CanvasObject? endObject,
    ConnectionPoint startPoint,
    List<Offset> path,
  ) {
    // Determine optimal wrapping direction
    final Offset directionToEnd = _getClosestDirection(startJut, endJut);
    final bool wrapClockwise = _shouldWrapClockwise(startPoint, directionToEnd);

    // Generate perimeter points around start object
    final List<Offset> perimeterPoints = _generatePerimeterPath(
      startObject,
      startJut,
      startPoint,
      wrapClockwise,
    );

    // Test vision at each perimeter point
    for (int i = 0; i < perimeterPoints.length; i++) {
      final perimeterPoint = perimeterPoints[i];
      final Offset? bridgePoint = _getVisionOffset(
        perimeterPoint,
        endJut,
        startObject,
        endObject,
        horizontal: _isMovementHorizontal(perimeterPoint, endJut),
      );

      if (bridgePoint != null) {
        // print('Found bridge point at: $perimeterPoint -> $bridgePoint');

        // Add all intermediate perimeter points we traversed to get here
        for (int j = 0; j <= i; j++) {
          final intermediatePoint = perimeterPoints[j];
          if (intermediatePoint != startJut &&
              !path.contains(intermediatePoint)) {
            path.add(intermediatePoint);
            // print('Added intermediate point: $intermediatePoint');
          }
        }

        // Add the bridge point if it's different
        if (bridgePoint != perimeterPoint && bridgePoint != endJut) {
          path.add(bridgePoint);
          // print('Added bridge point: $bridgePoint');
        }
        return;
      }
    }

    // no path was found (shouldn't ever happen)
    throw UnimplementedError(
      'Warning: No path found after wrapping around start object',
    );
  }

  bool _shouldWrapClockwise(ConnectionPoint startPoint, Offset directionToEnd) {
    // Determine which wrap direction initially moves toward the end point
    switch (startPoint) {
      case ConnectionPoint.top:
        return directionToEnd.dx > 0; // Go right if end is rightward
      case ConnectionPoint.right:
        return directionToEnd.dy > 0; // Go down if end is downward
      case ConnectionPoint.bottom:
        return directionToEnd.dx < 0; // Go left if end is leftward
      case ConnectionPoint.left:
        return directionToEnd.dy < 0; // Go up if end is upward
      case ConnectionPoint.none:
        return true; // Default to clockwise
    }
  }

  List<Offset> _generatePerimeterPath(
    CanvasObject? startObject,
    Offset startJut,
    ConnectionPoint startPoint,
    bool clockwise,
  ) {
    final List<Offset> perimeterPoints = [];
    final Size objDimensions = startObject?.getDimensions() ?? Size.zero;
    final Offset topLeft = startObject?.topLeft ?? .zero;
    final Offset bottomRight = startObject?.bottomRight ?? .zero;
    final double objWidth = objDimensions.width;
    final double objHeight = objDimensions.height;

    // Calculate the rectangle around start object at spacing distance
    final double leftX = topLeft.dx - spacing;
    final double rightX = bottomRight.dx + spacing;
    final double topY = topLeft.dy - spacing;
    final double bottomY = bottomRight.dy + spacing;

    // Calculate total perimeter distance for safety check
    final double perimeterLength = 2 * (objWidth + objHeight + 4 * spacing);
    final int maxPoints = (perimeterLength / spacing * 2)
        .ceil(); // Safety factor

    Offset currentPoint = startJut;
    ConnectionPoint currentSide = startPoint;

    for (int i = 0; i < maxPoints; i++) {
      perimeterPoints.add(currentPoint);

      // Move to next point based on current side and direction
      Offset nextPoint;
      ConnectionPoint nextSide = currentSide;

      if (clockwise) {
        switch (currentSide) {
          case ConnectionPoint.top:
            nextPoint = Offset(currentPoint.dx + spacing, currentPoint.dy);
            if (nextPoint.dx >= rightX) {
              // Ensure we hit the exact corner
              nextPoint = Offset(rightX, topY);
              nextSide = ConnectionPoint.right;
            }
            break;
          case ConnectionPoint.right:
            nextPoint = Offset(currentPoint.dx, currentPoint.dy + spacing);
            if (nextPoint.dy >= bottomY) {
              // Ensure we hit the exact corner
              nextPoint = Offset(rightX, bottomY);
              nextSide = ConnectionPoint.bottom;
            }
            break;
          case ConnectionPoint.bottom:
            nextPoint = Offset(currentPoint.dx - spacing, currentPoint.dy);
            if (nextPoint.dx <= leftX) {
              // Ensure we hit the exact corner
              nextPoint = Offset(leftX, bottomY);
              nextSide = ConnectionPoint.left;
            }
            break;
          case ConnectionPoint.left:
            nextPoint = Offset(currentPoint.dx, currentPoint.dy - spacing);
            if (nextPoint.dy <= topY) {
              // Ensure we hit the exact corner
              nextPoint = Offset(leftX, topY);
              nextSide = ConnectionPoint.top;
            }
            break;
          case ConnectionPoint.none:
            return perimeterPoints; // Should not happen
        }
      } else {
        // Counter-clockwise movement
        switch (currentSide) {
          case ConnectionPoint.top:
            nextPoint = Offset(currentPoint.dx - spacing, currentPoint.dy);
            if (nextPoint.dx <= leftX) {
              // Ensure we hit the exact corner
              nextPoint = Offset(leftX, topY);
              nextSide = ConnectionPoint.left;
            }
            break;
          case ConnectionPoint.left:
            nextPoint = Offset(currentPoint.dx, currentPoint.dy + spacing);
            if (nextPoint.dy >= bottomY) {
              // Ensure we hit the exact corner
              nextPoint = Offset(leftX, bottomY);
              nextSide = ConnectionPoint.bottom;
            }
            break;
          case ConnectionPoint.bottom:
            nextPoint = Offset(currentPoint.dx + spacing, currentPoint.dy);
            if (nextPoint.dx >= rightX) {
              // Ensure we hit the exact corner
              nextPoint = Offset(rightX, bottomY);
              nextSide = ConnectionPoint.right;
            }
            break;
          case ConnectionPoint.right:
            nextPoint = Offset(currentPoint.dx, currentPoint.dy - spacing);
            if (nextPoint.dy <= topY) {
              // Ensure we hit the exact corner
              nextPoint = Offset(rightX, topY);
              nextSide = ConnectionPoint.top;
            }
            break;
          case ConnectionPoint.none:
            return perimeterPoints; // Should not happen
        }
      }

      // Check if we've completed the loop (back near start)
      if (i > 4 && (nextPoint - startJut).distance < spacing) {
        break;
      }

      currentPoint = nextPoint;
      currentSide = nextSide;
    }

    return perimeterPoints;
  }

  Offset? _getVisionOffset(
    Offset start,
    Offset end,
    CanvasObject? startObject,
    CanvasObject? endObject, {
    required bool horizontal,
  }) {
    final Offset horizontalOffset = Offset(end.dx, start.dy);
    final Offset verticalOffset = Offset(start.dx, end.dy);

    final bool horizontalHasVision =
        _isObjectNotBetween(
          start: start,
          end: horizontalOffset,
          object: startObject,
        ) &&
        _isObjectNotBetween(
          start: start,
          end: horizontalOffset,
          object: endObject,
        ) &&
        _isObjectNotBetween(
          start: horizontalOffset,
          end: end,
          object: startObject,
        ) &&
        _isObjectNotBetween(
          start: horizontalOffset,
          end: end,
          object: endObject,
        );

    final bool verticalHasVision =
        _isObjectNotBetween(
          start: start,
          end: verticalOffset,
          object: startObject,
        ) &&
        _isObjectNotBetween(
          start: start,
          end: verticalOffset,
          object: endObject,
        ) &&
        _isObjectNotBetween(
          start: verticalOffset,
          end: end,
          object: startObject,
        ) &&
        _isObjectNotBetween(start: verticalOffset, end: end, object: endObject);

    if (horizontalHasVision && verticalHasVision) {
      return horizontal ? horizontalOffset : verticalOffset;
    } else if (horizontalHasVision) {
      return horizontalOffset;
    } else if (verticalHasVision) {
      return verticalOffset;
    } else {
      return null;
    }
  }

  bool _isObjectBetween({
    required Offset start,
    required Offset end,
    required CanvasObject? object,
  }) {
    final Rect objectRect = Rect.fromPoints(
      object?.topLeft ?? .zero,
      object?.bottomRight ?? .infinite,
    ).inflate(spacing / 2);

    final Rect betweenRect = Rect.fromPoints(start, end).inflate(0.1);

    return objectRect.overlaps(betweenRect);
  }

  bool _isObjectNotBetween({
    required Offset start,
    required Offset end,
    required CanvasObject? object,
  }) => !_isObjectBetween(start: start, end: end, object: object);

  bool _isMovementHorizontal(Offset start, Offset end) {
    final delta = end - start;
    return delta.dx.abs() > delta.dy.abs();
  }

  Offset _getClosestDirection(
    Offset start,
    Offset end, {
    bool? prioritizeHorizontal,
  }) {
    final delta = end - start;

    if (prioritizeHorizontal == true) {
      return delta.dx > 0 ? const Offset(1, 0) : const Offset(-1, 0);
    } else if (prioritizeHorizontal == false) {
      return delta.dy > 0 ? const Offset(0, 1) : const Offset(0, -1);
    } else {
      final absX = delta.dx.abs();
      final absY = delta.dy.abs();

      if (absX > absY) {
        return delta.dx > 0 ? const Offset(1, 0) : const Offset(-1, 0);
      } else {
        return delta.dy > 0 ? const Offset(0, 1) : const Offset(0, -1);
      }
    }
  }
}
