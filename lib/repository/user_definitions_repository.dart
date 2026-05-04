import 'package:onyxia/export.dart';

class UserDefinitionsRepository extends BaseFirestoreRepository<UserDefinition> {
  UserDefinitionsRepository({required super.projectId});

  @override
  String get collectionPath => 'users';

  @override
  UserDefinition fromMap(Map<String, dynamic> map) => UserDefinition.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserDefinition item) => item.toMap();

  @override
  String getIdFromItem(UserDefinition item) => item.id;

  @override
  bool get updateProjectMetadata => false;

  Future<UserDefinition?> getByEmail(String email) async {
    final results = await query(field: 'email', isEqualTo: email, limit: 1);
    return results.firstOrNull;
  }
}
