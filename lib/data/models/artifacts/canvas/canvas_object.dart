import 'package:onyxia/export.dart';
import 'dart:math' as math;
import 'package:onyxia/presentation/canvas_engine/providers/providers.dart';
import 'dart:convert';

const Size defaultArtifactObjectDimensions = Size(
  CanvasBounds.gridSpacing * 10,
  CanvasBounds.gridSpacing * 10,
);

enum ResizeHandle {
  center,
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  arrow,
  arrowHead,
  none,
}

enum CanvasObjectType with NarwhalEnum {
  // shapes
  rectangle,
  diamond,
  oblong,
  circle,
  rhombus,
  trapezoid,
  cylinder,
  house,
  reverseHouse,

  text,

  image,

  brush,

  arrow,

  artifact,
}

enum StrokeType with NarwhalEnum { dashed, solid, thick, none }

class CanvasObject {
  final GlobalKey fillAreaKey = GlobalKey();
  final GlobalKey textAreaKey = GlobalKey();
  final GlobalKey arrowTextAreaKey = GlobalKey();
  final GlobalKey firstKeypointKey = GlobalKey();
  final GlobalKey lastKeypointKey = GlobalKey();
  final GlobalKey curveMidpointKey = GlobalKey();

  String id;
  Color color;
  CanvasObjectType type;
  StrokeType stroke;
  Offset topLeft;
  Offset bottomRight;
  String content;
  ArrowProperties? _arrowProps;
  ImageProperties? _imageProps;
  BrushProperties? _brushProps;
  ArtifactProperties? _artifactProps;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  CanvasObject({
    required this.id,
    this.color = Colors.transparent,
    this.type = CanvasObjectType.rectangle,
    this.stroke = StrokeType.solid,
    this.topLeft = .zero,
    this.bottomRight = .zero,
    this.content = '',
    ArrowProperties? arrowProperties,
    ImageProperties? imageProperties,
    BrushProperties? brushProperties,
    ArtifactProperties? artifactProperties,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  }) : _arrowProps = arrowProperties,
       _imageProps = imageProperties,
       _brushProps = brushProperties,
       _artifactProps = artifactProperties {
    if (type == CanvasObjectType.arrow) {
      if (_arrowProps == null) {
        throw ArgumentError('Arrow objects require ArrowProperties');
      }
    } else if (type == CanvasObjectType.image) {
      if (_imageProps == null) {
        throw ArgumentError('Image objects require ImageProperties');
      }
    } else if (type == CanvasObjectType.brush) {
      if (_brushProps == null) {
        throw ArgumentError('Brush objects require BrushProperties');
      }
    } else if (type == CanvasObjectType.artifact) {
      if (_artifactProps == null) {
        throw ArgumentError('Artifact objects require ArtifactProperties');
      }
    }
  }

  bool get hasArrowProps => _arrowProps != null;
  ArrowProperties get arrowProps {
    if (_arrowProps == null) {
      throw StateError('This arrow object does not have ArrowProperties');
    }
    return _arrowProps!;
  }

  bool get hasImageProps => _imageProps != null;
  ImageProperties get imageProps {
    if (_imageProps == null) {
      throw StateError('This image object does not have ImageProperties');
    }
    return _imageProps!;
  }

  bool get hasBrushProps => _brushProps != null;
  BrushProperties get brushProps {
    if (_brushProps == null) {
      throw StateError('This brush object does not have BrushProperties');
    }
    return _brushProps!;
  }

  bool get hasArtifactProps => _artifactProps != null;
  ArtifactProperties get artifactProps {
    if (_artifactProps == null) {
      throw StateError('This artifact object does not have ArtifactProperties');
    }
    return _artifactProps!;
  }

  factory CanvasObject.initial() {
    return CanvasObject(
      id: '',
      color: Colors.transparent,
      type: CanvasObjectType.rectangle,
      stroke: StrokeType.solid,
      topLeft: .zero,
      bottomRight: .zero,
    );
  }

  factory CanvasObject.fromJson(String jsonStr) =>
      CanvasObject.fromMap(json.decode(jsonStr));

  String toJson() => json.encode(toMap());

  CanvasObject copyWith({
    String? id,
    Color? color,
    CanvasObjectType? type,
    StrokeType? stroke,
    Offset? topLeft,
    Offset? bottomRight,
    String? content,
    List<String>? commentIds,
    ArrowProperties? arrowProps,
    ImageProperties? imageProps,
    BrushProperties? brushProps,
    ArtifactProperties? artifactProps,
  }) {
    return CanvasObject(
      id: id ?? this.id,
      color: color ?? this.color,
      type: type ?? this.type,
      stroke: stroke ?? this.stroke,
      topLeft: topLeft ?? this.topLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      content: content ?? this.content,
      arrowProperties: arrowProps ?? _arrowProps,
      imageProperties: imageProps ?? _imageProps,
      brushProperties: brushProps ?? _brushProps,
      artifactProperties: artifactProps ?? _artifactProps,
    );
  }

  Map<String, dynamic> toMap() {
    final payload = <String, dynamic>{
      'color': color.toARGB32(),
      'stroke': stroke.value,
      'top_left': topLeft.toMap(),
      'bottom_right': bottomRight.toMap(),
      'content': content,
    };
    if (isArrow) payload['arrow_props'] = _arrowProps!.toMap();
    if (isImage) payload['image_props'] = _imageProps!.toMap();
    if (isBrush) payload['brush_props'] = _brushProps!.toMap();
    if (isArtifact) payload['artifact_props'] = _artifactProps!.toMap();

    // Top-level Postgres columns; repository injects `canvas_artifact_id`.
    return {'id': id, 'type': type.value, 'payload': payload};
  }

  Size getDimensions() => Size(
    (bottomRight.dx - topLeft.dx).abs(),
    (bottomRight.dy - topLeft.dy).abs(),
  );

