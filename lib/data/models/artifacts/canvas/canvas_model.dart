import 'package:onyxia/export.dart';

enum CanvasType with NarwhalEnum {
  whiteboard,
  markup,
  flow,
}

class CanvasModel extends Artifact {
  final CanvasType canvasType;
  final String? imageUrl;

  CanvasModel({
    super.id,
    super.createdAt,
    super.parent,
    super.createdBy,
    super.title = 'Canvas',
    super.type = ArtifactType.canvas,
    super.updatedBy,
    super.updatedAt,
    //
    this.canvasType = CanvasType.whiteboard,
    this.imageUrl,
  });

  CanvasModel.fromMap(super.map)
      : canvasType = CanvasType.values.fromString(map['canvasType'] ?? ''),
        imageUrl = map['imageUrl'],
        super.fromMap();

  @override
  Map<String, dynamic> toMapSub() {
    return {'canvasType': canvasType.value, 'imageUrl': imageUrl};
  }

  @override
  CanvasModel copyWith({
    String? id,
    String? parentId,
    String? title,
    DateTime? createdAt,
    String? createdBy,
    ArtifactType? type,
    String? updatedBy,
    DateTime? updatedAt,
    CanvasType? canvasType,
    String? imageUrl,
  }) {
    return CanvasModel(
      id: id ?? this.id,
      parent: parentId ?? this.parent,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      type: type ?? this.type,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      //
      canvasType: canvasType ?? this.canvasType,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory CanvasModel.fromJson(String source) => CanvasModel.fromMap(json.decode(source));

  @override
  String toString() {
    return '${super.toString()}'
        'canvasType: $canvasType, '
        'imageUrl: $imageUrl, '
        '))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return super == other && other is CanvasModel && other.canvasType == canvasType && other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => super.hashCode ^ canvasType.hashCode ^ imageUrl.hashCode;
}
