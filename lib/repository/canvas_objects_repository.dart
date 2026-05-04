import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

class CanvasObjectsRepository extends BaseFirestoreRepository<CanvasObject> {
  final String canvasId;

  CanvasObjectsRepository({
    required super.projectId,
    required this.canvasId,
  });

  @override
  String get collectionPath => 'projects/$projectId/artifacts/$canvasId/objects';

  @override
  CanvasObject fromMap(Map<String, dynamic> map) => CanvasObject.fromMap(map);

  @override
  Map<String, dynamic> toMap(CanvasObject item) => item.toMap();

  @override
  String getIdFromItem(CanvasObject item) => item.id;

  @override
  bool get updateProjectMetadata => true;

  /// Get stream of all canvas objects wrapped in CanvasObjects container
  Stream<CanvasObjects> getCanvasObjectsStream() {
    return executeStream(() {
      return FirebaseFirestore.instance.collection(collectionPath).snapshots().map((snapshot) {
        final objects = snapshot.docs.map((doc) => fromMap(doc.data())).toList();
        return CanvasObjects(objects: objects, selectedObjects: []);
      });
    }, CanvasObjects.initial());
  }

  /// Add multiple canvas objects
  Future<void> addObjects(List<CanvasObject> objects) {
    if (objects.length == 1) {
      return add(objects.first);
    }

    final objectMap = {for (var obj in objects) obj.id: obj};
    return addMultiple(objectMap);
  }
}
