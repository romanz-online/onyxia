import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/screens/canvas/providers/providers.dart';

enum ArrowTip with NarwhalEnum {
  triangle,
  circle,
  none,
}

enum ArrowType with NarwhalEnum {
  segmented,
  curved,
}

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
    this.startTip = ArrowTip.none,
    this.endTip = ArrowTip.triangle,
    this.startPoint = ConnectionPoint.none,
    this.startRelativeOffset,
    this.startAbsoluteOffset,
    this.endPoint = ConnectionPoint.none,
    this.endRelativeOffset,
    this.endAbsoluteOffset,
    this.textPosition = 0.5,
    this.curvedMidpoint,
    this.arrowType = ArrowType.segmented,
  });

  factory ArrowProperties.initial() {
    return ArrowProperties(
      points: [],
      arrowType: ArrowType.segmented,
    );
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
      'startObjectId': startObjectId,
      'endObjectId': endObjectId,
      'startTip': startTip.value,
      'endTip': endTip.value,
      'startConnectionPoint': startPoint.toShortString(),
      'startRelativeOffset': startRelativeOffset?.toMap(),
      'startAbsoluteOffset': startAbsoluteOffset?.toMap(),
      'endConnectionPoint': endPoint.toShortString(),
      'endRelativeOffset': endRelativeOffset?.toMap(),
      'endAbsoluteOffset': endAbsoluteOffset?.toMap(),
      'textPosition': textPosition,
      'curvedMidpoint': curvedMidpoint?.toMap(),
      'arrowType': arrowType.value,
    };
  }

  factory ArrowProperties.fromMap(Map<String, dynamic> map) {
    try {
      // Safe points parsing
      List<Offset> points = <Offset>[];
      try {
        if (map['points'] != null) {
          points = List<Offset>.from(map['points'].map((x) => OffsetExtension.fromMap(x)));
        }
      } catch (e) {
        points = <Offset>[];
      }

      // Safe enum parsing
      ArrowTip startTip = ArrowTip.none;
      try {
        if (map['startTip'] != null) {
          startTip = ArrowTip.values.fromString(map['startTip']);
        }
      } catch (e) {
        startTip = ArrowTip.none;
      }

      ArrowTip endTip = ArrowTip.triangle;
      try {
        if (map['endTip'] != null) {
          endTip = ArrowTip.values.fromString(map['endTip']);
        }
      } catch (e) {
        endTip = ArrowTip.triangle;
      }

      ConnectionPoint startPoint = ConnectionPoint.none;
      try {
        if (map['startConnectionPoint'] != null) {
          startPoint = ConnectionPointTypeExtension.fromString(map['startConnectionPoint']);
        }
      } catch (e) {
        startPoint = ConnectionPoint.none;
      }

      ConnectionPoint endPoint = ConnectionPoint.none;
      try {
        if (map['endConnectionPoint'] != null) {
          endPoint = ConnectionPointTypeExtension.fromString(map['endConnectionPoint']);
        }
      } catch (e) {
        endPoint = ConnectionPoint.none;
      }

      ArrowType arrowType = ArrowType.segmented;
      try {
        if (map['arrowType'] != null) {
          arrowType = ArrowType.values.fromString(map['arrowType']);
        }
      } catch (e) {
        arrowType = ArrowType.segmented;
      }

      // Safe offset parsing
      Offset? startRelativeOffset;
      try {
        if (map['startRelativeOffset'] != null) {
          startRelativeOffset = OffsetExtension.fromMap(map['startRelativeOffset']);
        }
      } catch (e) {
        startRelativeOffset = null;
      }

      Offset? startAbsoluteOffset;
      try {
        if (map['startAbsoluteOffset'] != null) {
          startAbsoluteOffset = OffsetExtension.fromMap(map['startAbsoluteOffset']);
        }
      } catch (e) {
        startAbsoluteOffset = null;
      }

      Offset? endRelativeOffset;
      try {
        if (map['endRelativeOffset'] != null) {
          endRelativeOffset = OffsetExtension.fromMap(map['endRelativeOffset']);
        }
      } catch (e) {
        endRelativeOffset = null;
      }

      Offset? endAbsoluteOffset;
      try {
        if (map['endAbsoluteOffset'] != null) {
          endAbsoluteOffset = OffsetExtension.fromMap(map['endAbsoluteOffset']);
        }
      } catch (e) {
        endAbsoluteOffset = null;
      }

      Offset? curvedMidpoint;
      try {
        if (map['curvedMidpoint'] != null) {
          curvedMidpoint = OffsetExtension.fromMap(map['curvedMidpoint']);
        }
      } catch (e) {
        curvedMidpoint = null;
      }

      return ArrowProperties(
        points: points,
        startObjectId: map['startObjectId'],
        endObjectId: map['endObjectId'],
        startTip: startTip,
        endTip: endTip,
        startPoint: startPoint,
        startRelativeOffset: startRelativeOffset,
        startAbsoluteOffset: startAbsoluteOffset,
        endPoint: endPoint,
        endRelativeOffset: endRelativeOffset,
        endAbsoluteOffset: endAbsoluteOffset,
        textPosition: map['textPosition']?.toDouble() ?? 0.5,
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
