import 'package:onyxia/export.dart';

class ProjectMembersRepository extends BaseSupabaseRepository<ProjectMember> {
  ProjectMembersRepository({required super.projectId});

  @override
  String get tableName => 'project_members';

  @override
  String get scopeField => 'project_id';

  @override
  List<String> get primaryKeyFields => const ['project_id', 'user_id'];

  @override
  Map<String, dynamic> keyFilter(ProjectMember item) => {
        'project_id': item.projectId,
        'user_id': item.userId,
      };

  @override
  ProjectMember fromMap(Map<String, dynamic> map) => ProjectMember.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProjectMember item) => item.toMap();

  /// Unused for composite-key tables — the base contract still requires it.
  @override
  String getIdFromItem(ProjectMember item) => item.userId;
}