  factory CanvasObject.fromMap(Map<String, dynamic> map) {
    try {
      final payload =
          (map['payload'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      CanvasObjectType type = CanvasObjectType.rectangle;
      try {
        type = CanvasObjectType.values.fromString(map['type'] ?? '');
      } catch (e) {
        type = CanvasObjectType.rectangle;
      }

      StrokeType stroke = StrokeType.solid;
      try {
        stroke = StrokeType.values.fromString(payload['stroke'] ?? '');
      } catch (e) {
        stroke = StrokeType.solid;
      }

      Color color = Colors.transparent;
      try {
        if (payload['color'] != null) {
          color = Color(payload['color']);
        }
      } catch (e) {
        color = Colors.transparent;
      }

      Offset topLeft = .zero;
      try {
        if (payload['top_left'] != null) {
          topLeft = OffsetExtension.fromMap(payload['top_left']);
        }
      } catch (e) {
        topLeft = .zero;
      }

      Offset bottomRight = .zero;
      try {
        if (payload['bottom_right'] != null) {
          bottomRight = OffsetExtension.fromMap(payload['bottom_right']);
        }
      } catch (e) {
        bottomRight = .zero;
      }

      final String content = payload['content'] is String
          ? payload['content'] as String
          : '';

      return CanvasObject(
        id: map['id'] ?? '',
        color: color,
        type: type,
        stroke: stroke,
        topLeft: topLeft,
        bottomRight: bottomRight,
        content: content,
        arrowProperties:
            type == CanvasObjectType.arrow && payload['arrow_props'] != null
            ? ArrowProperties.fromMap(payload['arrow_props'])
            : null,
        imageProperties:
            type == CanvasObjectType.image && payload['image_props'] != null
            ? ImageProperties.fromMap(payload['image_props'])
            : null,
        brushProperties:
            type == CanvasObjectType.brush && payload['brush_props'] != null
            ? BrushProperties.fromMap(payload['brush_props'])
            : null,
        artifactProperties:
            type == CanvasObjectType.artifact &&
                payload['artifact_props'] != null
            ? ArtifactProperties.fromMap(payload['artifact_props'])
            : null,
        //
        createdAt: TimestampService.fromMap(map['created_at']),
        createdBy: map['created_by'] ?? '',
        updatedAt: TimestampService.fromMap(map['updated_at']),
        updatedBy: map['updated_by'] ?? '',
      );
    } catch (e) {
      return CanvasObject.initial();
    }
  }

  @override
  String toString() {
    return 'CanvasObject('
        'id: $id, '
        'color: $color, '
        'type: $type, '
        'stroke: $stroke, '
        'topLeft: $topLeft, '
        'bottomRight: $bottomRight, '
        'content: $content, '
        'arrowProps: $_arrowProps, '
        'imageProps: $_imageProps, '
        'brushProps: $_brushProps, '
        'artifactProps: $_artifactProps, '
        //
        'createdAt: $createdAt, '
        'createdBy: $createdBy, '
        'updatedAt: $updatedAt, '
        'updatedBy: $updatedBy, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasObject && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        color.hashCode ^
        type.hashCode ^
        stroke.hashCode ^
        topLeft.hashCode ^
        bottomRight.hashCode ^
        content.hashCode ^
        _arrowProps.hashCode ^
        _imageProps.hashCode ^
        _brushProps.hashCode ^
        _artifactProps.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }

  bool get isContentEmpty => content.trim().isEmpty;

  bool isPointInObject(Offset point, {double? margin}) {
    margin ??= CanvasBounds.gridSpacing;

    // Use a larger margin for drag-drop operations
    final double effectiveMargin = margin * 1.5;

    // Calculate object center for all object types
    // final center = Offset(
    //   (topLeft.dx + bottomRight.dx) / 2,
    //   (topLeft.dy + bottomRight.dy) / 2,
    // );

    switch (type) {
      // case ObjectType.line:
      // case ObjectType.dashedLine:
      // case ObjectType.dotDashLine:
      case CanvasObjectType.rectangle:
      case CanvasObjectType.diamond:
      case CanvasObjectType.oblong:
      case CanvasObjectType.circle:
      case CanvasObjectType.rhombus:
      case CanvasObjectType.trapezoid:
      case CanvasObjectType.cylinder:
      case CanvasObjectType.house:
      case CanvasObjectType.reverseHouse:
      case CanvasObjectType.image:
      case CanvasObjectType.text:
      case CanvasObjectType.artifact:
        final double minX = math.min(topLeft.dx, bottomRight.dx);
        final double maxX = math.max(topLeft.dx, bottomRight.dx);
        final double minY = math.min(topLeft.dy, bottomRight.dy);
        final double maxY = math.max(topLeft.dy, bottomRight.dy);

        // Check if point is within rectangle bounds (with margin)
        final bool isInObject =
            point.dx >= minX - effectiveMargin &&
            point.dx <= maxX + effectiveMargin &&
            point.dy >= minY - effectiveMargin &&
            point.dy <= maxY + effectiveMargin;

        return isInObject;

      // case ObjectType.circle:
      //   final radius = (bottomRight - topLeft).distance / 2;
      //   final distance = (point - center).distance;

      //   // Check if point is within circle (with margin)
      //   final bool isInObject = distance <= (radius + effectiveMargin);

      //   return isInObject;

      case CanvasObjectType.brush:
        if (!isBrush) return false;

        // Check if point is near any brush point
        for (final p in brushProps.points) {
          final distance = (p - point).distance;
          if (distance < effectiveMargin) {
            return true;
          }
        }

        return false;

      case CanvasObjectType.arrow:
        if (!isArrow || arrowProps.points.isEmpty) return false;

        if (arrowProps.arrowType == ArrowType.curved) {
          final minX =
              math.min(arrowProps.points[0].dx, arrowProps.points.last.dx) -
              margin;
          final maxX =
              math.max(arrowProps.points[0].dx, arrowProps.points.last.dx) +
              margin;
          final minY =
              math.min(arrowProps.points[0].dy, arrowProps.points.last.dy) -
              margin;
          final maxY =
              math.max(arrowProps.points[0].dy, arrowProps.points.last.dy) +
              margin;

          if (point.dx < minX ||
              point.dx > maxX ||
              point.dy < minY ||
              point.dy > maxY) {
            return false;
          }

          // Sample the curve at regular intervals and find the closest point
          const int samples = 100; // Adjust for precision vs performance
          double minDistance = double.infinity;

          for (int i = 0; i <= samples; i++) {
            final t = i / samples;
            final curvePoint = curveOffset(t);
            final distance = (point - curvePoint).distance;

            if (distance < minDistance) {
              minDistance = distance;
            }

            // Early exit if we're already within margin
            if (minDistance <= margin) {
              return true;
            }
          }

          return minDistance <= margin;
        } else {
          // Check if point is near any arrow segment
          for (int i = 0; i < arrowProps.points.length - 1; i++) {
            final p1 = arrowProps.points[i];
            final p2 = arrowProps.points[i + 1];
            final l2 = (p1 - p2).distanceSquared;

            // Handle zero-length segments
            if (l2 == 0 && (point - p1).distance < effectiveMargin) {
              return true;
            }

            if (l2 > 0) {
              // Calculate projection of point onto line segment
              final t = math.max(
                0,
                math.min(1, (point - p1).dot(p2 - p1) / l2),
              );
              final double tValue = t.toDouble();
              final proj = p1 + (p2 - p1) * tValue;
              final distance = (point - proj).distance;

              if (distance < effectiveMargin) {
                return true;
              }
            }
          }
        }

        return false;
    }
  }

  /// Returns the nearest ConnectionPoint and the nearest Offset position
  /// on the corresponding edge.
  (ConnectionPoint, Offset) findNearestBoundOffset(Offset position) {
    if (isArrow || isBrush) return (ConnectionPoint.none, .zero);

    switch (type) {
      case CanvasObjectType.rectangle:
      case CanvasObjectType.text:
      case CanvasObjectType.image:
      case CanvasObjectType.artifact:
        return _findNearestBoundingBoxOffset(position);

      case CanvasObjectType.diamond:
        return _findNearestDiamondOffset(position);

      case CanvasObjectType.circle:
        return _findNearestCircleOffset(position);

      case CanvasObjectType.oblong:
        return _findNearestOblongOffset(position);

      case CanvasObjectType.rhombus:
        return _findNearestRhombusOffset(position);

      case CanvasObjectType.trapezoid:
        return _findNearestTrapezoidOffset(position);

      case CanvasObjectType.house:
        return _findNearestHouseOffset(position);

      case CanvasObjectType.reverseHouse:
        return _findNearestReverseHouseOffset(position);

      case CanvasObjectType.cylinder:
        return _findNearestCylinderOffset(position);

      default:
        return _findNearestBoundingBoxOffset(position);
    }
  }

  /// Default bounding box approach for simple shapes
  (ConnectionPoint, Offset) _findNearestBoundingBoxOffset(Offset position) {
    // Calculate distances to each edge
    final distanceToTop = (position.dy - topLeft.dy).abs();
    final distanceToBottom = (bottomRight.dy - position.dy).abs();
    final distanceToLeft = (position.dx - topLeft.dx).abs();
    final distanceToRight = (bottomRight.dx - position.dx).abs();

    // Find the minimum distance and corresponding edge
    final minDistance = [
      distanceToTop,
      distanceToBottom,
      distanceToLeft,
      distanceToRight,
    ].reduce((a, b) => a < b ? a : b);

    ConnectionPoint nearestEdge;
    Offset boundaryPoint;

    if (minDistance == distanceToTop) {
      nearestEdge = ConnectionPoint.top;
      final clampedX = position.dx.clamp(topLeft.dx, bottomRight.dx);
      boundaryPoint = Offset(clampedX, topLeft.dy);
    } else if (minDistance == distanceToBottom) {
      nearestEdge = ConnectionPoint.bottom;
      final clampedX = position.dx.clamp(topLeft.dx, bottomRight.dx);
      boundaryPoint = Offset(clampedX, bottomRight.dy);
    } else if (minDistance == distanceToLeft) {
      nearestEdge = ConnectionPoint.left;
      final clampedY = position.dy.clamp(topLeft.dy, bottomRight.dy);
      boundaryPoint = Offset(topLeft.dx, clampedY);
    } else {
      nearestEdge = ConnectionPoint.right;
      final clampedY = position.dy.clamp(topLeft.dy, bottomRight.dy);
      boundaryPoint = Offset(bottomRight.dx, clampedY);
    }

    return (nearestEdge, boundaryPoint);
  }

  /// Diamond shape boundary calculation
  (ConnectionPoint, Offset) _findNearestDiamondOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final center = rect.center;

    // Diamond vertices
    final top = Offset(center.dx, rect.top);
    final right = Offset(rect.right, center.dy);
    final bottom = Offset(center.dx, rect.bottom);
    final left = Offset(rect.left, center.dy);

    // Calculate distances to each diamond edge
    final distToTopRight = _distanceToLineSegment(position, top, right);
    final distToRightBottom = _distanceToLineSegment(position, right, bottom);
    final distToBottomLeft = _distanceToLineSegment(position, bottom, left);
    final distToLeftTop = _distanceToLineSegment(position, left, top);

    final distances = [
      distToTopRight,
      distToRightBottom,
      distToBottomLeft,
      distToLeftTop,
    ];
    final minDistance = distances.reduce((a, b) => a < b ? a : b);

    if (minDistance == distToTopRight) {
      return (
        ConnectionPoint.top,
        _projectOntoLineSegment(position, top, right),
      );
    } else if (minDistance == distToRightBottom) {
      return (
        ConnectionPoint.right,
        _projectOntoLineSegment(position, right, bottom),
      );
    } else if (minDistance == distToBottomLeft) {
      return (
        ConnectionPoint.bottom,
        _projectOntoLineSegment(position, bottom, left),
      );
    } else {
      return (
        ConnectionPoint.left,
        _projectOntoLineSegment(position, left, top),
      );
    }
  }

  /// Circle/oval boundary calculation
  (ConnectionPoint, Offset) _findNearestCircleOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final center = rect.center;
    final radiusX = rect.width / 2;
    final radiusY = rect.height / 2;

    // Convert to normalized coordinates
    final dx = (position.dx - center.dx) / radiusX;
    final dy = (position.dy - center.dy) / radiusY;

    // Normalize to unit circle
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return (ConnectionPoint.none, center);

    final normalizedX = dx / length;
    final normalizedY = dy / length;

    // Project back to ellipse
    final boundaryX = center.dx + normalizedX * radiusX;
    final boundaryY = center.dy + normalizedY * radiusY;

    // Determine which edge is closest
    final angle = math.atan2(normalizedY, normalizedX);
    final ConnectionPoint edge;

    if (angle >= -math.pi / 4 && angle < math.pi / 4) {
      edge = ConnectionPoint.right;
    } else if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) {
      edge = ConnectionPoint.bottom;
    } else if (angle >= 3 * math.pi / 4 || angle < -3 * math.pi / 4) {
      edge = ConnectionPoint.left;
    } else {
      edge = ConnectionPoint.top;
    }

