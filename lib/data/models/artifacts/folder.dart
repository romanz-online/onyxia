import 'package:onyxia/export.dart';

class FolderArtifact extends Artifact {
  FolderArtifact({
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

  FolderArtifact.fromMap(super.map) : super.fromMap();

  @override
  Map<String, dynamic> toMapSub() => {};

  @override
  FolderArtifact copyWith({
    String? id,
    String? name,
    String? parentFolderId,
  }) {
    return FolderArtifact(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
    );
  }
}
