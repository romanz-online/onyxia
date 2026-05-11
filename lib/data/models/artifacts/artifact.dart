import 'package:onyxia/export.dart';

abstract class Artifact {
  final String id;
  final String parentFolderId;
  final String title;
  final DateTime? createdAt;
  final String? createdBy;
  final ArtifactType type;
  final String? updatedBy;
  final DateTime? updatedAt;

  Artifact({
    this.id = '',
    this.parentFolderId = '',
    required this.title,
    this.createdAt,
    this.createdBy = 'Unknown',
    required this.type,
    this.updatedBy,
    this.updatedAt,
  });

  // Named constructor for shared field deserialization
  Artifact.fromMap(Map<String, dynamic> map)
      : id = map['id'] ?? '',
        parentFolderId = map['parent_folder_id'] ?? '',
        title = map['name'] ?? '',
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'],
        type = ArtifactType.values.fromString(map['type']),
        updatedBy = map['updated_by'],
        updatedAt = TimestampService.fromMap(map['updated_at']);

  /// Factory constructor that creates the appropriate concrete Artifact subclass
  /// based on the 'type' field in the map
  factory Artifact.factory(Map<String, dynamic> map) {
    final typeString = map['type'] as String?;
    final itemType = ArtifactType.values.fromString(typeString ?? '');

    return switch (itemType) {
      ArtifactType.canvas => CanvasModel.fromMap(map),
      ArtifactType.note => Note.fromMap(map),
      ArtifactType.folder => FolderModel.fromMap(map),
    };
  }

  /// Abstract method for child-specific fields.
  /// Do NOT use outside of Artifact class definition.
  Map<String, dynamic> toMapSub();

  // Top-level Postgres columns + subclass-specific fields wrapped in `body` jsonb.
  // The repository injects `project_id` at write time.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_folder_id': parentFolderId.isEmpty ? null : parentFolderId,
      'name': title,
      'type': type.value,
      'body': toMapSub(),
    };
  }

  Artifact copyWith({
    String? id,
    String? parentFolderId,
    String? title,
    DateTime? createdAt,
    String? createdBy,
    ArtifactType? type,
    String? updatedBy,
    DateTime? updatedAt,
  });

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Artifact('
        'parentFolderId: $parentFolderId, '
        'title: $title, '
        'createdAt: $createdAt, '
        'createdBy: $createdBy, '
        'type: $type, '
        'updatedBy: $updatedBy, '
        'updatedAt: $updatedAt, ';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Artifact &&
        other.id == id &&
        other.parentFolderId == parentFolderId &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.type == type &&
        other.updatedBy == updatedBy &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        parentFolderId.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode ^
        type.hashCode ^
        updatedBy.hashCode ^
        updatedAt.hashCode;
  }

  DateTime get getCreatedAt => createdAt ?? DateTime.now();
  DateTime get getUpdatedAt => updatedAt ?? DateTime.now();

  String get getCreatedBy => createdBy ?? 'Unknown';
  String get getUpdatedBy => updatedBy ?? 'Unknown';

  /// Returns the navigation URL for this item within the given project.
  String navigationUrl(String projectId) => '/project/$projectId/$title';

  dynamic castToSubtype() => switch (type) {
        ArtifactType.note => this as Note,
        ArtifactType.canvas => this as CanvasModel,
        ArtifactType.folder => this as FolderModel,
      };
}
