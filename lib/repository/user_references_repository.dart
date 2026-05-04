import 'package:onyxia/export.dart';

class UserReferencesRepository extends BaseFirestoreRepository<UserReference> {
  UserReferencesRepository({required super.projectId});

  @override
  String get collectionPath => 'projects/$projectId/members';

  @override
  UserReference fromMap(Map<String, dynamic> map) => UserReference.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserReference item) => item.toMap();

  @override
  String getIdFromItem(UserReference item) => item.id;

  @override
  bool get updateProjectMetadata => false;
}
