import 'package:onyxia/export.dart';

enum ArtifactType with OnyxiaEnum {
  note,
  canvas,
  folder,
  image;

  String get label => switch (this) {
    note => 'Note',
    canvas => 'Canvas',
    folder => 'Folder',
    image => 'Image',
  };
}

abstract class Artifact {
  final String id;
  final ArtifactType type;
  final String name;
  final String parentFolderId;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  // TODO: there are a lot of database functions which trigger updatedAt and createdAt, but since the compaction worker runs with no auth it sets updatedBy and createdBy to null sometimes. worth thinking about whether the *By fields are even needed or if they're taking up space for no reason.

  Artifact({
    String? id,
    required this.type,
    required this.name,
    this.parentFolderId = '',
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  }) : this.id = id == null || id.isEmpty ? const Uuid().v4() : id;

  // Named constructor for shared field deserialization
  Artifact.fromMap(Map<String, dynamic> map)
    : id = map['id'] ?? '',
      type = ArtifactType.values.fromString(map['type']),
      name = map['name'] ?? '',
      parentFolderId = map['parent_folder_id'] ?? '',
      //
      createdAt = TimestampService.fromMap(map['created_at']),
      createdBy = map['created_by'] ?? '',
      updatedAt = TimestampService.fromMap(map['updated_at']),
      updatedBy = map['updated_by'] ?? '';

  /// Factory constructor that creates the appropriate concrete Artifact subclass
  /// based on the 'type' field in the map
  factory Artifact.factory(Map<String, dynamic> map) {
    final typeString = map['type'] as String?;
    final itemType = ArtifactType.values.fromString(typeString ?? '');

    return switch (itemType) {
      ArtifactType.canvas => CanvasArtifact.fromMap(map),
      ArtifactType.note => NoteArtifact.fromMap(map),
      ArtifactType.folder => FolderArtifact.fromMap(map),
      ArtifactType.image => ImageArtifact.fromMap(map),
    };
  }

  /// Abstract method for child-specific fields.
  /// Do NOT use outside of Artifact class definition.
  Map<String, dynamic> toMapSub();

  // Top-level Postgres columns + subclass-specific fields wrapped in `body` jsonb.
  // The repository injects `vault_id` at write time.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'name': name,
      'parent_folder_id': parentFolderId.isEmpty ? null : parentFolderId,
      'body': toMapSub(),
    };
  }

  Artifact copyWith({String? id, String? name, String? parentFolderId});

  @override
  String toString() {
    return 'Artifact('
        'type: $type, '
        'name: $name, '
        'parentFolderId: $parentFolderId, '
        //
        'createdAt: $createdAt, '
        'createdBy: $createdBy, '
        'updatedAt: $updatedAt, '
        'updatedBy: $updatedBy, ';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Artifact &&
        other.id == id &&
        other.type == type &&
        other.name == name &&
        other.parentFolderId == parentFolderId &&
        //
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        parentFolderId.hashCode ^
        name.hashCode ^
        type.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }

  dynamic castToSubtype() => switch (type) {
    ArtifactType.note => this as NoteArtifact,
    ArtifactType.canvas => this as CanvasArtifact,
    ArtifactType.folder => this as FolderArtifact,
    ArtifactType.image => this as ImageArtifact,
  };
}
