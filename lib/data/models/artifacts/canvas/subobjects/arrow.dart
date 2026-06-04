import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/canvas_engine/providers/providers.dart';

enum ArrowTip with OnyxiaEnum { triangle, circle, none }

enum ArrowType with OnyxiaEnum { segmented, curved }

final minSegmentLength = CanvasBounds.gridSpacing * 2;

class ArrowProperties {
  List<Offset> points;
  String? startObjectId;
  String? endObjectId;
  ArrowTip startTip;
  ArrowTip endTip;
  ConnectionPoint startPoint;
  Offset? startRelativeOffset;
  Offset? startAbsoluteOffset;
  ConnectionPoint endPoint;
  Offset? endRelativeOffset;
  // absolute position (if not connected)
  Offset? endAbsoluteOffset;
  // text area position along the arrow path (0.0 = start, 1.0 = end)
  double textPosition;
  Offset? curvedMidpoint;
  ArrowType arrowType;

  ArrowProperties({
    this.points = const <Offset>[],
    this.startObjectId,
    this.endObjectId,
    this.startTip = .none,
    this.endTip = .triangle,
    this.startPoint = ConnectionPoint.none,
    this.startRelativeOffset,
    this.startAbsoluteOffset,
    this.endPoint = ConnectionPoint.none,
    this.endRelativeOffset,
    this.endAbsoluteOffset,
    this.textPosition = 0.5,
    this.curvedMidpoint,
    this.arrowType = .segmented,
  });

  factory ArrowProperties.initial() {
    return ArrowProperties(points: [], arrowType: .segmented);
  }

