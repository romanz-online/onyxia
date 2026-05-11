import 'package:onyxia/export.dart';

enum UserRole with NarwhalEnum {
  member,
  admin,
  owner;

  String get label => switch (this) {
        UserRole.member => 'Member',
        UserRole.admin => 'Admin',
        UserRole.owner => 'Owner',
      };
}

class ProjectMember {
  final String projectId;
  final String userId;
  final UserRole role;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  ProjectMember copyWith({
    String? projectId,
    String? userId,
    UserRole? role,
  }) =>
      ProjectMember(
        projectId: projectId ?? this.projectId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
      );

  Map<String, dynamic> toMap() => {
        'project_id': projectId,
        'user_id': userId,
        'role': role.value,
      };

  ProjectMember.fromMap(Map<String, dynamic> map)
      : projectId = map['project_id'] ?? '',
        userId = map['user_id'] ?? '',
        role = UserRole.values.fromString(map['role'] ?? ''),
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectMember &&
        other.projectId == projectId &&
        other.userId == userId &&
        //
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return projectId.hashCode ^
        userId.hashCode ^
        role.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }

  @override
  String toString() => 'ProjectMember(projectId: $projectId, '
      'userId: $userId, '
      'role: ${role.value}, '
      ')';
}
