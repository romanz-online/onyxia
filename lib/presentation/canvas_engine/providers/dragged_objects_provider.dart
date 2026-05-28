import 'package:onyxia/export.dart';

class DraggedObjectsNotifier extends Notifier<List<CanvasObject>> {
  @override
  List<CanvasObject> build() => [];

  /// Returns the current list of dragged objects
  List<CanvasObject> get draggedObjects => state;

  /// Checks if a specific object is currently being dragged
  bool isDragged(CanvasObject object) => state.contains(object);

  /// Adds an object to the dragged list if it's not already present
  void addDraggedObject(CanvasObject object) {
    if (!state.contains(object)) {
      state = [...state, object];
    }
  }

  void setDraggedObjects(List<CanvasObject> objects) => state = [...objects];

  /// Removes an object from the dragged list
  void removeDraggedObject(CanvasObject object) {
    if (state.contains(object)) {
      state = state.where((obj) => obj != object).toList();
    }
  }

  /// Clears all dragged objects
  void clearDraggedObjects() => state = [];

  /// Returns the number of currently dragged objects
  int get draggedCount => state.length;

  /// Checks if any objects are currently being dragged
  bool get hasDraggedObjects => state.isNotEmpty;
}

final draggedObjectsProvider =
    NotifierProvider.autoDispose<DraggedObjectsNotifier, List<CanvasObject>>(
      DraggedObjectsNotifier.new,
    );
