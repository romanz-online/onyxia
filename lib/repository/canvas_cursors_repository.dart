import 'package:onyxia/export.dart';

class CanvasCursorsRepository extends BaseFirestoreRepository<UserCursor> {
  final String canvasId;

  CanvasCursorsRepository({
    required super.projectId,
    required this.canvasId,
  });

  @override
  String get collectionPath => 'projects/$projectId/artifacts/$canvasId/cursors';

  @override
  UserCursor fromMap(Map<String, dynamic> map) => UserCursor.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserCursor item) => item.toMap();

  @override
  String getIdFromItem(UserCursor item) => item.userId;

  @override
  bool get updateProjectMetadata => false;

  /// Stream of other users' cursors (excludes current user)
  Stream<List<UserCursor>> getCursorsStream(
    String currentUserId, [
    String? currentUserEmail,
  ]) =>
      queryStream(field: 'userId', isNotEqualTo: currentUserId);
}