    return (edge, Offset(boundaryX, boundaryY));
  }

  /// Oblong/rounded rectangle boundary calculation
  (ConnectionPoint, Offset) _findNearestOblongOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);

    // If the oblong is close to being spherical, treat it as a circle
    if ((rect.width - rect.height).abs() <= CanvasBounds.gridSpacing) {
      return _findNearestCircleOffset(position);
    }

    final center = rect.center;

    if (rect.width <= rect.height) {
      // Tall oblong - top and bottom edges are semicircles, left and right are straight
      final effectiveRadius = rect.width / 2;
      final topSemicircleBottom = rect.top + effectiveRadius;
      final bottomSemicircleTop = rect.bottom - effectiveRadius;

      // Determine which region the position is in
      if (position.dy >= topSemicircleBottom &&
          position.dy <= bottomSemicircleTop) {
        // Position is in the straight edge region (between the two semicircles)
        if (position.dx < center.dx) {
          return (ConnectionPoint.left, Offset(rect.left, position.dy));
        } else {
          return (ConnectionPoint.right, Offset(rect.right, position.dy));
        }
      } else if (position.dy < topSemicircleBottom) {
        // Position is in top semicircle region - split quarter-circles between top and side edges
        final projectedPoint = _projectOntoSemicircle(
          position,
          Offset(center.dx, rect.top + effectiveRadius),
          effectiveRadius,
          true,
        );

        // Determine which edge this quarter-circle belongs to based on angle
        final dx = projectedPoint.dx - center.dx;
        final dy = projectedPoint.dy - (rect.top + effectiveRadius);
        final angle = math.atan2(dy, dx);

        // Split at 45-degree angles: top-left quarter goes to top edge if closer to top
        if (angle <= -3 * math.pi / 4 || angle >= 3 * math.pi / 4) {
          // Left side of semicircle - belongs to left edge
          return (ConnectionPoint.left, projectedPoint);
        } else if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
          // Right side of semicircle - belongs to right edge
          return (ConnectionPoint.right, projectedPoint);
        } else {
          // Top part of semicircle - belongs to top edge
          return (ConnectionPoint.top, projectedPoint);
        }
      } else {
        // Position is in bottom semicircle region - split quarter-circles between bottom and side edges
        final projectedPoint = _projectOntoSemicircle(
          position,
          Offset(center.dx, rect.bottom - effectiveRadius),
          effectiveRadius,
          false,
        );

        // Determine which edge this quarter-circle belongs to based on angle
        final dx = projectedPoint.dx - center.dx;
        final dy = projectedPoint.dy - (rect.bottom - effectiveRadius);
        final angle = math.atan2(dy, dx);

        // Split at 45-degree angles
        if (angle <= -3 * math.pi / 4 || angle >= 3 * math.pi / 4) {
          // Left side of semicircle - belongs to left edge
          return (ConnectionPoint.left, projectedPoint);
        } else if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
          // Right side of semicircle - belongs to right edge
          return (ConnectionPoint.right, projectedPoint);
        } else {
          // Bottom part of semicircle - belongs to bottom edge
          return (ConnectionPoint.bottom, projectedPoint);
        }
      }
    } else {
      // Wide oblong - left and right edges are semicircles, top and bottom are straight
      final effectiveRadius = rect.height / 2;
      final leftSemicircleRight = rect.left + effectiveRadius;
      final rightSemicircleLeft = rect.right - effectiveRadius;

      // Determine which region the position is in
      if (position.dx >= leftSemicircleRight &&
          position.dx <= rightSemicircleLeft) {
        // Position is in the straight edge region (between the two semicircles)
        if (position.dy < center.dy) {
          return (ConnectionPoint.top, Offset(position.dx, rect.top));
        } else {
          return (ConnectionPoint.bottom, Offset(position.dx, rect.bottom));
        }
      } else if (position.dx < leftSemicircleRight) {
        // Position is in left semicircle region - split quarter-circles between left and top/bottom edges
        final projectedPoint = _projectOntoSemicircle(
          position,
          Offset(rect.left + effectiveRadius, center.dy),
          effectiveRadius,
          true,
          isVertical: true,
        );

        // Determine which edge this quarter-circle belongs to based on angle
        final dx = projectedPoint.dx - (rect.left + effectiveRadius);
        final dy = projectedPoint.dy - center.dy;
        final angle = math.atan2(dy, dx);

        // Split at 45-degree angles
        if (angle <= -math.pi / 4 && angle >= -3 * math.pi / 4) {
          // Top side of semicircle - belongs to top edge
          return (ConnectionPoint.top, projectedPoint);
        } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
          // Bottom side of semicircle - belongs to bottom edge
          return (ConnectionPoint.bottom, projectedPoint);
        } else {
          // Left part of semicircle - belongs to left edge
          return (ConnectionPoint.left, projectedPoint);
        }
      } else {
        // Position is in right semicircle region - split quarter-circles between right and top/bottom edges
        final projectedPoint = _projectOntoSemicircle(
          position,
          Offset(rect.right - effectiveRadius, center.dy),
          effectiveRadius,
          false,
          isVertical: true,
        );

        // Determine which edge this quarter-circle belongs to based on angle
        final dx = projectedPoint.dx - (rect.right - effectiveRadius);
        final dy = projectedPoint.dy - center.dy;
        final angle = math.atan2(dy, dx);

        // Split at 45-degree angles
        if (angle <= -math.pi / 4 && angle >= -3 * math.pi / 4) {
          // Top side of semicircle - belongs to top edge
          return (ConnectionPoint.top, projectedPoint);
        } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
          // Bottom side of semicircle - belongs to bottom edge
          return (ConnectionPoint.bottom, projectedPoint);
        } else {
          // Right part of semicircle - belongs to right edge
          return (ConnectionPoint.right, projectedPoint);
        }
      }
    }
  }

  /// Rhombus boundary calculation
  (ConnectionPoint, Offset) _findNearestRhombusOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final offset = rect.width * 0.2;

    // Rhombus vertices (parallelogram with slant)
    final topL = Offset(rect.left + offset, rect.top);
    final topR = Offset(rect.right, rect.top);
    final bottomL = Offset(rect.left, rect.bottom);
    final bottomR = Offset(rect.right - offset, rect.bottom);

    // Calculate distances to each rhombus edge
    final distToTop = _distanceToLineSegment(position, topL, topR);
    final distToRight = _distanceToLineSegment(position, topR, bottomR);
    final distToBottom = _distanceToLineSegment(position, bottomR, bottomL);
    final distToLeft = _distanceToLineSegment(position, bottomL, topL);

    final distances = [distToTop, distToRight, distToBottom, distToLeft];
    final minDistance = distances.reduce((a, b) => a < b ? a : b);

    if (minDistance == distToTop) {
      return (
        ConnectionPoint.top,
        _projectOntoLineSegment(position, topL, topR),
      );
    } else if (minDistance == distToRight) {
      return (
        ConnectionPoint.right,
        _projectOntoLineSegment(position, topR, bottomR),
      );
    } else if (minDistance == distToBottom) {
      return (
        ConnectionPoint.bottom,
        _projectOntoLineSegment(position, bottomR, bottomL),
      );
    } else {
      return (
        ConnectionPoint.left,
        _projectOntoLineSegment(position, bottomL, topL),
      );
    }
  }

  /// Trapezoid boundary calculation
  (ConnectionPoint, Offset) _findNearestTrapezoidOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final topInset = rect.width * 0.2;

    // Trapezoid vertices
    final topL = Offset(rect.left + topInset, rect.top);
    final topR = Offset(rect.right - topInset, rect.top);
    final bottomL = Offset(rect.left, rect.bottom);
    final bottomR = Offset(rect.right, rect.bottom);

    // Calculate distances to each trapezoid edge
    final distToTop = _distanceToLineSegment(position, topL, topR);
    final distToRight = _distanceToLineSegment(position, topR, bottomR);
    final distToBottom = _distanceToLineSegment(position, bottomR, bottomL);
    final distToLeft = _distanceToLineSegment(position, bottomL, topL);

    final distances = [distToTop, distToRight, distToBottom, distToLeft];
    final minDistance = distances.reduce((a, b) => a < b ? a : b);

    if (minDistance == distToTop) {
      return (
        ConnectionPoint.top,
        _projectOntoLineSegment(position, topL, topR),
      );
    } else if (minDistance == distToRight) {
      return (
        ConnectionPoint.right,
        _projectOntoLineSegment(position, topR, bottomR),
      );
    } else if (minDistance == distToBottom) {
      return (
        ConnectionPoint.bottom,
        _projectOntoLineSegment(position, bottomR, bottomL),
      );
    } else {
      return (
        ConnectionPoint.left,
        _projectOntoLineSegment(position, bottomL, topL),
      );
    }
  }

  /// House boundary calculation
  (ConnectionPoint, Offset) _findNearestHouseOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final roofHeight = rect.height * 0.4;
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top + roofHeight,
      rect.width,
      rect.height - roofHeight,
    );

    // House vertices
    final roofPeak = Offset(rect.center.dx, rect.top);
    final roofBottomLeft = Offset(rect.left, rect.top + roofHeight);
    final roofBottomRight = Offset(rect.right, rect.top + roofHeight);
    final houseBottomLeft = Offset(houseRect.left, houseRect.bottom);
    final houseBottomRight = Offset(houseRect.right, houseRect.bottom);

    // Calculate distances to each edge
    final distToLeftRoof = _distanceToLineSegment(
      position,
      roofBottomLeft,
      roofPeak,
    );
    final distToRightRoof = _distanceToLineSegment(
      position,
      roofPeak,
      roofBottomRight,
    );
    final distToLeftWall = _distanceToLineSegment(
      position,
      roofBottomLeft,
      houseBottomLeft,
    );
    final distToRightWall = _distanceToLineSegment(
      position,
      roofBottomRight,
      houseBottomRight,
    );
    final distToBottom = _distanceToLineSegment(
      position,
      houseBottomLeft,
      houseBottomRight,
    );

    final distances = [
      distToLeftRoof,
      distToRightRoof,
      distToLeftWall,
      distToRightWall,
      distToBottom,
    ];
    final minDistance = distances.reduce((a, b) => a < b ? a : b);

    // Check if position is near the roof peak (within radius for better UX)
    final peakRadius = math.min(rect.width, rect.height) * 0.15;
    final distanceToPeak = (position - roofPeak).distance;

    if (minDistance == distToLeftRoof) {
      final projectedPoint = _projectOntoLineSegment(
        position,
        roofBottomLeft,
        roofPeak,
      );
      // If close to peak, snap to peak; otherwise use projected point on diagonal
      if (distanceToPeak <= peakRadius) {
        return (ConnectionPoint.top, roofPeak);
      } else {
        return (ConnectionPoint.left, projectedPoint);
      }
    } else if (minDistance == distToRightRoof) {
      final projectedPoint = _projectOntoLineSegment(
        position,
        roofPeak,
        roofBottomRight,
      );
      // If close to peak, snap to peak; otherwise use projected point on diagonal
      if (distanceToPeak <= peakRadius) {
        return (ConnectionPoint.top, roofPeak);
      } else {
        return (ConnectionPoint.right, projectedPoint);
      }
    } else if (minDistance == distToLeftWall) {
      return (
        ConnectionPoint.left,
        _projectOntoLineSegment(position, roofBottomLeft, houseBottomLeft),
      );
    } else if (minDistance == distToRightWall) {
      return (
        ConnectionPoint.right,
        _projectOntoLineSegment(position, roofBottomRight, houseBottomRight),
      );
    } else {
      return (
        ConnectionPoint.bottom,
        _projectOntoLineSegment(position, houseBottomLeft, houseBottomRight),
      );
    }
  }

  /// Reverse house boundary calculation
  (ConnectionPoint, Offset) _findNearestReverseHouseOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final roofHeight = rect.height * 0.4;
    final houseRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - roofHeight,
    );

    // Reverse house vertices
    final houseTopLeft = Offset(houseRect.left, houseRect.top);
    final houseTopRight = Offset(houseRect.right, houseRect.top);
    final roofTopLeft = Offset(rect.left, rect.bottom - roofHeight);
    final roofTopRight = Offset(rect.right, rect.bottom - roofHeight);
    final roofPeak = Offset(rect.center.dx, rect.bottom);

    // Calculate distances to each edge
    final distToTop = _distanceToLineSegment(
      position,
      houseTopLeft,
      houseTopRight,
    );
    final distToLeftWall = _distanceToLineSegment(
      position,
      houseTopLeft,
      roofTopLeft,
    );
    final distToRightWall = _distanceToLineSegment(
      position,
      houseTopRight,
      roofTopRight,
    );
    final distToLeftRoof = _distanceToLineSegment(
      position,
      roofTopLeft,
      roofPeak,
    );
    final distToRightRoof = _distanceToLineSegment(
      position,
      roofPeak,
      roofTopRight,
    );

    final distances = [
      distToTop,
      distToLeftWall,
      distToRightWall,
      distToLeftRoof,
      distToRightRoof,
    ];
    final minDistance = distances.reduce((a, b) => a < b ? a : b);

    // Check if position is near the roof peak (within radius for better UX)
    final peakRadius = math.min(rect.width, rect.height) * 0.15;
    final distanceToPeak = (position - roofPeak).distance;

    if (minDistance == distToTop) {
      return (
        ConnectionPoint.top,
        _projectOntoLineSegment(position, houseTopLeft, houseTopRight),
      );
    } else if (minDistance == distToLeftWall) {
      return (
        ConnectionPoint.left,
        _projectOntoLineSegment(position, houseTopLeft, roofTopLeft),
      );
    } else if (minDistance == distToRightWall) {
      return (
        ConnectionPoint.right,
        _projectOntoLineSegment(position, houseTopRight, roofTopRight),
      );
    } else if (minDistance == distToLeftRoof) {
      final projectedPoint = _projectOntoLineSegment(
        position,
        roofTopLeft,
        roofPeak,
      );
      // If close to peak, snap to peak; otherwise use projected point on diagonal
      if (distanceToPeak <= peakRadius) {
        return (ConnectionPoint.bottom, roofPeak);
      } else {
        return (ConnectionPoint.left, projectedPoint);
      }
    } else {
      final projectedPoint = _projectOntoLineSegment(
        position,
        roofPeak,
        roofTopRight,
      );
      // If close to peak, snap to peak; otherwise use projected point on diagonal
      if (distanceToPeak <= peakRadius) {
        return (ConnectionPoint.bottom, roofPeak);
      } else {
        return (ConnectionPoint.right, projectedPoint);
      }
    }
  }

  /// Cylinder boundary calculation
  (ConnectionPoint, Offset) _findNearestCylinderOffset(Offset position) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final radiusX = rect.width / 2;
    final radiusY = rect.height * 0.2; // Oval height is 20% of total height

    // Top oval center
    final topCenter = Offset(rect.center.dx, rect.top + radiusY);
    // Bottom oval center
    final bottomCenter = Offset(rect.center.dx, rect.bottom - radiusY);

    // Calculate distances to different parts
    final distToLeftEdge = (position.dx - rect.left).abs();
    final distToRightEdge = (rect.right - position.dx).abs();

    // Check if position is in top oval area
    if (position.dy < topCenter.dy) {
      final dx = (position.dx - topCenter.dx) / radiusX;
      final dy = (position.dy - topCenter.dy) / radiusY;
      final length = math.sqrt(dx * dx + dy * dy);

      if (length == 0) return (ConnectionPoint.top, topCenter);

      final normalizedX = dx / length;
      final normalizedY = dy / length;
      final boundaryX = topCenter.dx + normalizedX * radiusX;
      final boundaryY = topCenter.dy + normalizedY * radiusY;

      return (ConnectionPoint.top, Offset(boundaryX, boundaryY));
    }
    // Check if position is in bottom oval area
    else if (position.dy > bottomCenter.dy) {
      final dx = (position.dx - bottomCenter.dx) / radiusX;
      final dy = (position.dy - bottomCenter.dy) / radiusY;
      final length = math.sqrt(dx * dx + dy * dy);

      if (length == 0) return (ConnectionPoint.bottom, bottomCenter);

      final normalizedX = dx / length;
      final normalizedY = dy / length;
      final boundaryX = bottomCenter.dx + normalizedX * radiusX;
      final boundaryY = bottomCenter.dy + normalizedY * radiusY;

      return (ConnectionPoint.bottom, Offset(boundaryX, boundaryY));
    }
    // Position is in body area
    else {
      if (distToLeftEdge < distToRightEdge) {
        return (ConnectionPoint.left, Offset(rect.left, position.dy));
      } else {
        return (ConnectionPoint.right, Offset(rect.right, position.dy));
      }
    }
  }

  /// Helper method to calculate distance from point to line segment
  double _distanceToLineSegment(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final lineLength = (lineEnd - lineStart).distanceSquared;
    if (lineLength == 0) return (point - lineStart).distance;

    final t = math.max(
      0,
      math.min(1, (point - lineStart).dot(lineEnd - lineStart) / lineLength),
    );
    final projection = lineStart + (lineEnd - lineStart) * t.toDouble();
    return (point - projection).distance;
  }

  /// Helper method to project point onto line segment
  Offset _projectOntoLineSegment(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final lineLength = (lineEnd - lineStart).distanceSquared;
    if (lineLength == 0) return lineStart;

    final t = math.max(
      0,
      math.min(1, (point - lineStart).dot(lineEnd - lineStart) / lineLength),
    );
    return lineStart + (lineEnd - lineStart) * t.toDouble();
  }

  /// Helper method to project point onto semicircle
  Offset _projectOntoSemicircle(
    Offset point,
    Offset semicircleCenter,
    double radius,
    bool isTop, {
    bool isVertical = false,
  }) {
    final dx = point.dx - semicircleCenter.dx;
    final dy = point.dy - semicircleCenter.dy;
    final distanceFromCenter = math.sqrt(dx * dx + dy * dy);

    if (distanceFromCenter == 0) return semicircleCenter + Offset(radius, 0);

    final normalizedX = dx / distanceFromCenter;
    final normalizedY = dy / distanceFromCenter;

    if (isVertical) {
      // For vertical semicircles, constrain to appropriate half
      if (isTop) {
        // Left semicircle - constrain to left half
        final constrainedX = normalizedX <= 0 ? normalizedX : 0;
        final length = math.sqrt(
          constrainedX * constrainedX + normalizedY * normalizedY,
        );
        if (length == 0) return semicircleCenter + Offset(-radius, 0);
        return semicircleCenter +
            Offset(
              (constrainedX / length) * radius,
              (normalizedY / length) * radius,
            );
      } else {
        // Right semicircle - constrain to right half
        final constrainedX = normalizedX >= 0 ? normalizedX : 0;
        final length = math.sqrt(
          constrainedX * constrainedX + normalizedY * normalizedY,
        );
        if (length == 0) return semicircleCenter + Offset(radius, 0);
        return semicircleCenter +
            Offset(
              (constrainedX / length) * radius,
              (normalizedY / length) * radius,
            );
      }
    } else {
      // For horizontal semicircles, constrain to appropriate half
      if (isTop) {
        // Top semicircle - constrain to top half
        final constrainedY = normalizedY <= 0 ? normalizedY : 0;
        final length = math.sqrt(
          normalizedX * normalizedX + constrainedY * constrainedY,
        );
        if (length == 0) return semicircleCenter + Offset(0, -radius);
        return semicircleCenter +
            Offset(
              (normalizedX / length) * radius,
              (constrainedY / length) * radius,
            );
      } else {
        // Bottom semicircle - constrain to bottom half
        final constrainedY = normalizedY >= 0 ? normalizedY : 0;
        final length = math.sqrt(
          normalizedX * normalizedX + constrainedY * constrainedY,
        );
        if (length == 0) return semicircleCenter + Offset(0, radius);
        return semicircleCenter +
            Offset(
              (normalizedX / length) * radius,
              (constrainedY / length) * radius,
            );
      }
    }
  }

  /// Returns true if a new arrow segment was created, false otherwise.
  /// Return value means nothing for non-arrow objects.
  bool handleResize(
    WidgetRef ref,
    Offset delta,
    ResizeHandle handle, {
    int arrowKeypointIndex = 0,
  }) {
    if (isArrow) {
      // Returns true if a new segment was created, false otherwise
      if (arrowProps.points.isEmpty) return false;

      final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);

      final oldLength = arrowProps.points.length;
      List<Offset> newKeypoints = List.from(arrowProps.points);

      bool isFirstSegment = arrowKeypointIndex == 0;
      bool isLastSegment = arrowKeypointIndex == newKeypoints.length - 2;
      bool isHorizontal =
          newKeypoints[arrowKeypointIndex].dy -
              newKeypoints[arrowKeypointIndex + 1].dy ==
          0;

      // only allows orthogonal movement depending on segment orientation
      Offset appliedDelta = isHorizontal
          ? Offset(0, delta.dy)
          : Offset(delta.dx, 0);

      if (newKeypoints.length == 2) {
        // straight line (one segment)
        final midpoint1 = _getOffsetBetween(
          newKeypoints[0],
          newKeypoints[1],
          minSegmentLength,
        );
        final midpoint2 = _getOffsetBetween(
          newKeypoints[1],
          newKeypoints[0],
          minSegmentLength,
        );
        newKeypoints.insert(1, midpoint2);
        newKeypoints.insert(1, midpoint2);
        newKeypoints.insert(1, midpoint1);
        newKeypoints.insert(1, midpoint1);

        // Apply delta and clamp to canvas bounds
        newKeypoints[2] = canvasBoundsNotifier.clamp(
          newKeypoints[2] + appliedDelta,
        );
        newKeypoints[3] = canvasBoundsNotifier.clamp(
          newKeypoints[3] + appliedDelta,
        );
      } else if (isFirstSegment || isLastSegment) {
        double segmentLength =
            (newKeypoints[arrowKeypointIndex + 1] -
                    newKeypoints[arrowKeypointIndex])
                .distance;

        // Only allow creating new segments if the current one is longer than minimum
        if (segmentLength > minSegmentLength) {
          if (isFirstSegment) {
            final newKeypoint = _getOffsetBetween(
              newKeypoints[0],
              newKeypoints[1],
              minSegmentLength,
            );

            newKeypoints.insert(1, newKeypoint);
            newKeypoints.insert(1, newKeypoint);

            // Apply delta and clamp to canvas bounds
            newKeypoints[2] = canvasBoundsNotifier.clamp(
              newKeypoints[2] + appliedDelta,
            );
            newKeypoints[3] = canvasBoundsNotifier.clamp(
              newKeypoints[3] + appliedDelta,
            );
          } else if (isLastSegment) {
            final newKeypoint = _getOffsetBetween(
              newKeypoints[newKeypoints.length - 1],
              newKeypoints[newKeypoints.length - 2],
              minSegmentLength,
            );

            newKeypoints.insert(newKeypoints.length - 1, newKeypoint);
            newKeypoints.insert(newKeypoints.length - 1, newKeypoint);

            // Apply delta and clamp to canvas bounds
            newKeypoints[newKeypoints.length - 3] = canvasBoundsNotifier.clamp(
              newKeypoints[newKeypoints.length - 3] + appliedDelta,
            );
            newKeypoints[newKeypoints.length - 4] = canvasBoundsNotifier.clamp(
              newKeypoints[newKeypoints.length - 4] + appliedDelta,
            );
          }
        }
      } else {
        // Apply delta and clamp to canvas bounds
        newKeypoints[arrowKeypointIndex] = canvasBoundsNotifier.clamp(
          newKeypoints[arrowKeypointIndex] + appliedDelta,
        );
        newKeypoints[arrowKeypointIndex + 1] = canvasBoundsNotifier.clamp(
          newKeypoints[arrowKeypointIndex + 1] + appliedDelta,
        );
      }

      // Ensure all keypoints are within canvas bounds
      for (int i = 0; i < newKeypoints.length; i++) {
        newKeypoints[i] = canvasBoundsNotifier.clamp(newKeypoints[i]);
      }

      arrowProps.points = newKeypoints;

      return oldLength < arrowProps.points.length;
    } else {
      final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
      final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);

      Offset newTopLeft = topLeft;
      Offset newBottomRight = bottomRight;

      if (type == CanvasObjectType.image) {
        // maintain aspect ratio
        final currentWidth = bottomRight.dx - topLeft.dx;
        final currentHeight = bottomRight.dy - topLeft.dy;
        final aspectRatio = currentWidth / currentHeight;
        final d = delta.dx.abs() > delta.dy.abs() ? delta.dx : delta.dy;
        final widthChange = d / aspectRatio;
        final heightChange = d * aspectRatio;

        switch (handle) {
          case ResizeHandle.topCenter:
            newTopLeft += Offset(delta.dy * aspectRatio, delta.dy);
            break;
          case ResizeHandle.centerLeft:
            newTopLeft += Offset(delta.dx, delta.dx / aspectRatio);
            break;
          case ResizeHandle.centerRight:
            newBottomRight += Offset(delta.dx, delta.dx / aspectRatio);
            break;
          case ResizeHandle.bottomCenter:
            newBottomRight += Offset(delta.dy * aspectRatio, delta.dy);
            break;
          case ResizeHandle.topLeft:
            if (delta.dx.abs() > delta.dy.abs()) {
              newTopLeft += Offset(d, widthChange);
            } else {
              newTopLeft += Offset(heightChange, d);
            }
            break;
          case ResizeHandle.bottomRight:
            if (delta.dx.abs() > delta.dy.abs()) {
              newBottomRight += Offset(d, widthChange);
            } else {
              newBottomRight += Offset(heightChange, d);
            }
            break;
          case ResizeHandle.bottomLeft:
            if (delta.dx.abs() > delta.dy.abs()) {
              newTopLeft += Offset(d, 0);
              newBottomRight += Offset(0, -d / aspectRatio);
            } else {
              newTopLeft += Offset(-d * aspectRatio, 0);
              newBottomRight += Offset(0, d);
            }
            break;
          case ResizeHandle.topRight:
            if (delta.dx.abs() > delta.dy.abs()) {
              newTopLeft += Offset(0, -d / aspectRatio);
              newBottomRight += Offset(d, 0);
            } else {
              newTopLeft += Offset(0, d);
              newBottomRight += Offset(-d * aspectRatio, 0);
            }
            break;
          case ResizeHandle.arrow:
          case ResizeHandle.arrowHead:
          case ResizeHandle.center:
          case ResizeHandle.none:
            break;
        }
      } else {
        // For non-image objects, use the original logic
        switch (handle) {
          case ResizeHandle.topLeft:
            newTopLeft += delta;
            break;
          case ResizeHandle.topCenter:
            newTopLeft += Offset(0, delta.dy);
            break;
          case ResizeHandle.topRight:
            newTopLeft += Offset(0, delta.dy);
            newBottomRight += Offset(delta.dx, 0);
            break;
          case ResizeHandle.centerLeft:
            newTopLeft += Offset(delta.dx, 0);
            break;
          case ResizeHandle.centerRight:
            newBottomRight += Offset(delta.dx, 0);
            break;
          case ResizeHandle.bottomLeft:
            newTopLeft += Offset(delta.dx, 0);
            newBottomRight += Offset(0, delta.dy);
            break;
          case ResizeHandle.bottomCenter:
            newBottomRight += Offset(0, delta.dy);
            break;
          case ResizeHandle.bottomRight:
            newBottomRight += delta;
            break;
          case ResizeHandle.arrow:
          case ResizeHandle.arrowHead:
          case ResizeHandle.center:
          case ResizeHandle.none:
            break;
        }
      }

      newTopLeft = canvasBoundsNotifier.clamp(newTopLeft);
      newBottomRight = canvasBoundsNotifier.clamp(newBottomRight);

      if (topLeft != newTopLeft &&
          snapToGrid &&
          type != CanvasObjectType.image) {
        newTopLeft = canvasBoundsNotifier.snap(newTopLeft);
      }

      if (bottomRight != newBottomRight &&
          snapToGrid &&
          type != CanvasObjectType.image) {
        newBottomRight = canvasBoundsNotifier.snap(newBottomRight);
      }

      // Prevent flipping coordinates
      if (newTopLeft.dx > newBottomRight.dx) {
        final temp = newTopLeft.dx;
        newTopLeft = Offset(newBottomRight.dx, newTopLeft.dy);
        newBottomRight = Offset(temp, newBottomRight.dy);
      }

      if (newTopLeft.dy > newBottomRight.dy) {
        final temp = newTopLeft.dy;
        newTopLeft = Offset(newTopLeft.dx, newBottomRight.dy);
        newBottomRight = Offset(newBottomRight.dx, temp);
      }

      if ((newTopLeft.dx - newBottomRight.dx).abs() <
          CanvasBounds.gridSpacing) {
        newTopLeft = Offset(topLeft.dx, newTopLeft.dy);
        newBottomRight = Offset(bottomRight.dx, newBottomRight.dy);
      }

      if ((newTopLeft.dy - newBottomRight.dy).abs() <
          CanvasBounds.gridSpacing) {
        newTopLeft = Offset(newTopLeft.dx, topLeft.dy);
        newBottomRight = Offset(newBottomRight.dx, bottomRight.dy);
      }

      topLeft = newTopLeft;
      bottomRight = newBottomRight;
    }

    return false;
  }

  bool canMove(WidgetRef ref, Offset delta) {
    final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
    final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);
    if (isArrow) {
      for (final p in arrowProps.points) {
        Offset newPosition = p + delta;
        if (snapToGrid) {
          newPosition = canvasBoundsNotifier.snap(newPosition);
        }

        if (canvasBoundsNotifier.clamp(newPosition) != newPosition) {
          return false;
        }
      }
      return true;
    } else {
      Offset newTopLeft = snapToGrid
          ? canvasBoundsNotifier.snap(topLeft + delta)
          : topLeft + delta;
      Offset newBottomRight = bottomRight + delta;

      return canvasBoundsNotifier.clamp(newTopLeft) == newTopLeft &&
          canvasBoundsNotifier.clamp(newBottomRight) == newBottomRight;
    }
  }

  /// Returns which directions the object can move given a delta
  /// Returns a map with canMoveUp, canMoveDown, canMoveLeft, canMoveRight
  Map<String, bool> getMovementConstraints(WidgetRef ref, Offset delta) {
    final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
    final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);
    final bounds = canvasBoundsNotifier.bounds;

    Offset newTopLeft = snapToGrid
        ? canvasBoundsNotifier.snap(topLeft + delta)
        : topLeft + delta;
    Offset newBottomRight = bottomRight + delta;

    return {
      'canMoveUp': delta.dy < 0 ? newTopLeft.dy >= bounds.top : true,
      'canMoveDown': delta.dy > 0 ? newBottomRight.dy <= bounds.bottom : true,
      'canMoveLeft': delta.dx < 0 ? newTopLeft.dx >= bounds.left : true,
      'canMoveRight': delta.dx > 0 ? newBottomRight.dx <= bounds.right : true,
    };
  }

  bool handleMove(WidgetRef ref, Offset delta) {
    final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
    final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);

    if (!canMove(ref, delta)) return false;

    if (isArrow) {
      arrowProps.points = arrowProps.points
          .map(
            (p) =>
                snapToGrid ? canvasBoundsNotifier.snap(p + delta) : p + delta,
          )
          .toList();
      return true;
    } else if (isBrush) {
      brushProps.points = brushProps.points.map((p) => p + delta).toList();
      _updateBoundingRect();
      return true;
    } else {
      topLeft = snapToGrid
          ? canvasBoundsNotifier.snap(topLeft + delta)
          : topLeft + delta;
      bottomRight = bottomRight + delta;
    }
    return true;
  }

  void _updateBoundingRect() {
    if (isBrush) {
      final boundingRect = Rect.fromPoints(
        brushProps.points.reduce(
          (a, b) =>
              Offset(a.dx < b.dx ? a.dx : b.dx, a.dy < b.dy ? a.dy : b.dy),
        ),
        brushProps.points.reduce(
          (a, b) =>
              Offset(a.dx > b.dx ? a.dx : b.dx, a.dy > b.dy ? a.dy : b.dy),
        ),
      );

      topLeft = boundingRect.topLeft;
      bottomRight = boundingRect.bottomRight;
    } else if (isArrow && arrowProps.points.isNotEmpty) {
      final boundingRect = Rect.fromPoints(
        arrowProps.points.reduce(
          (a, b) =>
              Offset(a.dx < b.dx ? a.dx : b.dx, a.dy < b.dy ? a.dy : b.dy),
        ),
        arrowProps.points.reduce(
          (a, b) =>
              Offset(a.dx > b.dx ? a.dx : b.dx, a.dy > b.dy ? a.dy : b.dy),
        ),
      );

      topLeft = boundingRect.topLeft;
      bottomRight = boundingRect.bottomRight;
    }
  }

  /// Returns the largest rectangle that can fit inside the object's shape.
  /// This excludes curved or angled areas that extend beyond a simple rectangle.
  Rect findInnerRect() {
    final rect = Rect.fromPoints(topLeft, bottomRight);

    switch (type) {
      case CanvasObjectType.rectangle:
      case CanvasObjectType.text:
      case CanvasObjectType.image:
      case CanvasObjectType.artifact:
        // For rectangles, the inner rect is the same as the bounding rect
        return rect;

      case CanvasObjectType.diamond:
        // For diamond, calculate the inscribed rectangle properly
        // Diamond vertices are at (centerX, top), (right, centerY), (centerX, bottom), (left, centerY)
        // The largest inscribed rectangle has corners that touch the diamond edges
        final center = rect.center;

        // For a diamond, the inscribed rectangle width and height are:
        // width = diamond_width / 2, height = diamond_height / 2
        // This ensures the rectangle corners touch the diamond edges at their midpoints
        final innerWidth = rect.width / 2;
        final innerHeight = rect.height / 2;

        return Rect.fromCenter(
          center: center,
          width: innerWidth,
          height: innerHeight,
        );

      case CanvasObjectType.circle:
        // For circle/oval, the inner rect is the largest rectangle that fits inside
        // For a circle, this is a square with side = diameter/sqrt(2)
        // For an oval, we need to scale based on the aspect ratio
        final center = rect.center;
        final innerWidth = rect.width / math.sqrt(2);
        final innerHeight = rect.height / math.sqrt(2);
        return Rect.fromCenter(
          center: center,
          width: innerWidth,
          height: innerHeight,
        );

      case CanvasObjectType.oblong:
        // For oblong (rounded rectangle), the inner rect has corners at the center of each quarter-circle
        final center = rect.center;

        // If the oblong is close to being spherical, treat it as a circle
        if ((rect.width - rect.height).abs() <= CanvasBounds.gridSpacing) {
          // For a perfect circle, inner rect is a square with corners at quarter-circle centers
          final radius = math.min(rect.width, rect.height) / 2;
          final innerSize =
              radius *
              math.sqrt(2); // Distance from center to quarter-circle center
          return Rect.fromCenter(
            center: center,
            width: innerSize,
            height: innerSize,
          );
        }

        if (rect.width <= rect.height) {
          // Tall oblong - semicircles on top and bottom
          final effectiveRadius = rect.width / 2;

          // Quarter-circle centers are at 45-degree angles from semicircle centers
          // Distance from semicircle center to quarter-circle center is radius * sqrt(2) / 2
          final quarterCircleOffset = effectiveRadius * math.sqrt(2) / 2;

          // Inner rect corners are at the quarter-circle centers
          final innerLeft = center.dx - quarterCircleOffset;
          final innerRight = center.dx + quarterCircleOffset;
          final innerTop = rect.top + effectiveRadius - quarterCircleOffset;
          final innerBottom =
              rect.bottom - effectiveRadius + quarterCircleOffset;

          return Rect.fromLTRB(innerLeft, innerTop, innerRight, innerBottom);
        } else {
          // Wide oblong - semicircles on left and right
          final effectiveRadius = rect.height / 2;

          // Quarter-circle centers are at 45-degree angles from semicircle centers
          final quarterCircleOffset = effectiveRadius * math.sqrt(2) / 2;

          // Inner rect corners are at the quarter-circle centers
          final innerLeft = rect.left + effectiveRadius - quarterCircleOffset;
          final innerRight = rect.right - effectiveRadius + quarterCircleOffset;
          final innerTop = center.dy - quarterCircleOffset;
          final innerBottom = center.dy + quarterCircleOffset;

          return Rect.fromLTRB(innerLeft, innerTop, innerRight, innerBottom);
        }

      case CanvasObjectType.rhombus:
        // For rhombus (parallelogram), the inner rect excludes the slanted triangular areas
        final offset = rect.width * 0.2; // Same offset as used in drawing
        final innerLeft = rect.left + offset;
        final innerRight = rect.right - offset;

        return Rect.fromLTRB(innerLeft, rect.top, innerRight, rect.bottom);

      case CanvasObjectType.trapezoid:
        // For trapezoid, the inner rect is bounded by the narrower top edge
        final topInset = rect.width * 0.2; // Same inset as used in drawing
        final innerLeft = rect.left + topInset;
        final innerRight = rect.right - topInset;

        return Rect.fromLTRB(innerLeft, rect.top, innerRight, rect.bottom);

      case CanvasObjectType.house:
        // For house, the inner rect is the main body excluding the roof
        final roofHeight = rect.height * 0.4; // Same ratio as used in drawing
        return Rect.fromLTRB(
          rect.left,
          rect.top + roofHeight,
          rect.right,
          rect.bottom,
        );

      case CanvasObjectType.reverseHouse:
        // For reverse house, the inner rect is the main body excluding the bottom roof
        final roofHeight = rect.height * 0.4; // Same ratio as used in drawing
        return Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom - roofHeight,
        );

      case CanvasObjectType.cylinder:
        // For cylinder, the inner rect is the main body excluding the curved top and bottom
        final radiusY = rect.height * 0.2; // Same ratio as used in drawing
        return Rect.fromLTRB(
          rect.left,
          rect.top + radiusY,
          rect.right,
          rect.bottom - radiusY,
        );

      case CanvasObjectType.brush:
        // For brush, return the bounding rect of the brush strokes
        if (!isBrush || brushProps.points.isEmpty) return rect;

        final points = brushProps.points;
        double minX = points[0].dx;
        double maxX = points[0].dx;
        double minY = points[0].dy;
        double maxY = points[0].dy;

        for (final point in points) {
          minX = math.min(minX, point.dx);
          maxX = math.max(maxX, point.dx);
          minY = math.min(minY, point.dy);
          maxY = math.max(maxY, point.dy);
        }

        return Rect.fromLTRB(minX, minY, maxX, maxY);

      case CanvasObjectType.arrow:
        // For arrows, return the bounding rect of the arrow path
        if (!isArrow || arrowProps.points.isEmpty) return rect;

        final points = arrowProps.points;
        double minX = points[0].dx;
        double maxX = points[0].dx;
        double minY = points[0].dy;
        double maxY = points[0].dy;

        for (final point in points) {
          minX = math.min(minX, point.dx);
          maxX = math.max(maxX, point.dx);
          minY = math.min(minY, point.dy);
          maxY = math.max(maxY, point.dy);
        }

        return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }
}

