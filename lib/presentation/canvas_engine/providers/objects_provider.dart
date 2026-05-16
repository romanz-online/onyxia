import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import 'pins_provider.dart';
import 'dart:async';

final canvasConfigProvider = Provider.autoDispose<CanvasConfig>((ref) {
  final type = ref.watch(selectedArtifactProvider
      .select((a) => a is CanvasArtifact ? a.canvasType : null));
  return type == null ? CanvasConfig.flow() : CanvasConfig.fromType(type);
});

final canvasObjectsProvider =
    NotifierProvider.autoDispose<ObjectsNotifier, CanvasObjects>(
  ObjectsNotifier.new,
);

class ObjectsNotifier extends Notifier<CanvasObjects> {
  late CanvasObjectsRepository repository;
  late String canvasId;
  String? vaultId;
  StreamSubscription? _subscription;

  @override
  CanvasObjects build() {
    // Use .select() to only rebuild when the ID changes, not on every canvas metadata update
    canvasId = ref.watch(selectedArtifactProvider
        .select((a) => a is CanvasArtifact ? a.id : ''));
    vaultId = ref.watch(selectedVaultProvider)?.id;
    repository = CanvasObjectsRepository(
      vaultId: vaultId,
      canvasId: canvasId,
    );

    ref.onDispose(_cancelSubscriptions);

    _init();

    return CanvasObjects.initial();
  }

  void _init() {
    if (canvasId.isEmpty || vaultId == null) return;

    _subscription = repository.getStream().listen((remoteObjects) async {
      List<CanvasObject> updatedObjects = [];

      for (final object in remoteObjects) {
        if (object.isImage) {
          await ImageService.preloadImages([object.imageProps.imageUrl]);
        }

        updatedObjects.add(object);
      }

      if (ref.mounted) {
        state = state.copyWith(objects: updatedObjects);
      }
    });
  }

  void _cancelSubscriptions() {
    _subscription?.cancel();
  }

  CanvasObject getObjectById(String id) {
    return state.objects.firstWhere(
      (element) => element.id == id,
      orElse: () => CanvasObject.initial(),
    );
  }

  /// Updates the local state of the object; does not update backend.
  /// Use this to queue up multiple updates together. updateObjectState multiple
  /// times and then updateObject or updateObjects once to consolidate updates.
  void updateObjectState(CanvasObject object) {
    final index = state.objects.indexWhere((obj) => obj.id == object.id);

    if (index == -1) return;

    final updatedObjects = List<CanvasObject>.from(state.objects);
    updatedObjects[index] = object;

    state = state.copyWith(
      objects: updatedObjects,
      selectedObjects: state.selectedObjects.map((o) {
        return o.id == object.id ? object : o;
      }).toList(),
    );
  }

  void updateObjectsState(List<CanvasObject> objects) {
    for (final obj in objects) {
      updateObjectState(obj);
    }
  }

  void updateObject(CanvasObject object) {
    updateObjectState(object);
    repository.update([object]);
  }

  void updateObjects({List<CanvasObject> objects = const []}) {
    for (final obj in objects) {
      updateObjectState(obj);
    }

    repository.update(objects.isEmpty ? state.objects : objects);
  }

  void addObjectState(CanvasObject object) {
    // no objects with duplicate IDs
    if (!state.objects.contains(object)) {
      state = state.copyWith(objects: [...state.objects, object]);
    }
  }

  void addObject(CanvasObject object) {
    addObjectState(object);
    repository.add([object]);
  }

  void addObjects(List<CanvasObject> objects) {
    List<CanvasObject> currentObjects = List.from(state.objects);

    for (final obj in objects) {
      if (!currentObjects.contains(obj)) {
        currentObjects.add(obj);
      }
    }

    state = state.copyWith(objects: currentObjects);
    repository.add(objects);
  }

  void deleteObject(CanvasObject object) {
    final connectedArrows = state.objects
        .where((o) =>
            o.isArrow &&
            (o.arrowProps.startObjectId == object.id ||
                o.arrowProps.endObjectId == object.id))
        .toList();

    final objectsToDelete = [object, ...connectedArrows];
    final deletedIds = objectsToDelete.map((o) => o.id).toSet();

    // Update state with adjusted objects
    state = state.copyWith(
      selectedObjects: [],
      objects: state.objects.where((o) => !deletedIds.contains(o.id)).toList(),
    );

    // Get the actual pins and delete them
    final pinsNotifier = ref.read(pinsProvider.notifier);
    final pinsToDelete = ref
        .read(pinsProvider)
        .pins
        .where((e) => e.pinnedObjectId == object.id)
        .toList();

    if (pinsToDelete.isNotEmpty) {
      pinsNotifier.deletePins(pinsToDelete);
    }

    repository.deleteMultiple([object, ...connectedArrows]);
  }

  void deleteObjects(List<CanvasObject> objects) {
    if (objects.isEmpty) return;

    final connectedArrows = state.objects
        .where((o) =>
            o.isArrow &&
            (objects.any((obj) =>
                o.arrowProps.startObjectId == obj.id ||
                o.arrowProps.endObjectId == obj.id)))
        .toList();

    final allObjectsToDelete = [...objects, ...connectedArrows];
    final allDeletedIds = allObjectsToDelete.map((o) => o.id).toSet();

    state = state.copyWith(
      selectedObjects: [],
      objects:
          state.objects.where((o) => !allDeletedIds.contains(o.id)).toList(),
    );

    repository.deleteMultiple(allObjectsToDelete);
  }

  void selectObject(CanvasObject object) {
    if (state.selectedObjects.contains(object) || object.id.isEmpty) return;
    state = state.copyWith(selectedObjects: [...state.selectedObjects, object]);
  }

  void selectObjects(List<CanvasObject> objects) {
    List<CanvasObject> newList = state.selectedObjects;
    for (final obj in objects) {
      if (!state.selectedObjects.contains(obj) && obj.id.isNotEmpty) {
        newList.add(obj);
      }
    }
    state = state.copyWith(selectedObjects: newList);
  }

  void deselectObject(CanvasObject object) {
    if (!state.selectedObjects.contains(object)) return;
    state = state.copyWith(
      selectedObjects:
          state.selectedObjects.where((obj) => obj != object).toList(),
    );
  }

  void clearSelectedObjects() {
    state = state.copyWith(
      selectedObjects: [],
    );
  }
}
