import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_gesture_state.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';
import '../widgets/canvas_right_click_menu.dart';

/// Handles gestures when pointer tool is active
/// Responsible for object selection, movement, and drag selection
class PointerToolBehavior extends CanvasToolGestureHandler {
  PointerToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => ToolMode.pointer;

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(TapUpDetails, WidgetRef, BuildContext,
      CanvasInteractionContext)? get onTapUp => (details, ref, buildContext,
          interactionContext) {
        switch (interactionContext) {
          case ArrowToolWellInteraction():
            break;
          case ArrowWellInteraction(
              :final sourceObject,
              :final connectionPoint
            ):
            ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
            ArrowInteractionService.autoCompleteArrow(
                sourceObject, connectionPoint, ref, buildContext);
            break;
          case ArrowTextInteraction(targetObject: final targetObject):
          case ObjectResizeInteraction(:final targetObject):
          case ArrowResizeInteraction(:final targetObject):
          case ArrowMoveInteraction(:final targetObject):
          case ObjectFillInteractionContext(:final targetObject):
            _canvasObjectTapUp(targetObject, ref);
            break;
          case BackgroundInteraction():
            ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
            ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
            break;
        }
      };

  @override
  void Function(
          DragStartDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanStart => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ArrowWellInteraction(
                  :final sourceObject,
                  :final connectionPoint
                ):
                final arrow = ArrowInteractionService.startArrowWellPan(
                  details,
                  sourceObject,
                  connectionPoint,
                  ref,
                  buildContext,
                  canvasConfig,
                );
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(arrow);
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setArrowMoveType(ArrowMoveType.end);
                break;
              case ObjectResizeInteraction(:final targetObject, :final handle):
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(targetObject);
                _startObjectResize(
                    details.localPosition, targetObject, handle, ref);
                break;
              case ArrowResizeInteraction(
                  :final targetObject,
                  :final segmentIndex
                ):
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(targetObject);
                _startArrowResize(details, targetObject, segmentIndex, ref);
                break;
              case ArrowMoveInteraction(:final targetObject, :final moveType):
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(targetObject);
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setArrowMoveType(moveType);
                ref
                    .read(canvasObjectsProvider.notifier)
                    .selectObject(targetObject);
                break;
              case ObjectFillInteractionContext(:final targetObject):
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(targetObject);
                _startObjectMovePan(details.localPosition, targetObject, ref);
                break;
              case BackgroundInteraction():
                ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
                ref
                    .read(dragSelectProvider.notifier)
                    .startDragSelect(details.localPosition);
                break;
              case _:
                break;
            }
          };

  @override
  void Function(
          DragUpdateDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanUpdate => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ArrowTextInteraction(targetObject: final arrowObject):
                _handleArrowTextDrag(details, arrowObject, ref);
                break;
              case ArrowWellInteraction():
                ArrowInteractionService.updateArrowPan(
                  details,
                  ref,
                  ref.read(canvasGestureStateProvider).activeObject,
                );
                break;
              case ObjectResizeInteraction(:final targetObject, :final handle):
                _updateObjectResizePan(details, targetObject, handle, ref);
                break;
              case ArrowResizeInteraction(
                  :final targetObject,
                  :final segmentIndex
                ):
                _handleArrowResize(details, targetObject, segmentIndex, ref);
                break;
              case ArrowMoveInteraction(:final targetObject, :final moveType):
                ArrowInteractionService.updateArrowPan(
                    details, ref, targetObject,
                    part: moveType);
                break;
              case ObjectFillInteractionContext():
                _updateObjectMovePan(details, ref);
                break;
              case BackgroundInteraction():
                ref
                    .read(dragSelectProvider.notifier)
                    .updateDragSelect(details.localPosition);
                break;
              case _:
                break;
            }
          };

  @override
  void Function(
          DragEndDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanEnd => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ArrowWellInteraction():
                ArrowInteractionService.endArrowPan(
                  details,
                  ref,
                  ref.read(canvasGestureStateProvider).activeObject,
                  true,
                  canvasConfig,
                );
                break;
              case ArrowMoveInteraction():
                ArrowInteractionService.endArrowPan(
                  details,
                  ref,
                  ref.read(canvasGestureStateProvider).activeObject,
                  false,
                  canvasConfig,
                );
                break;
              case ArrowTextInteraction(targetObject: final arrowObject):
                _handleArrowTextDragEnd(details, arrowObject, ref);
                break;
              case ObjectResizeInteraction(:final targetObject):
                _endObjectResizePan(details, targetObject, ref);
                break;
              case ArrowResizeInteraction(:final targetObject):
                _handleArrowResizeEnd(details, targetObject, ref);
                break;
              case ObjectFillInteractionContext():
                _endObjectMovePan(details, ref);
                break;
              case BackgroundInteraction():
                ref.read(dragSelectProvider.notifier).endDragSelect();
                break;
              case _:
                break;
            }

            if (interactionContext is ArrowWellInteraction ||
                interactionContext is ArrowMoveInteraction) {
              // do this without resetInteraction so that the headless arrow palette doesn't automatically close
            } else {
              ref
                  .read(canvasGestureStateProvider.notifier)
                  .resetInteraction(ref);
            }
          };

  @override
  void Function(
          TapDownDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onSecondaryTapDown =>
          (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ObjectFillInteractionContext(:final targetObject):
                canvasRightClick(
                  buildContext,
                  canvasConfig.allowArtifactsOnBackground, // isMarkup
                  details.globalPosition,
                  details.localPosition,
                  ref,
                  clickedObj: targetObject,
                );
                break;
              case BackgroundInteraction():
                canvasRightClick(
                  buildContext,
                  canvasConfig.allowArtifactsOnBackground, // isMarkup
                  details.globalPosition,
                  details.localPosition,
                  ref,
                  clickedObj: null,
                );
              case _:
                break;
            }
          };

  @override
  void Function(
          PointerHoverEvent, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onHover => (event, ref, buildContext, interactionContext) {
            final cursorNotifier =
                ref.read(cursorIconOverrideProvider.notifier);
            final selectedObjects =
                ref.read(canvasObjectsProvider).selectedObjects;

            switch (interactionContext) {
              case ObjectResizeInteraction(:final targetObject, :final handle):
                if (selectedObjects.contains(targetObject)) {
                  final cursor = switch (handle) {
                    ResizeHandle.topLeft ||
                    ResizeHandle.bottomRight =>
                      SystemMouseCursors.resizeUpLeftDownRight,
                    ResizeHandle.topRight ||
                    ResizeHandle.bottomLeft =>
                      SystemMouseCursors.resizeUpRightDownLeft,
                    ResizeHandle.topCenter ||
                    ResizeHandle.bottomCenter =>
                      SystemMouseCursors.resizeUpDown,
                    ResizeHandle.centerLeft ||
                    ResizeHandle.centerRight =>
                      SystemMouseCursors.resizeLeftRight,
                    _ => SystemMouseCursors.move,
                  };
                  cursorNotifier.setCursor(cursor);
                }
                break;
              case ObjectFillInteractionContext(:final targetObject):
                if (selectedObjects.contains(targetObject) &&
                    !targetObject.isBrush &&
                    !targetObject.isArrow) {
                  cursorNotifier.setCursor(SystemMouseCursors.grab);
                }
                break;
              case ArrowWellInteraction():
                cursorNotifier.setCursor(SystemMouseCursors.grab);
                break;
              default:
                cursorNotifier.setCursor(null);
            }
          };

  void _canvasObjectTapUp(CanvasObject? object, WidgetRef ref) {
    if (object == null) return;

    if (CanvasInteractionService.isModifierPressed()) {
      if (ref.read(canvasObjectsProvider).selectedObjects.contains(object)) {
        ref.read(canvasObjectsProvider.notifier).deselectObject(object);
      } else {
        ref.read(canvasObjectsProvider.notifier).selectObject(object);
      }
    } else {
      final wasSelected =
          ref.read(canvasObjectsProvider).selectedObjects.contains(object);
      ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
      ref.read(canvasObjectsProvider.notifier).selectObject(object);
      if (!object.isImage && !object.isArrow && !object.isBrush) {
        if (!wasSelected) {
          CanvasInteractionService.closeTextEditor(ref: ref);
        } else {
          if (ref.read(canvasTextProvider.notifier).isEditing) {
            CanvasInteractionService.closeTextEditor(ref: ref);
          } else {
            CanvasInteractionService.openTextEditor(ref: ref);
          }
        }
      }
    }
  }

  void _startObjectMovePan(
      Offset position, CanvasObject object, WidgetRef ref) {
    if (object.isArrow) return;

    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);

    if (!CanvasInteractionService.isModifierPressed()) {
      // clear selected objects if not holding Ctrl
      objectsNotifier.clearSelectedObjects();
    }

    // Select this object if it's not already selected
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(object)) {
      objectsNotifier.selectObject(object);
    }

    // set all currently selected objects are being dragged
    final draggedObjectsNotifier = ref.read(draggedObjectsProvider.notifier);
    if (!draggedObjectsNotifier.draggedObjects.contains(object)) {
      draggedObjectsNotifier.setDraggedObjects(
        ref.read(canvasObjectsProvider).selectedObjects,
      );
    }
  }

  void _updateObjectMovePan(DragUpdateDetails details, WidgetRef ref) {
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    if (selectedObjects.length == 1 && selectedObjects.first.isArrow) return;

    ref
        .read(canvasGestureStateProvider.notifier)
        .updateAccumulatedDelta(details.delta);
    final gridDelta = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? ref
            .read(canvasBoundsProvider.notifier)
            .snap(ref.read(canvasGestureStateProvider).accumulatedDelta)
        : ref.read(canvasGestureStateProvider).accumulatedDelta;
    final deltaToUse = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? gridDelta
        : details.delta;

    if (deltaToUse != Offset.zero) {
      // Get movement constraints for all selected objects
      List<Map<String, bool>> allConstraints = selectedObjects
          .map((obj) => obj.getMovementConstraints(ref, deltaToUse))
          .toList();

      // Calculate which directions ALL objects can move
      bool allCanMoveUp = deltaToUse.dy < 0
          ? allConstraints
              .every((constraints) => constraints['canMoveUp'] == true)
          : true;
      bool allCanMoveDown = deltaToUse.dy > 0
          ? allConstraints
              .every((constraints) => constraints['canMoveDown'] == true)
          : true;
      bool allCanMoveLeft = deltaToUse.dx < 0
          ? allConstraints
              .every((constraints) => constraints['canMoveLeft'] == true)
          : true;
      bool allCanMoveRight = deltaToUse.dx > 0
          ? allConstraints
              .every((constraints) => constraints['canMoveRight'] == true)
          : true;

      // Create constrained delta based on allowed directions
      final constrainedDelta = Offset(
        // Horizontal movement: only apply dx if movement direction is allowed
        (deltaToUse.dx > 0 && allCanMoveRight) ||
                (deltaToUse.dx < 0 && allCanMoveLeft)
            ? deltaToUse.dx
            : 0,
        // Vertical movement: only apply dy if movement direction is allowed
        (deltaToUse.dy > 0 && allCanMoveDown) ||
                (deltaToUse.dy < 0 && allCanMoveUp)
            ? deltaToUse.dy
            : 0,
      );

      // Apply movement if there's any allowed movement
      if (constrainedDelta != Offset.zero) {
        for (final obj in selectedObjects) {
          obj.handleMove(ref, constrainedDelta);
        }

        // Update connected arrows if needed
        List<CanvasObject> objectsToUpdate = [...selectedObjects];

        for (final selectedObj in selectedObjects.where((e) => !e.isArrow)) {
          for (final arrow in ref
              .read(canvasObjectsProvider)
              .objects
              .where((e) => e.isArrow)) {
            arrow.adjustPointsToObject(selectedObj);
            if (!objectsToUpdate.contains(arrow)) {
              objectsToUpdate.add(arrow);
            }

            {
              // check start object
              final obj = arrow.getStartObject(ref);
              if (obj != null && !selectedObjects.contains(obj)) {
                arrow.adjustPointsToObject(obj);
                objectsToUpdate.add(obj);
              }
            }

            {
              // check end object
              final obj = arrow.getEndObject(ref);
              if (obj != null && !selectedObjects.contains(obj)) {
                arrow.adjustPointsToObject(obj);
                objectsToUpdate.add(obj);
              }
            }
          }
        }

        ref
            .read(canvasObjectsProvider.notifier)
            .updateObjectsState(objectsToUpdate);
        ref
            .read(canvasGestureStateProvider.notifier)
            .updateAccumulatedDelta(-gridDelta);
      }
    }
  }

  void _endObjectMovePan(DragEndDetails details, WidgetRef ref) {
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;
    if (selectedObjects.length == 1 && selectedObjects.first.isArrow) return;

    ref.read(draggedObjectsProvider.notifier).clearDraggedObjects();
    ref.invalidate(draggedObjectsProvider); // forces a state update
    _pruneArrowKeypoints(ref);
    ref.read(canvasObjectsProvider.notifier).updateObjects();
  }

  void _updateObjectResizePan(
    DragUpdateDetails details,
    CanvasObject object,
    ResizeHandle handle,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(object))
      return;

    ref
        .read(canvasGestureStateProvider.notifier)
        .updateAccumulatedDelta(details.delta);
    final gridDelta = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? ref
            .read(canvasBoundsProvider.notifier)
            .snap(ref.read(canvasGestureStateProvider).accumulatedDelta)
        : ref.read(canvasGestureStateProvider).accumulatedDelta;
    final deltaToUse = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? gridDelta
        : details.delta;

    if (deltaToUse != Offset.zero) {
      // Perform the resize operation
      object.handleResize(ref, deltaToUse, handle);

      // Update connected arrows if needed
      List<CanvasObject> objectsToUpdate = [object];

      for (final arrow
          in ref.read(canvasObjectsProvider).objects.where((e) => e.isArrow)) {
        arrow.adjustPointsToObject(object);
        objectsToUpdate.add(arrow);
      }

      ref
          .read(canvasObjectsProvider.notifier)
          .updateObjectsState(objectsToUpdate);
      ref
          .read(canvasGestureStateProvider.notifier)
          .updateAccumulatedDelta(-gridDelta);
    }
  }

  void _endObjectResizePan(
    DragEndDetails details,
    CanvasObject object,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(object))
      return;

    ref.read(draggedObjectsProvider.notifier).clearDraggedObjects();
    ref.invalidate(draggedObjectsProvider); // forces a state update
    _pruneArrowKeypoints(ref);
    ref.read(canvasObjectsProvider.notifier).updateObjects();
  }

  void _startArrowResize(
    DragStartDetails details,
    CanvasObject arrow,
    int segmentIndex,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(arrow))
      return;

    ref
        .read(canvasGestureStateProvider.notifier)
        .setArrowSegmentIndex(segmentIndex);
  }

  void _handleArrowResize(
    DragUpdateDetails details,
    CanvasObject arrow,
    int segmentIndex,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(arrow))
      return;

    if (ref.read(canvasGestureStateProvider).arrowSegmentIndex == null) {
      ref
          .read(canvasGestureStateProvider.notifier)
          .setArrowSegmentIndex(segmentIndex);
    }

    ref
        .read(canvasGestureStateProvider.notifier)
        .updateAccumulatedDelta(details.delta);
    final gridDelta = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? ref
            .read(canvasBoundsProvider.notifier)
            .snap(ref.read(canvasGestureStateProvider).accumulatedDelta)
        : ref.read(canvasGestureStateProvider).accumulatedDelta;
    final deltaToUse = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? gridDelta
        : details.delta;

    if (deltaToUse != Offset.zero) {
      final newSegmentCreated = arrow.handleResize(
        ref,
        deltaToUse,
        ResizeHandle.arrow,
        arrowKeypointIndex:
            ref.read(canvasGestureStateProvider).arrowSegmentIndex ?? 0,
      );

      if (newSegmentCreated) {
        if (ref.read(canvasGestureStateProvider).arrowSegmentIndex == 0) {
          // need to shift up the index if a segment was created at the start
          // otherwise the wrong segment is referenced
          ref.read(canvasGestureStateProvider.notifier).setArrowSegmentIndex(2);
        }
      }

      arrow.updateArrowBounds();
      ref.read(canvasObjectsProvider.notifier).updateObjectState(arrow);

      if (ref.read(canvasSettingsProvider(Setting.snapToGrid))) {
        ref
            .read(canvasGestureStateProvider.notifier)
            .updateAccumulatedDelta(-gridDelta);
      }
    }
  }

  void _handleArrowResizeEnd(
    DragEndDetails details,
    CanvasObject arrow,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(arrow))
      return;

    arrow.pruneKeypoints();
    arrow.updateArrowBounds();
    ref.read(canvasObjectsProvider.notifier).updateObjects();
  }

  void _handleArrowTextDrag(
    DragUpdateDetails details,
    CanvasObject arrow,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(arrow))
      return;

    arrow.updateTextPosition(ref
        .read(canvasViewportProvider.notifier)
        .convertToCanvasCoords(details.globalPosition));
    ref.read(canvasObjectsProvider.notifier).updateObjectState(arrow);
  }

  void _handleArrowTextDragEnd(
    DragEndDetails details,
    CanvasObject arrow,
    WidgetRef ref,
  ) {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(arrow))
      return;

    ref.read(canvasObjectsProvider.notifier).updateObject(arrow);
  }

  void _startObjectResize(
    Offset position,
    CanvasObject object,
    ResizeHandle handle,
    WidgetRef ref,
  ) {
    if (object.isArrow) return;

    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);

    // Select this object if it's not already selected
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(object)) {
      objectsNotifier.selectObject(object);
    }

    // Initialize resize operation
    ref.read(canvasGestureStateProvider.notifier).resetAccumulatedDelta();
  }

  void _pruneArrowKeypoints(WidgetRef ref) {
    for (final obj
        in ref.read(canvasObjectsProvider).objects.where((e) => e.isArrow)) {
      obj.pruneKeypoints();
    }
  }
}