  @override
  String toString() {
    return 'ArrowProperties('
        'points: $points, '
        'startObjectId: $startObjectId, '
        'endObjectId: $endObjectId, '
        'startTip: $startTip, '
        'endTip: $endTip, '
        'startConnectionPoint: $startPoint, '
        'startRelativeOffset: $endRelativeOffset, '
        'startAbsoluteOffset: $startAbsoluteOffset, '
        'endConnectionPoint: $endPoint, '
        'endRelativeOffset: $endRelativeOffset, '
        'endAbsoluteOffset: $endAbsoluteOffset, '
        'textPosition: $textPosition, '
        'curvedMidpoint: $curvedMidpoint, '
        'arrowType: $arrowType, '
        ')';
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((x) => x.toMap()).toList(),
      'start_object_id': startObjectId,
      'end_object_id': endObjectId,
      'start_tip': startTip.value,
      'end_tip': endTip.value,
      'start_connection_point': startPoint.toShortString(),
      'start_relative_offset': startRelativeOffset?.toMap(),
      'start_absolute_offset': startAbsoluteOffset?.toMap(),
      'end_connection_point': endPoint.toShortString(),
      'end_relative_offset': endRelativeOffset?.toMap(),
      'end_absolute_offset': endAbsoluteOffset?.toMap(),
      'text_position': textPosition,
      'curved_midpoint': curvedMidpoint?.toMap(),
      'arrow_type': arrowType.value,
    };
  }

  factory ArrowProperties.fromMap(Map<String, dynamic> map) {
    try {
      // Safe points parsing
      List<Offset> points = <Offset>[];
      try {
        if (map['points'] != null) {
          points = List<Offset>.from(
            map['points'].map((x) => OffsetExtension.fromMap(x)),
          );
        }
      } catch (e) {
        points = <Offset>[];
      }

      // Safe enum parsing
      ArrowTip startTip = .none;
      try {
        if (map['start_tip'] != null) {
          startTip = ArrowTip.values.fromString(map['start_tip']);
        }
      } catch (e) {
        startTip = .none;
      }

      ArrowTip endTip = .triangle;
      try {
        if (map['end_tip'] != null) {
          endTip = ArrowTip.values.fromString(map['end_tip']);
        }
      } catch (e) {
        endTip = .triangle;
      }

      ConnectionPoint startPoint = ConnectionPoint.none;
      try {
        if (map['start_connection_point'] != null) {
          startPoint = ConnectionPointTypeExtension.fromString(
            map['start_connection_point'],
          );
        }
      } catch (e) {
        startPoint = ConnectionPoint.none;
      }

      ConnectionPoint endPoint = ConnectionPoint.none;
      try {
        if (map['end_connection_point'] != null) {
          endPoint = ConnectionPointTypeExtension.fromString(
            map['end_connection_point'],
          );
        }
      } catch (e) {
        endPoint = ConnectionPoint.none;
      }

      ArrowType arrowType = .segmented;
      try {
        if (map['arrow_type'] != null) {
          arrowType = ArrowType.values.fromString(map['arrow_type']);
        }
      } catch (e) {
        arrowType = .segmented;
      }

      // Safe offset parsing
      Offset? startRelativeOffset;
      try {
        if (map['start_relative_offset'] != null) {
          startRelativeOffset = OffsetExtension.fromMap(
            map['start_relative_offset'],
          );
        }
      } catch (e) {
        startRelativeOffset = null;
      }

      Offset? startAbsoluteOffset;
      try {
        if (map['start_absolute_offset'] != null) {
          startAbsoluteOffset = OffsetExtension.fromMap(
            map['start_absolute_offset'],
          );
        }
      } catch (e) {
        startAbsoluteOffset = null;
      }

      Offset? endRelativeOffset;
      try {
        if (map['end_relative_offset'] != null) {
          endRelativeOffset = OffsetExtension.fromMap(
            map['end_relative_offset'],
          );
        }
      } catch (e) {
        endRelativeOffset = null;
      }

      Offset? endAbsoluteOffset;
      try {
        if (map['end_absolute_offset'] != null) {
          endAbsoluteOffset = OffsetExtension.fromMap(
            map['end_absolute_offset'],
          );
        }
      } catch (e) {
        endAbsoluteOffset = null;
      }

      Offset? curvedMidpoint;
      try {
        if (map['curved_midpoint'] != null) {
          curvedMidpoint = OffsetExtension.fromMap(map['curved_midpoint']);
        }
      } catch (e) {
        curvedMidpoint = null;
      }

      return ArrowProperties(
        points: points,
        startObjectId: map['start_object_id'],
        endObjectId: map['end_object_id'],
        startTip: startTip,
        endTip: endTip,
        startPoint: startPoint,
        startRelativeOffset: startRelativeOffset,
        startAbsoluteOffset: startAbsoluteOffset,
        endPoint: endPoint,
        endRelativeOffset: endRelativeOffset,
        endAbsoluteOffset: endAbsoluteOffset,
        textPosition: map['text_position']?.toDouble() ?? 0.5,
        curvedMidpoint: curvedMidpoint,
        arrowType: arrowType,
      );
    } catch (e) {
      // Return a completely default ArrowProperties if parsing fails entirely
      return ArrowProperties();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArrowProperties &&
        listEquals(other.points, points) &&
        other.startObjectId == startObjectId &&
        other.endObjectId == endObjectId &&
        other.startTip == startTip &&
        other.endTip == endTip &&
        other.startPoint == startPoint &&
        other.startRelativeOffset == startRelativeOffset &&
        other.startAbsoluteOffset == startAbsoluteOffset &&
        other.endPoint == endPoint &&
        other.endRelativeOffset == endRelativeOffset &&
        other.endAbsoluteOffset == endAbsoluteOffset &&
        other.textPosition == textPosition &&
        other.curvedMidpoint == curvedMidpoint &&
        other.arrowType == arrowType;
  }

  @override
  int get hashCode {
    return points.hashCode ^
        startObjectId.hashCode ^
        endObjectId.hashCode ^
        startTip.hashCode ^
        endTip.hashCode ^
        startPoint.hashCode ^
        startRelativeOffset.hashCode ^
        startAbsoluteOffset.hashCode ^
        endPoint.hashCode ^
        endRelativeOffset.hashCode ^
        endAbsoluteOffset.hashCode ^
        textPosition.hashCode ^
        curvedMidpoint.hashCode ^
        arrowType.hashCode;
  }
}
