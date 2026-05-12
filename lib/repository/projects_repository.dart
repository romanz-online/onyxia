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
}
