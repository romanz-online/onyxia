import 'package:onyxia/export.dart';

final hoveredObjectsProvider = NotifierProvider.autoDispose<
    HoveredObjectsNotifier, List<CanvasObject>>(
  HoveredObjectsNotifier.new,
);

class HoveredObjectsNotifier extends Notifier<List<CanvasObject>> {
  @override
  List<CanvasObject> build() => [];

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

  bool containsObject(CanvasObject object) =>
      state.any((obj) => obj.id == object.id);

  CanvasObject getObjectById(String id) => state.firstWhere(
        (e) => e.id == id,
        orElse: () => CanvasObject.initial(),
      );
}
