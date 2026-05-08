import 'package:onyxia/export.dart';

class UserReferencesRepository extends BaseSupabaseRepository<UserReference> {
  UserReferencesRepository({required super.projectId});

  @override
  String get tableName => 'project_members';

  @override
  UserReference fromMap(Map<String, dynamic> map) => UserReference.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserReference item) => {
        ...item.toMap(),
        'project_id': projectId,
      };

  @override
  String getIdFromItem(UserReference item) => item.id;

  @override
  Future<List<UserReference>> getAll() async {
    return query(field: 'project_id', isEqualTo: projectId);
  }

  @override
  Stream<List<UserReference>> getStream({String? orderBy, bool descending = false}) {
    return queryStream(
      field: 'project_id',
      isEqualTo: projectId,
      orderBy: orderBy,
      descending: descending,
    );
  }
}
