import 'package:onyxia/export.dart';

final hoveredObjectsProvider =
    StateNotifierProvider.autoDispose<HoveredObjectsNotifier, List<CanvasObject>>((ref) => HoveredObjectsNotifier());

class HoveredObjectsNotifier extends StateNotifier<List<CanvasObject>> {
  HoveredObjectsNotifier() : super([]);

  void addObject(CanvasObject object) {
    if (!state.contains(object)) {
      state = [...state, object];
    }
  }

  void removeObject(CanvasObject object) {
    if (state.contains(object)) {
      state = state.where((obj) => obj.id != object.id).toList();
    }
  }

  void clearObjects() {
    state = [];
  }

  bool containsObject(CanvasObject object) => state.any((obj) => obj.id == object.id);

  CanvasObject getObjectById(String id) => state.firstWhere(
        (e) => e.id == id,
        orElse: () => CanvasObject.initial(),
      );
}
