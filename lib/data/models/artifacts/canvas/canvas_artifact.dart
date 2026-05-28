import 'package:onyxia/export.dart';
import 'dart:convert';

enum CanvasType with NarwhalEnum { whiteboard, markup, flow }

class CanvasArtifact extends Artifact {
  final CanvasType canvasType;
  final String? imageUrl;

  CanvasArtifact({
    super.id,
    super.type = ArtifactType.canvas,
    super.name = 'Canvas',
    super.parentFolderId,
    //
    super.createdAt,
    super.createdBy,
    super.updatedAt,
    super.updatedBy,
    //
    this.canvasType = CanvasType.whiteboard,
    this.imageUrl,
  });

  CanvasArtifact.fromMap(super.map)
    : canvasType = CanvasType.values.fromString(
        (map['body'] as Map<String, dynamic>?)?['canvas_type'] ?? '',
      ),
      imageUrl =
          (map['body'] as Map<String, dynamic>?)?['image_url'] as String?,
      super.fromMap();

  @override
  Map<String, dynamic> toMapSub() {
    return {'canvas_type': canvasType.value, 'image_url': imageUrl};
  }

  @override
  CanvasArtifact copyWith({
    String? id,
    String? name,
    String? parentFolderId,
    CanvasType? canvasType,
    String? imageUrl,
  }) {
    return CanvasArtifact(
      id: id ?? this.id,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      name: name ?? this.name,
      //
      canvasType: canvasType ?? this.canvasType,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory CanvasArtifact.fromJson(String source) =>
      CanvasArtifact.fromMap(json.decode(source));

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

    return super == other &&
        other is CanvasArtifact &&
        other.canvasType == canvasType &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => super.hashCode ^ canvasType.hashCode ^ imageUrl.hashCode;
}
