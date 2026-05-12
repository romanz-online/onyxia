import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import 'pins_provider.dart';
import 'dart:async';

final canvasConfigProvider = Provider.autoDispose<CanvasConfig>((ref) {
  final type = ref.watch(currentCanvasProvider.select((c) => c?.canvasType));
  return type == null ? CanvasConfig.flow() : CanvasConfig.fromType(type);
});

// Holds the canvas ID from URL route parameter
// Set by CanvasLoaderService.setupCanvas(), cleared on cleanup
final urlCanvasIdProvider = StateProvider.autoDispose<String?>((ref) => null);

// Provides current canvas with URL-first priority
// Auto-disposes when widget unmounts
final currentCanvasProvider = Provider.autoDispose<CanvasArtifact?>((ref) {
  final projectId = ref.watch(projectsProvider).selectedProject?.id;
  if (projectId == null) return null;

  // Priority 1: URL canvas ID (set by CanvasLoaderService)
  final urlCanvasId = ref.watch(urlCanvasIdProvider);

  if (urlCanvasId != null) {
    final canvas = ref.watch(canvasByIdProvider(urlCanvasId));
    if (canvas != null) return canvas;
  }

  // Priority 2: Selected item (fallback)
  final selectedItem = ref.watch(selectedArtifactProvider);
  return selectedItem is CanvasArtifact ? selectedItem : null;
});

final canvasObjectsProvider =
    StateNotifierProvider.autoDispose<ObjectsNotifier, CanvasObjects>((ref) {
  // Use .select() to only rebuild when the ID changes, not on every canvas metadata update
  final canvasId = ref.watch(currentCanvasProvider.select((c) => c?.id ?? ''));
  final projectId = ref.watch(projectsProvider).selectedProject?.id;

  final notifier = ObjectsNotifier(
    CanvasObjects.initial(),
    repository: CanvasObjectsRepository(
      projectId: projectId,
      canvasId: canvasId,
    ),
    canvasId: canvasId,
    projectId: projectId,
  );

  // Ensure immediate disposal when canvas changes
  // This provides synchronous cleanup before new provider starts
  ref.onDispose(() {
    notifier._cancelSubscriptions();
  });

  return notifier;
});

class ObjectsNotifier extends StateNotifier<CanvasObjects> {
  final CanvasObjectsRepository repository;
  final String canvasId;
  final String? projectId;
  StreamSubscription? _subscription;
  int _maxLayer = 0;

  int get maxLayer => _maxLayer;
  int nextLayer() {
    _maxLayer++;
    return _maxLayer;
  }

  ObjectsNotifier(
    super.state, {
    required this.repository,
    required this.canvasId,
    required this.projectId,
  }) {
    _init();
  }

  /// Sorts the list of objects by their layer
  List<CanvasObject> _sortObjects(List<CanvasObject> objects) =>
      objects..sort((a, b) => a.layer.compareTo(b.layer));

  void _init() {
    if (canvasId.isEmpty || projectId == null) return;

    _subscription = repository.getStream().listen((remoteObjects) async {
      final sorted = _sortObjects(remoteObjects);
      List<CanvasObject> updatedObjects = [];

      for (final object in sorted) {
        if (object.isImage) {
          await ImageService.preloadImages([object.imageProps.imageUrl]);
        }

        updatedObjects.add(object);
      }

      if (mounted) {
        state = state.copyWith(objects: updatedObjects);
        // Update maxLayer based on loaded objects
        _maxLayer = updatedObjects.isEmpty
            ? 0
            : updatedObjects
                .map((o) => o.layer)
                .reduce((a, b) => a > b ? a : b);
      }
    });
  }

