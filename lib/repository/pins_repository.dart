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
  String get scopeField => 'canvas_artifact_id';

  @override
  dynamic get scopeValue => canvasId;

  @override
  Pin fromMap(Map<String, dynamic> map) => Pin.fromMap(map);

  @override
  Map<String, dynamic> toMap(Pin item) => item.toMap();

  @override
  String getIdFromItem(Pin item) => item.id;

  /// Real-time stream of all pins on this canvas, wrapped in a Pins container.
  Stream<Pins> getPinsStream() {
    return getStream().map((pins) => Pins(pins: pins));
  }
}
