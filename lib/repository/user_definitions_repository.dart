import 'package:onyxia/export.dart';

class UserDefinitionsRepository extends BaseSupabaseRepository<UserDefinition> {
  UserDefinitionsRepository({super.projectId});

  @override
  String get tableName => 'users';

  @override
  bool get requireProjectId => false;

  @override
  UserDefinition fromMap(Map<String, dynamic> map) => UserDefinition.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserDefinition item) => item.toMap();

  @override
  String getIdFromItem(UserDefinition item) => item.id;

  Future<UserDefinition?> getByEmail(String email) async {
    final results = await query(field: 'email', isEqualTo: email, limit: 1);
    return results.firstOrNull;
  }
}
