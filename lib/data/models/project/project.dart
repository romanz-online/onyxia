import 'package:onyxia/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;

  Project({
    required this.id,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });

  factory Project.initial() {
    return Project(
      id: '',
      ownerId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'name': name,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    // Convert timestamps or milliseconds to DateTime
    DateTime? getDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        return null;
      }
    }

    return Project(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      createdAt: getDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: getDateTime(map['updatedAt']) ?? DateTime.now(),
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Project.fromJson(String source) => Project.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Project(id: $id, '
        'ownerId: $ownerId, '
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
        other.ownerId == ownerId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ ownerId.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode ^ name.hashCode;
  }
}
