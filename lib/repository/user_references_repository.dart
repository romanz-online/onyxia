import 'package:onyxia/export.dart';

class UserReferencesRepository extends BaseSupabaseRepository<UserReference> {
  UserReferencesRepository({required super.projectId});

  @override
  String get tableName => 'project_members';

  @override
  String get scopeField => 'project_id';

  @override
  UserReference fromMap(Map<String, dynamic> map) => UserReference.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserReference item) => item.toMap();

  @override
  String getIdFromItem(UserReference item) => item.id;
}
