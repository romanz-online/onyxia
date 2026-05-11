import 'package:onyxia/export.dart';
import 'bounds_provider.dart';

class ArrowPrimedObjectsNotifier extends StateNotifier<List<CanvasObject>> {
  ArrowPrimedObjectsNotifier() : super([]);

  void set(List<CanvasObject> objects) => state = [...objects];

  void clear() {
    if (state.isNotEmpty) {
      state = [];
    }
  }
}

final arrowPrimedObjectsProvider = StateNotifierProvider.autoDispose<ArrowPrimedObjectsNotifier, List<CanvasObject>>(
  (ref) => ArrowPrimedObjectsNotifier(),
);

/// Data for a single primed object in arrow tool mode
class ArrowToolPrimedData {
  final CanvasObject object;
  final Offset cursorPosition;
  final ConnectionPoint closestEdge;
  final Offset relativeOffset;

  const ArrowToolPrimedData({
    required this.object,
    required this.cursorPosition,
    required this.closestEdge,
    required this.relativeOffset,
  });

  /// Calculate the absolute position of the arrow tool well with connection point snapping
  Offset get absolutePosition {
    final connectionPointOffset = closestEdge.getOffset(object);
    final basePosition = connectionPointOffset + relativeOffset;

    // Check if the calculated base position is close to any connection point
    final allConnectionPoints = [
      ConnectionPoint.top,
      ConnectionPoint.left,
      ConnectionPoint.right,
      ConnectionPoint.bottom
    ];

    Offset? closestSnapPoint;
    double closestDistance = double.infinity;

    for (final connectionPoint in allConnectionPoints) {
      final connectionOffset = connectionPoint.getOffset(object);
      final distance = (basePosition - connectionOffset).distance;

      if (distance <= CanvasBounds.gridSpacing && distance < closestDistance) {
        closestDistance = distance;
        closestSnapPoint = connectionOffset;
      }
    }

    // Return snapped position if found, otherwise return original calculated position
    return closestSnapPoint ?? basePosition;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArrowToolPrimedData &&
        other.object.id == object.id &&
        other.cursorPosition == cursorPosition &&
        other.closestEdge == closestEdge &&
        other.relativeOffset == relativeOffset;
  }

  @override
  int get hashCode => object.id.hashCode ^ cursorPosition.hashCode ^ closestEdge.hashCode ^ relativeOffset.hashCode;
}

class ArrowToolPrimedObjectsNotifier extends StateNotifier<ArrowToolPrimedData?> {
  ArrowToolPrimedObjectsNotifier() : super(null);

  void setPrimed(CanvasObject object, Offset cursorPosition) {
    final nearestPoint = object.findNearestBoundOffset(cursorPosition);
    state = ArrowToolPrimedData(
      object: object,
      cursorPosition: cursorPosition,
      closestEdge: nearestPoint.$1,
      relativeOffset: nearestPoint.$2 - nearestPoint.$1.getOffset(object),
    );
  }

  void updateCursor(Offset cursorPosition) {
    if (state == null) return;

    final nearestPoint = state!.object.findNearestBoundOffset(cursorPosition);
    state = ArrowToolPrimedData(
      object: state!.object,
      cursorPosition: cursorPosition,
      closestEdge: nearestPoint.$1,
      relativeOffset: nearestPoint.$2 - nearestPoint.$1.getOffset(state!.object),
    );
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

final arrowToolPrimedObjectsProvider =
    StateNotifierProvider.autoDispose<ArrowToolPrimedObjectsNotifier, ArrowToolPrimedData?>(
  (ref) => ArrowToolPrimedObjectsNotifier(),
);
