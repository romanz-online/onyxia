import 'package:flutter/material.dart';
import 'package:onyxia/data/models/artifacts/canvas/canvas_object.dart';

enum ConnectionPoint { top, left, right, bottom, none }

extension ConnectionPointExtension on ConnectionPoint {
  Offset getOffset(CanvasObject object) {
    if (object.id.isEmpty) return .zero;

    switch (object.type) {
      case CanvasObjectType.rectangle:
      case CanvasObjectType.diamond:
      case CanvasObjectType.oblong:
      case CanvasObjectType.circle:
      case CanvasObjectType.cylinder:
        // These shapes use bounding box approach - gaps are at edge centers
        return getBoundingBoxOffset(object.topLeft, object.bottomRight);

      case CanvasObjectType.rhombus:
        return _getRhombusOffset(object.topLeft, object.bottomRight);

      case CanvasObjectType.trapezoid:
        return _getTrapezoidOffset(object.topLeft, object.bottomRight);

      case CanvasObjectType.house:
        return _getHouseOffset(object.topLeft, object.bottomRight);

      case CanvasObjectType.reverseHouse:
        return _getReverseHouseOffset(object.topLeft, object.bottomRight);

      default:
        // For other shapes, use default bounding box
        return getBoundingBoxOffset(object.topLeft, object.bottomRight);
    }
  }

  Offset getBoundingBoxOffset(Offset topLeft, Offset bottomRight) {
    final center = Offset(
      (topLeft.dx + bottomRight.dx) / 2,
      (topLeft.dy + bottomRight.dy) / 2,
    );

    return switch (this) {
      ConnectionPoint.top => Offset(center.dx, topLeft.dy),
      ConnectionPoint.left => Offset(topLeft.dx, center.dy),
      ConnectionPoint.right => Offset(bottomRight.dx, center.dy),
      ConnectionPoint.bottom => Offset(center.dx, bottomRight.dy),
      ConnectionPoint.none => Offset(center.dx, center.dy),
    };
  }

  Offset _getMidpoint(Offset point1, Offset point2) {
    return Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2);
  }

  Offset _getRhombusOffset(Offset topLeft, Offset bottomRight) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final offset = rect.width * 0.2; // 20% offset for slant

    // Define the four vertices of the rhombus
    final tL = Offset(rect.left + offset, rect.top);
    final tR = Offset(rect.right, rect.top);
    final bL = Offset(rect.left, rect.bottom);
    final bR = Offset(rect.right - offset, rect.bottom);

    return switch (this) {
      ConnectionPoint.top => _getMidpoint(
        topLeft,
        Offset(bottomRight.dx, topLeft.dy),
      ),
      ConnectionPoint.bottom => _getMidpoint(
        Offset(topLeft.dx, bottomRight.dy),
        bottomRight,
      ),
      ConnectionPoint.right => _getMidpoint(bR, tR),
      ConnectionPoint.left => _getMidpoint(bL, tL),
      ConnectionPoint.none => rect.center,
    };
  }

  Offset _getTrapezoidOffset(Offset topLeft, Offset bottomRight) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final topInset = rect.width * 0.2; // Top is 20% narrower

    // Calculate actual trapezoid vertices
    final tL = Offset(rect.left + topInset, rect.top);
    final tR = Offset(rect.right - topInset, rect.top);
    final bL = Offset(rect.left, rect.bottom);
    final bR = Offset(rect.right, rect.bottom);

    return switch (this) {
      ConnectionPoint.top => _getMidpoint(tL, tR),
      ConnectionPoint.right => _getMidpoint(tR, bR),
      ConnectionPoint.bottom => _getMidpoint(bL, bR),
      ConnectionPoint.left => _getMidpoint(bL, tL),
      ConnectionPoint.none => rect.center,
    };
  }

  Offset _getHouseOffset(Offset topLeft, Offset bottomRight) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final center = rect.center;
    final roofHeight = rect.height * 0.4; // Roof is 40% of total height
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top + roofHeight,
      rect.width,
      rect.height - roofHeight,
    );

    return switch (this) {
      ConnectionPoint.top => Offset(center.dx, rect.top), // Roof peak
      ConnectionPoint.right => Offset(houseRect.right, houseRect.center.dy),
      ConnectionPoint.bottom => Offset(houseRect.center.dx, houseRect.bottom),
      ConnectionPoint.left => Offset(houseRect.left, houseRect.center.dy),
      ConnectionPoint.none => center,
    };
  }

  Offset _getReverseHouseOffset(Offset topLeft, Offset bottomRight) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final center = rect.center;
    final roofHeight = rect.height * 0.4; // Roof is 40% of total height
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - roofHeight,
    );

    return switch (this) {
      ConnectionPoint.top => Offset(houseRect.center.dx, houseRect.top),
      ConnectionPoint.right => Offset(houseRect.right, houseRect.center.dy),
      ConnectionPoint.bottom => Offset(
        center.dx,
        rect.bottom,
      ), // Roof peak at bottom
      ConnectionPoint.left => Offset(houseRect.left, houseRect.center.dy),
      ConnectionPoint.none => center,
    };
  }
}

extension ConnectionPointTypeExtension on ConnectionPoint {
  String toShortString() {
    return toString().split('.').last;
  }

  static ConnectionPoint fromString(String value) {
    return ConnectionPoint.values.firstWhere((e) => e.toShortString() == value);
  }
}
