import 'package:onyxia/export.dart';

class CommentsRepository extends BaseSupabaseRepository<Comment> {
  CommentsRepository({required super.projectId});

  @override
  String get tableName => 'comments';

  @override
  Comment fromMap(Map<String, dynamic> map) => Comment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Comment item) => item.toMap();

  @override
  String getIdFromItem(Comment item) => item.id;

  /// Watch comments attached to a target artifact (canvas or note).
  /// `targetId` is the artifact's UUID — NOT its title (legacy bug).
  Stream<List<Comment>> watchComments({required String targetId}) {
    return queryStream(field: 'target_id', isEqualTo: targetId);
  }

  Future<void> addComment({
    required String targetId,
    required Comment comment,
  }) async =>
      add(comment.copyWith(targetId: targetId));

  Future<void> updateComment({
    required String targetId,
    required Comment comment,
  }) async =>
      update(comment.copyWith(targetId: targetId));
}
