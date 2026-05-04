import 'package:onyxia/export.dart';

class FolderModel extends Artifact {
  FolderModel({
    super.id,
    super.createdAt,
    super.parent,
    super.createdBy,
    super.title = 'Folder',
    super.type = ArtifactType.folder,
    super.updatedBy,
    super.updatedAt,
    //
  });

  FolderModel.fromMap(super.map) : super.fromMap();

  @override
  Map<String, dynamic> toMapSub() => {};

  @override
  FolderModel copyWith({
    String? id,
    String? parentId,
    String? title,
    DateTime? createdAt,
    String? createdBy,
    ArtifactType? type,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      parent: parentId ?? this.parent,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      type: type ?? this.type,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FolderModel.fromJson(String source) => FolderModel.fromMap(json.decode(source));
}