  void _cancelSubscriptions() {
    _subscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
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

    // Resort to maintain proper arrow/layer ordering
    final sortedObjects = _sortObjects(updatedObjects);

    state = state.copyWith(
      objects: sortedObjects,
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

  void updateObject(WidgetRef ref, CanvasObject object) {
    pipe(ref, () async {
      updateObjectState(object);
      repository.update(object);
    }).catchError((e, stack) {
      debugPrint('pipe error in updateObject: $e');
    });
  }

  void updateObjects(WidgetRef ref, {List<CanvasObject> objects = const []}) {
    pipe(ref, () async {
      for (final obj in objects) {
        updateObjectState(obj);
      }

      repository.updateMultiple(objects.isEmpty ? state.objects : objects);
    }).catchError((e, stack) {
      debugPrint('pipe error in updateObjects: $e');
    });
  }

  void addObjectState(CanvasObject object) {
    // no objects with duplicate IDs
    if (!state.objects.contains(object)) {
      final updatedObjects = _sortObjects([...state.objects, object]);
      state = state.copyWith(objects: updatedObjects);
    }
  }

  void addObject(WidgetRef ref, CanvasObject object) {
    pipe(ref, () async {
      addObjectState(object);
      repository.add([object]);
    }).catchError((e, stack) {
      debugPrint('pipe error in addObject: $e');
    });
  }

  void addObjects(WidgetRef ref, List<CanvasObject> objects) {
    pipe(ref, () async {
      List<CanvasObject> currentObjects = List.from(state.objects);

      for (final obj in objects) {
        if (!currentObjects.contains(obj)) {
          currentObjects.add(obj);
        }
      }

      state = state.copyWith(objects: _sortObjects(currentObjects));
      repository.add(objects);
    }).catchError((e, stack) {
      debugPrint('pipe error in addObjects: $e');
    });
  }

  void deleteObject(WidgetRef ref, CanvasObject object) {
    pipe(ref, () async {
      final connectedArrows = state.objects
          .where((o) =>
              o.isArrow &&
              (o.arrowProps.startObjectId == object.id ||
                  o.arrowProps.endObjectId == object.id))
          .toList();

      final objectsToDelete = [object, ...connectedArrows];
      final deletedIds = objectsToDelete.map((o) => o.id).toSet();

      // Get the layer of the deleted object to adjust other objects
      final deletedLayers = objectsToDelete.map((o) => o.layer).toList();

      // Create updated objects list with adjusted layer numbers
      final updatedObjects =
          state.objects.where((o) => !deletedIds.contains(o.id)).map((o) {
        // If this object's layer is higher than any deleted object's layer,
        // decrease its layer number by 1 for each deleted object with lower layer
        int layerAdjustment =
            deletedLayers.where((layer) => layer < o.layer).length;
        if (layerAdjustment > 0) {
          o.layer = o.layer - layerAdjustment;
        }
        return o;
      }).toList();

      // Update state with adjusted objects
      state = state.copyWith(
        selectedObjects: [],
        objects: updatedObjects,
      );

      // Get the actual pins and delete them
      final pinsNotifier = ref.read(pinsProvider.notifier);
      final pinsToDelete = ref
          .read(pinsProvider)
          .pins
          .where((e) => e.pinnedObjectId == object.id)
          .toList();

      if (pinsToDelete.isNotEmpty) {
        pinsNotifier.deletePins(ref, pinsToDelete);
      }

      repository.deleteMultiple([object, ...connectedArrows]);
    }).catchError((e, stack) {
      debugPrint('pipe error in deleteObject: $e');
    });
  }

  void deleteObjects(WidgetRef ref, List<CanvasObject> objects) {
    if (objects.isEmpty) return;

    pipe(ref, () async {
      final connectedArrows = state.objects
          .where((o) =>
              o.isArrow &&
              (objects.any((obj) =>
                  o.arrowProps.startObjectId == obj.id ||
                  o.arrowProps.endObjectId == obj.id)))
          .toList();

      final allObjectsToDelete = [...objects, ...connectedArrows];
      final allDeletedIds = allObjectsToDelete.map((o) => o.id).toSet();

      final deletedLayers = allObjectsToDelete.map((o) => o.layer).toList();

      final updatedObjects =
          state.objects.where((o) => !allDeletedIds.contains(o.id)).map((o) {
        int layerAdjustment =
            deletedLayers.where((layer) => layer < o.layer).length;
        if (layerAdjustment > 0) {
          o.layer = o.layer - layerAdjustment;
        }
        return o;
      }).toList();

      state = state.copyWith(
        selectedObjects: [],
        objects: updatedObjects,
      );

      repository.deleteMultiple(allObjectsToDelete);
    }).catchError((e, stack) {
      debugPrint('pipe error in deleteObjects: $e');
    });
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

  // Arrange methods for layer manipulation
  void moveObjectForward(WidgetRef ref, CanvasObject object) {
    if (!canMoveForward(object)) return;

    final objects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    final index = objects.indexWhere((o) => o.id == object.id);
    if (index == -1) return;

    final nextObject = objects[index + 1];
    final tempLayer = object.layer;

    object.layer = nextObject.layer;
    nextObject.layer = tempLayer;

    updateObjects(ref, objects: [object, nextObject]);
  }

  void moveObjectBackward(WidgetRef ref, CanvasObject object) {
    if (!canMoveBackward(object)) return;

    final objects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    final index = objects.indexWhere((o) => o.id == object.id);
    if (index == -1) return;

    // Swap layers with the previous object in the same type
    final prevObject = objects[index - 1];
    final tempLayer = object.layer;

    object.layer = prevObject.layer;
    prevObject.layer = tempLayer;

    updateObjects(ref, objects: [object, prevObject]);
  }

  void moveObjectToFront(WidgetRef ref, CanvasObject object) {
    if (!canMoveForward(object)) return;

    final objects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    final index = objects.indexWhere((o) => o.id == object.id);
    if (index == -1) return;

    object.layer = nextLayer();
    updateObject(ref, object);
  }

  void moveObjectToBack(WidgetRef ref, CanvasObject object) {
    if (!canMoveBackward(object)) return;

    final objects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    final index = objects.indexWhere((o) => o.id == object.id);
    if (index == -1) return;

    object.layer = objects.first.layer - 1;
    updateObject(ref, object);
  }

  bool canMoveForward(CanvasObject object) {
    final sameTypeObjects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    if (sameTypeObjects.length <= 1) return false;

    return sameTypeObjects.last.id != object.id;
  }

  bool canMoveBackward(CanvasObject object) {
    final sameTypeObjects = List<CanvasObject>.from(state.objects)
        .where((o) => o.isArrow == object.isArrow)
        .toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));
    if (sameTypeObjects.length <= 1) return false;

    return sameTypeObjects.first.id != object.id;
  }

  Future<void> pipe(WidgetRef ref, Future<void> Function() operation) async {
    if (HistoryService.pipeActive) {
      await operation.call();
    } else {
      final projectId = ref.read(projectsProvider).selectedProject?.id;
      if (projectId == null) return;

      await HistoryService.pipe(
        ref: ref,
        projectId: projectId,
        operation: operation,
        serializer: CanvasSerializerService(
          canvasId: canvasId,
          projectId: projectId,
          repository: ArtifactsRepository(projectId: projectId),
        ),
      );
    }
  }
}