extension GenericCanvasObjectExtension on CanvasObject {
  bool get isGeneric =>
      type != CanvasObjectType.arrow &&
      type != CanvasObjectType.image &&
      type != CanvasObjectType.brush;
}

extension ArrowCanvasObjectExtension on CanvasObject {
  bool get isArrow => type == CanvasObjectType.arrow;
  ArrowProperties get arrow => arrowProps;

  CanvasObject? getStartObject(WidgetRef ref) => ref
      .read(canvasObjectsProvider)
      .objects
      .firstWhereOrNull((e) => e.id == arrowProps.startObjectId);

  CanvasObject? getEndObject(WidgetRef ref) => ref
      .read(canvasObjectsProvider)
      .objects
      .firstWhereOrNull((e) => e.id == arrowProps.endObjectId);

  Offset getStartOffset(WidgetRef ref, {CanvasObject? startObject}) {
    final startObj = startObject ?? getStartObject(ref);
    return (startObj == null || arrowProps.startPoint == ConnectionPoint.none)
        ? arrowProps.startAbsoluteOffset!
        : arrowProps.startPoint.getOffset(startObj) +
              (arrowProps.startRelativeOffset ?? .zero);
  }

  Offset getEndOffset(WidgetRef ref, {CanvasObject? endObject}) {
    final endObj = endObject ?? getEndObject(ref);
    return (endObj == null || arrowProps.endPoint == ConnectionPoint.none)
        ? arrowProps.endAbsoluteOffset!
        : arrowProps.endPoint.getOffset(endObj) +
              (arrowProps.endRelativeOffset ?? .zero);
  }

