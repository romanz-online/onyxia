import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

class CommentsRepository extends BaseFirestoreRepository<Comment> {
  CommentsRepository({required super.projectId});

  @override
  String get collectionPath => 'projects/$projectId/comments';

  @override
  Comment fromMap(Map<String, dynamic> map) => Comment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Comment item) => item.toMap();

  @override
  String getIdFromItem(Comment item) => item.id;

  @override
  bool get updateProjectMetadata => true;

  /// Watch comments filtered by target and type
  Stream<List<Comment>> watchComments({required String targetId}) {
    // Use multiple where clauses - need to create custom query since base queryStream
    // doesn't support multiple field filters yet
    return executeStream(() {
      return FirebaseFirestore.instance
          .collection(collectionPath)
          .where('targetId', isEqualTo: targetId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => fromMap(doc.data())).toList());
    }, <Comment>[]);
  }

  /// Add a comment with targetId
  Future<void> addComment({
    required String targetId,
    required Comment comment,
  }) async =>
      add(comment.copyWith(targetId: targetId));

  /// Update a comment with targetId
  Future<void> updateComment({
    required String targetId,
    required Comment comment,
  }) async =>
      update(comment.copyWith(targetId: targetId));
}
