import 'package:onyxia/export.dart';

class Pin implements ExpandablePin {
  final GlobalKey fillAreaKey = GlobalKey();

  @override
  String id;
  String artifactId;
  String canvasId;
  @override
  Offset position;
  String? pinnedObjectId;

  Pin({
    this.id = '',
    this.artifactId = '',
    this.canvasId = '',
    this.position = Offset.zero,
    this.pinnedObjectId,
  });

  factory Pin.initial() => Pin();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linked_artifact_id': artifactId.isEmpty ? null : artifactId,
      'canvas_artifact_id': canvasId,
      'position': position.toMap(),
      'target_object_id': pinnedObjectId,
    };
  }

  factory Pin.fromMap(Map<String, dynamic> map) {
    try {
      return Pin(
        id: map['id'] ?? '',
        artifactId: map['linked_artifact_id'] ?? '',
        canvasId: map['canvas_artifact_id'] ?? '',
        position: OffsetExtension.fromMap(map['position']),
        pinnedObjectId: map['target_object_id']?.toString(),
      );
    } catch (e) {
      return Pin();
    }
  }

  Pin copyWith({
    String? id,
    String? artifactId,
    String? canvasId,
    Offset? position,
    String? pinnedObjectId,
  }) {
    return Pin(
      id: id ?? this.id,
      artifactId: artifactId ?? this.artifactId,
      canvasId: canvasId ?? this.canvasId,
      position: position ?? this.position,
      pinnedObjectId: pinnedObjectId ?? this.pinnedObjectId,
    );
  }

  @override
  String toString() {
    return 'Pin('
        'id: $id, '
        'artifactId: $artifactId '
        'canvasId: $canvasId '
        'position: $position '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Pin &&
        other.id == id &&
        other.artifactId == artifactId &&
        other.canvasId == canvasId &&
        other.position == other.position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        artifactId.hashCode ^
        canvasId.hashCode ^
        position.hashCode;
  }

  @override
  Offset getOffset({CanvasObject? parent}) {
    if (parent == null) {
      return position;
    } else if (parent.isArrow) {
      // Arrow positioning: position.dx is percentage along arrow path (0.0-1.0)
      final arrowPoints = parent.arrowProps.points;
      return ArrowPathHelper.getPointAtPercentage(arrowPoints, position.dx);
    } else {
      // Regular object positioning: relative positioning based on dimensions
      final objSize = parent.getDimensions();
      return parent.topLeft +
          Offset(
            (position.dx * objSize.width),
            (position.dy * objSize.height),
          );
    }
  }
}

class Pins {
  final List<Pin> pins;
  Pins({required this.pins});

  factory Pins.initial() => Pins(pins: []);

  Pins copyWith({List<Pin>? pins}) {
    return Pins(pins: pins ?? this.pins);
  }

  @override
  String toString() => 'Pins(pins: $pins)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Pins && listEquals(other.pins, pins);
  }

  @override
  int get hashCode => pins.hashCode;
}
