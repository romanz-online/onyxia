import 'package:onyxia/export.dart';

class ProjectMember {
  final String projectId;
  final String userId;
  final UserRole role;

  const ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
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

  factory ProjectMember.fromMap(Map<String, dynamic> map) => ProjectMember(
        projectId: map['project_id'] ?? '',
        userId: map['user_id'] ?? '',
        role: UserRole.values.fromString(map['role'] ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectMember &&
          other.projectId == projectId &&
          other.userId == userId);

  @override
  int get hashCode => Object.hash(projectId, userId);

  @override
  String toString() =>
      'ProjectMember(projectId: $projectId, userId: $userId, role: ${role.value})';
}
