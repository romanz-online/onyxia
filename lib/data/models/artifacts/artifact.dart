import 'package:onyxia/export.dart';

abstract class Artifact {
  final String id;
  final String parent;
  final String title;
  final DateTime? createdAt;
  final String? createdBy;
  final ArtifactType type;
  final String? updatedBy;
  final DateTime? updatedAt;

  /// The sub-type label for this item (e.g. 'note', 'canvas').
  /// Used by GenUI catalog widgets for display grouping.
  String get noteType => type.value;

  Artifact({
    this.id = '',
    this.parent = '',
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
        parent = map['parent'] ?? map['parentId'] ?? '',
        title = map['title'] ?? map['name'] ?? '',
        createdAt = map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : null,
        createdBy = map['createdBy'] ?? map['owner'],
        type = ArtifactType.values.fromString(map['type'] ?? ''),
        updatedBy = map['updatedBy'],
        updatedAt = map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : null;

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

  // Concrete implementation that merges shared fields with child fields
  Map<String, dynamic> toMap() {
    final sharedMap = {
      'id': id,
      'parentId': parent,
      'title': title,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'type': type.value,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };

    // Merge shared fields with child-specific fields
    return {...sharedMap, ...toMapSub()};
  }

  Artifact copyWith({
    String? id,
    String? parentId,
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
        'parentId: $parent, '
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
        other.parent == parent &&
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
        parent.hashCode ^
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
