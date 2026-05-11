import 'package:onyxia/export.dart';

class FolderModel extends Artifact {
  FolderModel({
    super.id,
    super.createdAt,
    super.parentFolderId,
    super.createdBy,
    super.name = 'Folder',
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
    String? parentFolderId,
    String? title,
    DateTime? createdAt,
    String? createdBy,
    ArtifactType? type,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      name: title ?? this.name,
      type: type ?? this.type,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
