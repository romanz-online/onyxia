import 'package:onyxia/export.dart';

class PinsRepository extends BaseSupabaseRepository<Pin> {
  final String canvasId;

  PinsRepository({
    required super.projectId,
    required this.canvasId,
  });

  @override
  String get tableName => 'pins';

  @override
  Pin fromMap(Map<String, dynamic> map) => Pin.fromMap(map);

  @override
  Map<String, dynamic> toMap(Pin item) => {
        ...item.toMap(),
        'canvas_artifact_id': canvasId,
      };

  @override
  String getIdFromItem(Pin item) => item.id;

  @override
  Future<List<Pin>> getAll() =>
      query(field: 'canvas_artifact_id', isEqualTo: canvasId);

  @override
  Stream<List<Pin>> getStream({String? orderBy, bool descending = false}) {
    return queryStream(
      field: 'canvas_artifact_id',
      isEqualTo: canvasId,
      orderBy: orderBy,
      descending: descending,
    );
  }

  /// Real-time stream of all pins on this canvas, wrapped in a Pins container.
  Stream<Pins> getPinsStream() {
    return getStream().map((pins) => Pins(pins: pins));
  }

  /// Add multiple pins in a single round-trip.
  Future<void> addPins(List<Pin> pins) {
    if (pins.length == 1) return add(pins.first);
    final pinMap = {for (var pin in pins) pin.id: pin};
    return addMultiple(pinMap);
  }
}
