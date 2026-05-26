import 'package:onyxia/export.dart';

class Pin implements ExpandablePin {
  final GlobalKey fillAreaKey = GlobalKey();

  @override
  String id;
  String linkedArtifactId;
  String canvasId;
  @override
  Offset position;
  String? pinnedObjectId;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  Pin({
    this.id = '',
    this.linkedArtifactId = '',
    this.canvasId = '',
    this.position = .zero,
    this.pinnedObjectId,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linked_artifact_id': linkedArtifactId.isEmpty ? null : linkedArtifactId,
      'canvas_artifact_id': canvasId,
      'position': position.toMap(),
      'pinned_object_id': pinnedObjectId,
    };
  }

  Pin.fromMap(Map<String, dynamic> map)
      : id = map['id'] ?? '',
        linkedArtifactId = map['linked_artifact_id'] ?? '',
        canvasId = map['canvas_artifact_id'] ?? '',
        position = OffsetExtension.fromMap(map['position']),
        pinnedObjectId = map['pinned_object_id'] ?? '',
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  Pin copyWith({
    String? id,
    String? linkedArtifactId,
    String? canvasId,
    Offset? position,
    String? pinnedObjectId,
  }) {
    return Pin(
      id: id ?? this.id,
      linkedArtifactId: linkedArtifactId ?? this.linkedArtifactId,
      canvasId: canvasId ?? this.canvasId,
      position: position ?? this.position,
      pinnedObjectId: pinnedObjectId ?? this.pinnedObjectId,
    );
  }

  @override
  String toString() {
    return 'Pin('
        'id: $id, '
        'linkedArtifactId: $linkedArtifactId '
        'canvasId: $canvasId '
        'position: $position '
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

    return other is Pin &&
        other.id == id &&
        other.linkedArtifactId == linkedArtifactId &&
        other.canvasId == canvasId &&
        other.position == other.position &&
        //
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        linkedArtifactId.hashCode ^
        canvasId.hashCode ^
        position.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
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