  /// Updates the arrow's topLeft and bottomRight values based on its points
  void updateArrowBounds() {
    if (!isArrow) return;
    _updateBoundingRect();
  }

  /// Creates a list of automatically-generated keypoints based on the arrow's
  /// start and end points. These are only used when dragging the arrowhead.
  /// The user can modify the arrow afterwards using resize handles but NOT
  /// using this method because this creates new keypoints from scratch.
  void drawNewKeypoints(
    WidgetRef ref, {
    CanvasObject? startObject,
    CanvasObject? endObject,
    bool reverse = false,
  }) {
    final startObj = startObject ?? getStartObject(ref);
    final endObj = endObject ?? getEndObject(ref);
    final start = getStartOffset(ref, startObject: startObj);
    final end = getEndOffset(ref, endObject: endObject);

    if ((startObj != null && startObj.isPointInObject(end)) ||
        (endObj != null && endObj.isPointInObject(start)) ||
        (startObj == null && endObj == null)) {
      arrowProps.points = [];
      arrowProps.curvedMidpoint = curveOffset(0.0);
      return;
    }

    arrowProps.points = Pathfinder.findPath(
      reverse ? end : start,
      reverse ? start : end,
      reverse ? endObj : startObj,
      reverse ? startObj : endObj,
      reverse ? arrowProps.endPoint : arrowProps.startPoint,
      reverse ? arrowProps.startPoint : arrowProps.endPoint,
    ).map((p) => ref.read(canvasBoundsProvider.notifier).clamp(p)).toList();

    if (reverse) {
      arrowProps.points = arrowProps.points.reversed.toList();
    }

    arrowProps.curvedMidpoint = arrowProps.points.isEmpty
        ? curveOffset(0.0)
        : curveOffset(0.5);

    _updateBoundingRect();
  }

