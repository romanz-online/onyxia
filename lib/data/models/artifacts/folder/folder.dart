import 'package:onyxia/export.dart';

class FolderModel extends Artifact {
  FolderModel({
    super.id,
    super.type = ArtifactType.folder,
    super.name = 'Folder',
    super.parentFolderId,
    //
    super.createdAt,
    super.createdBy,
    super.updatedAt,
    super.updatedBy,
    //
  });

  FolderModel.fromMap(super.map) : super.fromMap();

  @override
  Map<String, dynamic> toMapSub() => {};

  @override
  FolderModel copyWith({
    String? id,
    String? name,
    String? parentFolderId,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
    );
  }
}
