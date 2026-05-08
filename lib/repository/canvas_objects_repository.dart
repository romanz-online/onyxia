import 'package:onyxia/export.dart';

class CanvasObjectsRepository extends BaseSupabaseRepository<CanvasObject> {
  final String canvasId;

  CanvasObjectsRepository({
    required super.projectId,
    required this.canvasId,
  });

  @override
  String get tableName => 'canvas_objects';

  @override
  CanvasObject fromMap(Map<String, dynamic> map) => CanvasObject.fromMap(map);

  @override
  Map<String, dynamic> toMap(CanvasObject item) => {
        ...item.toMap(),
        'canvas_artifact_id': canvasId,
      };

  @override
  String getIdFromItem(CanvasObject item) => item.id;

  @override
  Future<List<CanvasObject>> getAll() =>
      query(field: 'canvas_artifact_id', isEqualTo: canvasId);

  @override
  Stream<List<CanvasObject>> getStream({String? orderBy, bool descending = false}) {
    return queryStream(
      field: 'canvas_artifact_id',
      isEqualTo: canvasId,
      orderBy: orderBy,
      descending: descending,
    );
  }

  /// Real-time stream of all canvas objects on this canvas, wrapped in a CanvasObjects container.
  Stream<CanvasObjects> getCanvasObjectsStream() {
    return getStream().map((objects) => CanvasObjects(objects: objects, selectedObjects: []));
  }

  /// Add multiple canvas objects in a single round-trip.
  Future<void> addObjects(List<CanvasObject> objects) {
    if (objects.length == 1) return add(objects.first);
    final objectMap = {for (var obj in objects) obj.id: obj};
    return addMultiple(objectMap);
  }
}
