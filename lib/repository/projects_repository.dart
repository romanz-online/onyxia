import 'package:onyxia/export.dart';

class ProjectsRepository extends BaseSupabaseRepository<Project> {
  final String? userId;

  ProjectsRepository({this.userId});

  @override
  String get tableName => 'projects';

  @override
  bool get requireProjectId => false;

  @override
  Project fromMap(Map<String, dynamic> map) => Project.fromMap(map);

  @override
  Map<String, dynamic> toMap(Project item) => item.toMap();

  @override
  String getIdFromItem(Project item) => item.id;

  /// Fetch all projects visible to a user. With Supabase RLS, the auth-scoped
  /// query already returns only the projects the user is a member of (or owns)
  /// — no client-side join required. Admins fall through the same path because
  /// admin-level access is enforced via RLS policies, not application logic.
  Future<List<Project>> getProjects(String userId) async {
    if (userId.isEmpty) return [];
    return getAll();
  }
}
