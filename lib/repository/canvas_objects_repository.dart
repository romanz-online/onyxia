import 'package:onyxia/export.dart';

class CanvasObjectsRepository extends BaseSupabaseRepository<CanvasObject> {
  final String canvasId;

  CanvasObjectsRepository({required super.vaultId, required this.canvasId});

  @override
  String get tableName => 'canvas_objects';

  @override
  String get scopeField => 'canvas_artifact_id';

  @override
  dynamic get scopeValue => canvasId;

  @override
  CanvasObject fromMap(Map<String, dynamic> map) => CanvasObject.fromMap(map);

  @override
  Map<String, dynamic> toMap(CanvasObject item) => item.toMap();

  @override
  String getIdFromItem(CanvasObject item) => item.id;
}