  void handleMoveEndPoint(
    WidgetRef ref,
    CanvasObject startObj,
    CanvasObject endObj,
    Offset position,
  ) {
    final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
    final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);
    if (endObj.id == arrowProps.startObjectId ||
        startObj.isPointInObject(position)) {
      arrowProps.endObjectId = null;
      arrowProps.endPoint = ConnectionPoint.none;
      arrowProps.endAbsoluteOffset = snapToGrid
          ? canvasBoundsNotifier.snap(position)
          : position;
    } else {
      final nearestPoint = endObj.findNearestBoundOffset(position);

      arrowProps.endObjectId = endObj.id;
      arrowProps.endPoint = nearestPoint.$1;
      arrowProps.endAbsoluteOffset = nearestPoint.$2;

      final connectionPointOffset = arrowProps.endPoint.getOffset(endObj);
      arrowProps.endRelativeOffset =
          arrowProps.endAbsoluteOffset! - connectionPointOffset;

      if (arrowProps.endRelativeOffset!.distance <=
          CanvasBounds.gridSpacing * 2) {
        arrowProps.endRelativeOffset = .zero;
      }
    }

    drawNewKeypoints(ref, reverse: false);
  }

  void handleMoveStartPoint(
    WidgetRef ref,
    CanvasObject startObj,
    CanvasObject endObj,
    Offset position,
  ) {
    final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
    final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);
    if (startObj.id == arrowProps.endObjectId ||
        endObj.isPointInObject(position)) {
      arrowProps.startObjectId = null;
      arrowProps.startPoint = ConnectionPoint.none;
      arrowProps.startAbsoluteOffset = snapToGrid
          ? canvasBoundsNotifier.snap(position)
          : position;
    } else {
      final nearestPoint = startObj.findNearestBoundOffset(position);

      arrowProps.startObjectId = startObj.id;
      arrowProps.startPoint = nearestPoint.$1;
      arrowProps.startAbsoluteOffset = nearestPoint.$2;

      final connectionPointOffset = arrowProps.startPoint.getOffset(startObj);
      arrowProps.startRelativeOffset =
          arrowProps.startAbsoluteOffset! - connectionPointOffset;

      if (arrowProps.startRelativeOffset!.distance <=
          CanvasBounds.gridSpacing * 2) {
        arrowProps.startRelativeOffset = .zero;
      }
    }

    drawNewKeypoints(ref, reverse: true);
  }

  /// Update textPosition based on a cursor position by finding the closest point on the path
  void updateTextPosition(Offset cursorPosition) {
    if (arrowProps.points.isEmpty) {
      arrowProps.textPosition = 0.5;
      return;
    }

    double closestDistance = double.infinity;
    double bestPosition = 0.5;
    double accumulatedLength = 0.0;
    double totalLength = 0.0;

    // First pass: calculate total length
    for (int i = 0; i < arrowProps.points.length - 1; i++) {
      totalLength += (arrowProps.points[i + 1] - arrowProps.points[i]).distance;
    }

    if (totalLength == 0) {
      arrowProps.textPosition = 0.5;
      return;
    }

    // Second pass: find closest point
    accumulatedLength = 0.0;
    for (int i = 0; i < arrowProps.points.length - 1; i++) {
      final segmentStart = arrowProps.points[i];
      final segmentEnd = arrowProps.points[i + 1];
      final segmentLength = (segmentEnd - segmentStart).distance;

      if (segmentLength > 0) {
        // Find closest point on this segment
        final segmentVector = segmentEnd - segmentStart;
        final cursorVector = cursorPosition - segmentStart;
        final t =
            (cursorVector.dx * segmentVector.dx +
                cursorVector.dy * segmentVector.dy) /
            (segmentVector.dx * segmentVector.dx +
                segmentVector.dy * segmentVector.dy);
        final tClamped = t.clamp(0.0, 1.0);

        final pointOnSegment = segmentStart + segmentVector * tClamped;
        final distance = (cursorPosition - pointOnSegment).distance;

        if (distance < closestDistance) {
          closestDistance = distance;
          bestPosition =
              (accumulatedLength + segmentLength * tClamped) / totalLength;
        }
      }

      accumulatedLength += segmentLength;
    }

    arrowProps.textPosition = bestPosition.clamp(0.0, 1.0);
  }

  Offset _getOffsetBetween(Offset a, Offset b, double x) {
    final direction = b - a;
    final distance = direction.distance;
    if (distance == 0) return a;
    final unitDirection = direction / distance;
    return a + unitDirection * x;
  }

  void adjustPointsToObject(CanvasObject anchor) {
    if (arrowProps.points.isEmpty) return;

    final originalKeypoints = List<Offset>.from(arrowProps.points);
    List<Offset> updatedKeypoints = List.from(arrowProps.points);

    // straight line (one segment)
    if (updatedKeypoints.length == 2) {
      final midpoint = Offset(
        (updatedKeypoints[0].dx + updatedKeypoints[1].dx) / 2,
        (updatedKeypoints[0].dy + updatedKeypoints[1].dy) / 2,
      );
      updatedKeypoints.insert(1, midpoint);
      updatedKeypoints.insert(1, midpoint);
    } else if (updatedKeypoints.length == 3) {
      final midpoint = Offset(
        (updatedKeypoints[1].dx + updatedKeypoints[2].dx) / 2,
        (updatedKeypoints[1].dy + updatedKeypoints[2].dy) / 2,
      );
      updatedKeypoints.insert(2, midpoint);
      updatedKeypoints.insert(2, midpoint);
    }

    if (arrowProps.startObjectId == anchor.id) {
      // moving object is the start object
      updatedKeypoints[0] =
          arrowProps.startPoint.getOffset(anchor) +
          (arrowProps.startRelativeOffset ?? .zero);
      bool isHorizontal =
          arrowProps.startPoint == ConnectionPoint.left ||
          arrowProps.startPoint == ConnectionPoint.right;

      if (originalKeypoints.length >= 3) {
        // Detect if the original first segment direction conflicts with the connection point direction.
        // e.g. connected to left/right but arrow initially goes up/down, or top/bottom but goes left/right.
        final origP0 = originalKeypoints[0];
        final origP1 = originalKeypoints[1];
        final dx = (origP1.dx - origP0.dx).abs();
        final dy = (origP1.dy - origP0.dy).abs();
        final conflict =
            (isHorizontal && dy > dx) || (!isHorizontal && dx > dy);

        if (conflict) {
          // Insert a turn keypoint at the connection point to create a proper elbow,
          // preserving the original first-segment direction instead of warping it.
          final turnPoint = isHorizontal
              ? Offset(origP1.dx, updatedKeypoints[0].dy)
              : Offset(updatedKeypoints[0].dx, origP1.dy);
          updatedKeypoints.insert(1, turnPoint);
        } else {
          updatedKeypoints[1] = Offset(
            isHorizontal ? updatedKeypoints[1].dx : updatedKeypoints[0].dx,
            isHorizontal ? updatedKeypoints[0].dy : updatedKeypoints[1].dy,
          );
        }
      } else {
        updatedKeypoints[1] = Offset(
          isHorizontal ? updatedKeypoints[1].dx : updatedKeypoints[0].dx,
          isHorizontal ? updatedKeypoints[0].dy : updatedKeypoints[1].dy,
        );
      }
    } else if (arrowProps.endObjectId == anchor.id) {
      // moving object is the end object
      updatedKeypoints[updatedKeypoints.length - 1] =
          arrowProps.endPoint.getOffset(anchor) +
          (arrowProps.endRelativeOffset ?? .zero);
      bool isHorizontal =
          arrowProps.endPoint == ConnectionPoint.left ||
          arrowProps.endPoint == ConnectionPoint.right;

      if (originalKeypoints.length >= 3) {
        // Detect if the original last segment direction conflicts with the connection point direction.
        final n = originalKeypoints.length;
        final origPrev = originalKeypoints[n - 2];
        final origLast = originalKeypoints[n - 1];
        final dx = (origLast.dx - origPrev.dx).abs();
        final dy = (origLast.dy - origPrev.dy).abs();
        final conflict =
            (isHorizontal && dy > dx) || (!isHorizontal && dx > dy);

        if (conflict) {
          final lastIdx = updatedKeypoints.length - 1;
          final turnPoint = isHorizontal
              ? Offset(origPrev.dx, updatedKeypoints[lastIdx].dy)
              : Offset(updatedKeypoints[lastIdx].dx, origPrev.dy);
          updatedKeypoints.insert(lastIdx, turnPoint);
        } else {
          updatedKeypoints[updatedKeypoints.length - 2] = Offset(
            isHorizontal
                ? updatedKeypoints[updatedKeypoints.length - 2].dx
                : updatedKeypoints[updatedKeypoints.length - 1].dx,
            isHorizontal
                ? updatedKeypoints[updatedKeypoints.length - 1].dy
                : updatedKeypoints[updatedKeypoints.length - 2].dy,
          );
        }
      } else {
        updatedKeypoints[updatedKeypoints.length - 2] = Offset(
          isHorizontal
              ? updatedKeypoints[updatedKeypoints.length - 2].dx
              : updatedKeypoints[updatedKeypoints.length - 1].dx,
          isHorizontal
              ? updatedKeypoints[updatedKeypoints.length - 1].dy
              : updatedKeypoints[updatedKeypoints.length - 2].dy,
        );
      }
    }

    arrowProps.points = updatedKeypoints;
  }

  /// Consolidates arrow keypoints. If two or more keypoints run the same
  /// direction and they have no offset from each other, they they will be
  /// turned into one keypoint.
  void pruneKeypoints() {
    if (arrowProps.points.length < 3) return;

    List<Offset> newKeypoints = [arrowProps.points[0]];

    for (int i = 1; i < arrowProps.points.length - 1; i++) {
      Offset prev = arrowProps.points[i - 1];
      Offset current = arrowProps.points[i];
      Offset next = arrowProps.points[i + 1];

      bool bothHorizontal = (prev.dy == current.dy) && (current.dy == next.dy);
      bool bothVertical = (prev.dx == current.dx) && (current.dx == next.dx);

      if (!bothHorizontal && !bothVertical) {
        newKeypoints.add(current);
      }
    }

    newKeypoints.add(arrowProps.points.last);

    arrowProps.points = newKeypoints;
  }

  /// Calculate the position along the arrow path based on textPosition (0.0 to 1.0)
  Offset getTextOffset() {
    if (arrowProps.points.isEmpty) return .zero;

    if (arrowProps.arrowType == ArrowType.curved) {
      return curveOffset(arrowProps.textPosition);
    }

    // Calculate total path length
    double totalLength = 0.0;
    final List<double> segmentLengths = [];

    for (int i = 0; i < arrowProps.points.length - 1; i++) {
      final segmentLength =
          (arrowProps.points[i + 1] - arrowProps.points[i]).distance;
      segmentLengths.add(segmentLength);
      totalLength += segmentLength;
    }

    if (totalLength == 0) {
      return arrowProps.points[0];
    }

    // Find target distance along path
    final targetDistance =
        totalLength * arrowProps.textPosition.clamp(0.0, 1.0);

    // Find which segment contains the target distance
    double accumulatedDistance = 0.0;
    for (int i = 0; i < segmentLengths.length; i++) {
      final segmentLength = segmentLengths[i];

      if (accumulatedDistance + segmentLength >= targetDistance) {
        // Target is in this segment
        final remainingDistance = targetDistance - accumulatedDistance;
        final t = segmentLength > 0 ? remainingDistance / segmentLength : 0.0;

        return .lerp(arrowProps.points[i], arrowProps.points[i + 1], t) ??
            arrowProps.points[i];
      }

      accumulatedDistance += segmentLength;
    }

    // Fallback to last point
    return arrowProps.points.last;
  }

  Offset curveOffset(double t) {
    if (arrowProps.points.isEmpty) return .zero;

    final direction = arrowProps.points.last - arrowProps.points[0];
    final distance = direction.distance;

    // Control point offset based on distance
    final controlPointOffset = distance * 0.2; // Adjusted for gentler curve

    // Determine if we should flip the connection direction based on end position
    bool shouldFlip = false;
    switch (arrowProps.startPoint) {
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
    ConnectionPoint effectiveStartPoint = arrowProps.startPoint;
    if (shouldFlip) {
      effectiveStartPoint = switch (arrowProps.startPoint) {
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
    switch (arrowProps.endPoint) {
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
      arrowProps.points.last.dx - (arrowHeadLength / 2) * finalDirection.dx,
      arrowProps.points.last.dy - (arrowHeadLength / 2) * finalDirection.dy,
    );

    // First control point extends from start in the initial direction
    final controlPoint1 = Offset(
      arrowProps.points[0].dx + controlPointOffset * initialDirection.dx,
      arrowProps.points[0].dy + controlPointOffset * initialDirection.dy,
    );

    // Second control point approaches the SHORTENED end from the final direction
    final controlPoint2 = Offset(
      shortenedEnd.dx - controlPointOffset * finalDirection.dx,
      shortenedEnd.dy - controlPointOffset * finalDirection.dy,
    );

    final u = 1 - t;
    return Offset(
      u * u * u * arrowProps.points[0].dx +
          3 * u * u * t * controlPoint1.dx +
          3 * u * t * t * controlPoint2.dx +
          t * t * t * shortenedEnd.dx,
      u * u * u * arrowProps.points[0].dy +
          3 * u * u * t * controlPoint1.dy +
          3 * u * t * t * controlPoint2.dy +
          t * t * t * shortenedEnd.dy,
    );
  }
}

extension ImageCanvasObjectExtension on CanvasObject {
  bool get isImage => type == CanvasObjectType.image;
  ImageProperties get obj => imageProps;
}

extension BrushCanvasObjectExtension on CanvasObject {
  bool get isBrush => type == CanvasObjectType.brush;
  BrushProperties get obj => brushProps;

  void draw(Offset point) {
    brushProps.points.add(point);
    _updateBoundingRect();
  }
}

extension ArtifactCanvasObjectExtension on CanvasObject {
  bool get isArtifact => type == CanvasObjectType.artifact;
  ArtifactProperties get obj => artifactProps;
}

class CanvasObjects {
  final List<CanvasObject> objects;
  final List<CanvasObject> selectedObjects;

  CanvasObjects({required this.objects, required this.selectedObjects});

  factory CanvasObjects.initial() {
    return CanvasObjects(objects: [], selectedObjects: []);
  }

  CanvasObjects copyWith({
    List<CanvasObject>? objects,
    List<CanvasObject>? selectedObjects,
  }) {
    return CanvasObjects(
      objects: objects ?? this.objects,
      selectedObjects: selectedObjects ?? this.selectedObjects,
    );
  }

  @override
  String toString() =>
      'Objects(objects: $objects, selectedObjects: $selectedObjects)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasObjects &&
        listEquals(other.objects, objects) &&
        listEquals(other.selectedObjects, selectedObjects);
  }

  @override
  int get hashCode => objects.hashCode ^ selectedObjects.hashCode;
}
