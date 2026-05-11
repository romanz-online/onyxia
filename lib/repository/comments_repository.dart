import 'package:onyxia/export.dart';

class CommentsRepository extends BaseSupabaseRepository<Comment> {
  final String canvasId;

  CommentsRepository({required super.projectId, required this.canvasId});

  @override
  String get tableName => 'comments';

  @override
  String get scopeField => 'canvas_artifact_id';

  @override
  dynamic get scopeValue => canvasId;

  @override
  Comment fromMap(Map<String, dynamic> map) => Comment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Comment item) => item.toMap();

  @override
  String getIdFromItem(Comment item) => item.id;
}
