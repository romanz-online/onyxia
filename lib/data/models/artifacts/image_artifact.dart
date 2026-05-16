import 'package:onyxia/export.dart';

class ImageArtifact extends Artifact {
  final String storagePath;
  final String mimeType;

  ImageArtifact({
    super.id,
    super.type = ArtifactType.image,
    super.name = 'Untitled',
    super.parentFolderId,
    super.createdAt,
    super.createdBy,
    super.updatedAt,
    super.updatedBy,
    //
    required this.storagePath,
    required this.mimeType,
  });

  String get downloadUrl => Supabase.instance.client.storage
      .from('vault-files')
      .getPublicUrl(storagePath);

  @override
  ImageArtifact copyWith({
    String? id,
    String? name,
    String? parentFolderId,
    //
    String? storagePath,
    String? mimeType,
  }) =>
      ImageArtifact(
        id: id ?? this.id,
        name: name ?? this.name,
        parentFolderId: parentFolderId ?? this.parentFolderId,
        //
        storagePath: storagePath ?? this.storagePath,
        mimeType: mimeType ?? this.mimeType,
      );

  @override
  Map<String, dynamic> toMapSub() =>
      {'storage_path': storagePath, 'mime_type': mimeType};

  ImageArtifact.fromMap(super.map)
      : storagePath = ((map['body'] as Map<String, dynamic>?)?['storage_path']
                as String?) ??
            '',
        mimeType =
            ((map['body'] as Map<String, dynamic>?)?['mime_type'] as String?) ??
                'image/png',
        super.fromMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (super == other &&
          other is ImageArtifact &&
          other.storagePath == storagePath &&
          other.mimeType == mimeType);

  @override
  int get hashCode => super.hashCode ^ storagePath.hashCode ^ mimeType.hashCode;
}
