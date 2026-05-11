import 'package:onyxia/export.dart';

class Project {
  final String id;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;

  Project({
    required this.id,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    required this.name,
  });

  factory Project.initial() {
    return Project(
      id: '',
      createdBy: '',
      name: '',
    );
  }

  Project copyWith({
    String? id,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
  }) {
    return Project(
      id: id ?? this.id,
      createdBy: ownerId ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_by': createdBy,
      'name': name,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: TimestampService.fromMap(map['created_at']),
      updatedAt: TimestampService.fromMap(map['updated_at']),
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Project.fromJson(String source) =>
      Project.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Project(id: $id, '
        'createdBy: $createdBy, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'name: $name, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        name.hashCode;
  }
}
