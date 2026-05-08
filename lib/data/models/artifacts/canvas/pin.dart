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

  factory Pin.fromJson(String jsonStr) {
    final Map<String, dynamic> map = json.decode(jsonStr);
    return Pin.fromMap(map);
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linked_artifact_id': artifactId.isEmpty ? null : artifactId,
      'canvas_artifact_id': canvasId,
      'x': position.dx,
      'y': position.dy,
      'target_object_id': pinnedObjectId,
    };
  }

  factory Pin.fromMap(Map<String, dynamic> map) {
    try {
      final dx = (map['x'] as num?)?.toDouble() ?? 0.0;
      final dy = (map['y'] as num?)?.toDouble() ?? 0.0;
      return Pin(
        id: map['id'] ?? '',
        artifactId: map['linked_artifact_id'] ?? '',
        canvasId: map['canvas_artifact_id'] ?? '',
        position: Offset(dx, dy),
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
    return id.hashCode ^ artifactId.hashCode ^ canvasId.hashCode ^ position.hashCode;
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
