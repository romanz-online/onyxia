import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

class PinsRepository extends BaseFirestoreRepository<Pin> {
  final String canvasId;

  PinsRepository({
    required super.projectId,
    required this.canvasId,
  });

  @override
  String get collectionPath => 'projects/$projectId/artifacts/$canvasId/artObjs';

  @override
  Pin fromMap(Map<String, dynamic> map) => Pin.fromMap(map);

  @override
  Map<String, dynamic> toMap(Pin item) => item.toMap();

  @override
  String getIdFromItem(Pin item) => item.id;

  @override
  bool get updateProjectMetadata => true;

  Stream<Pins> getPinsStream() {
    return executeStream(() {
      return FirebaseFirestore.instance.collection(collectionPath).snapshots().map((snapshot) {
        return Pins(
          pins: snapshot.docs.map((doc) => fromMap(doc.data())).toList(),
        );
      });
    }, Pins(pins: []));
  }

  /// Add multiple pins
  Future<void> addPins(List<Pin> pins) {
    if (pins.length == 1) {
      return add(pins.first);
    }

    final pinMap = {for (var pin in pins) pin.id: pin};
    return addMultiple(pinMap);
  }
}
