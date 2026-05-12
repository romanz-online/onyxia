import 'package:flutter/cupertino.dart';
import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/canvas_engine/utils/image_drag_data.dart';
import '../providers/providers.dart';
import 'clipboard_service.dart';

/// Service responsible for handling all canvas interactions
/// Provides centralized interaction logic for both whiteboard and markup screens
class CanvasInteractionService {
  /// Saves changes to canvas title
  static void saveTitleChanges({
    required WidgetRef ref,
    required TextEditingController titleController,
    required VoidCallback onEditingComplete,
  }) {
    onEditingComplete();
    final currentCanvas = ref.read(currentCanvasProvider);
    if (currentCanvas != null) {
      final oldTitle = currentCanvas.name;
      final newTitle = titleController.text.trim();
      if (newTitle.isNotEmpty && newTitle != oldTitle) {
        ArtifactsRepository(
          projectId: ref.read(projectsProvider).selectedProject?.id,
        ).update(currentCanvas.copyWith(name: newTitle));
      } else {
        titleController.text = oldTitle;
      }
    }
  }

  /// Handles keyboard events for canvas interactions
  static Future<bool> handleKeyEvent({
    required KeyEvent event,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    // Prevent handler execution if widget is being disposed
    if (!context.mounted) return false;

    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final isTyping = isFocusingText(context: context, ref: ref);
      final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
      final objects = ref.read(canvasObjectsProvider).objects;
      final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;
      final isModifierPressed = CanvasInteractionService.isModifierPressed();

      // Zoom In (= key is the same as + key. don't account for shift here)
      if (isModifierPressed && key == LogicalKeyboardKey.equal) {
        ref.read(canvasViewportProvider.notifier).updateZoom(increment: 0.1);
        return true;
      }

      // Zoom Out
      if (isModifierPressed && key == LogicalKeyboardKey.minus) {
        ref.read(canvasViewportProvider.notifier).updateZoom(increment: -0.1);
        return true;
      }

      // Enter (start editing selected object)
      if (!isTyping && key == LogicalKeyboardKey.enter) {
        openTextEditor(ref: ref);
        return true;
      }

      if (key == LogicalKeyboardKey.escape) {
        objectsNotifier.clearSelectedObjects();
        closeTextEditor(ref: ref);
        return true;
      }

      if (isTyping) return false;

      // Reset Viewport
      if (key == LogicalKeyboardKey.space) {
        ref.read(canvasViewportProvider.notifier).reset();
        return true;
      }

      // Select All
      if (isModifierPressed && key == LogicalKeyboardKey.keyA) {
        objectsNotifier.selectObjects(objects);
        return true;
      }

      if (key == LogicalKeyboardKey.escape) {
        objectsNotifier.clearSelectedObjects();
        closePin(ref: ref);
        closeHeadlessPalette(ref: ref);
        clearTemporaryComment(ref: ref);
        return true;
      }

      // Shift (grid-snapping)
      if (key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        ref.read(canvasSettingsProvider(Setting.snapToGrid).notifier).toggle();
        return true;
      }

      // Undo/Redo functionality (works for both markup and whiteboard)
      if (isModifierPressed && key == LogicalKeyboardKey.keyZ) {
        final shiftPressed = HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.shiftLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.shiftRight);

        // ref.read(canvasDiffPreviewProvider.notifier).clearPreview();

        if (shiftPressed) {
          // Ctrl+Shift+Z = Redo
          performRedo(ref: ref);
        } else {
          // Ctrl+Z = Undo
          performUndo(ref: ref);
        }
        return true;
      }

      // Paste
      if (isModifierPressed && key == LogicalKeyboardKey.keyV) {
        final targetPosition =
            ref.read(canvasViewportProvider.notifier).getViewportCenter();
        final pasted = await CanvasClipboardService.paste(
            targetPosition: targetPosition, ref: ref);

        objectsNotifier.addObjects(ref, pasted.$1);
        objectsNotifier.clearSelectedObjects();
        ref.read(pinsProvider.notifier).addPins(ref, pasted.$2);
        return true;
      }

      // Backspace/Delete
      if (key == LogicalKeyboardKey.delete ||
          key == LogicalKeyboardKey.backspace) {
        objectsNotifier.deleteObjects(ref, selectedObjects);
        return true;
      }

      // Copy
      if (isModifierPressed && key == LogicalKeyboardKey.keyC) {
        await CanvasClipboardService.copy(objects: selectedObjects);
        return true;
      }

      // Cut
      if (isModifierPressed && key == LogicalKeyboardKey.keyX) {
        await CanvasClipboardService.copy(objects: selectedObjects);
        objectsNotifier.deleteObjects(ref, selectedObjects);
        return true;
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        ref.read(canvasSettingsProvider(Setting.snapToGrid).notifier).toggle();
      }
    }

    return false;
  }

  /// Checks if currently focusing on a text input widget
  static bool isFocusingText(
      {required BuildContext context, required WidgetRef ref}) {
    // Check if this widget is still mounted before proceeding
    if (!context.mounted) return false;

    final FocusNode? focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null) return false;

    // Check if the focused widget is a text editing widget
    final BuildContext? focusContext = focusedNode.context;
    if (focusContext == null) return false;

    // Ensure the context is still active before traversing the widget tree
    bool contextIsActive = false;
    try {
      // This will throw if the context is not active
      contextIsActive = focusContext.mounted;
    } catch (e) {
      // Context is deactivated, return false safely
      return false;
    }

    if (!contextIsActive) return false;

    // Look up the widget tree to find text editing widgets
    bool isTextWidget = false;
    try {
      focusContext.visitAncestorElements((element) {
        final widget = element.widget;
        if (widget is TextField ||
            widget is TextFormField ||
            widget is EditableText ||
            widget is CupertinoTextField) {
          isTextWidget = true;
          return false;
        }
        return true;
      });
    } catch (e) {
      // If ancestor lookup fails, assume not a text widget
      isTextWidget = false;
    }

    return isTextWidget ||
        (context.mounted && ref.read(canvasTextProvider.notifier).hasFocus) ||
        (context.mounted &&
            ref.read(selectedNoteStateProvider.notifier).hasFocus) ||
        (context.mounted && ref.read(expandedPinProvider.notifier).hasFocus);
  }

  /// Checks if modifier keys (Ctrl/Cmd) are currently pressed
  static bool isModifierPressed() {
    final ctrlPressed = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlRight);

    final metaPressed = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.metaRight);

    return ctrlPressed || metaPressed;
  }

  static void openTextEditor({required WidgetRef ref}) {
    closeTextEditor(ref: ref);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;
    if (selectedObjects.length == 1 &&
        !selectedObjects[0].isBrush &&
        !selectedObjects[0].isArtifact &&
        !selectedObjects[0].isImage) {
      ref.read(canvasTextProvider.notifier).startEditing(
            selectedObjects[0].content,
            selectedObjects[0].id,
          );
    }
  }

  static void closeTextEditor({required WidgetRef ref}) {
    final textNotifier = ref.read(canvasTextProvider.notifier);

    if (textNotifier.isEditing) {
      final textProvider = ref.read(canvasTextProvider);
      final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
      final object = objectsNotifier.getObjectById(textProvider.editingObjId);
      if (object.id.isNotEmpty && object.type == CanvasObjectType.text) {
        object.content = textNotifier.text;
        if (object.isContentEmpty) {
          // automatically delete text objects with no text
          objectsNotifier.deleteObject(ref, object);
        } else {
          objectsNotifier.updateObject(ref, object);
        }
      }
      textNotifier.stopEditing();
    }
  }

  static void closePin({required WidgetRef ref}) {
    ref.read(expandedPinProvider.notifier).collapsePin();
  }

  /// Clears temporary comment state
  static void clearTemporaryComment({required WidgetRef ref}) {
    ref.read(commentsProvider.notifier).clearTemporaryComment();
  }

  static Future<void> pipeHistory({
    required WidgetRef ref,
    required Future<void> Function() operation,
  }) async {
    final projectId = ref.read(projectsProvider).selectedProject?.id;
    if (projectId == null) return;
    await HistoryService.pipe(
      ref: ref,
      projectId: projectId,
      operation: operation,
      serializer: CanvasSerializerService(
        canvasId: ref.read(currentCanvasProvider)?.id ?? '',
        projectId: projectId,
        repository: ArtifactsRepository(
          projectId: projectId,
        ),
      ),
    );
  }

  static void performUndo({required WidgetRef ref}) async {
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    final projectId = ref.read(projectsProvider).selectedProject?.id;
    if (projectId == null) return;
    // try {
    //   final params = HistoryDiffsParams(
    //     projectId: projectId,
    //     itemId: ref.read(currentCanvasProvider)?.id ?? '',
    //     itemType: ArtifactType.canvas,
    //   );
    //   if (await ref.read(historyDiffsProvider(params).notifier).undo()) {
    //     await _applyCurrentDiffState(ref: ref);
    //   }
    // } catch (e) {
    //   debugPrint('Error in undo: $e');
    // }
  }

  static void performRedo({required WidgetRef ref}) async {
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    final projectId = ref.read(projectsProvider).selectedProject?.id;
    if (projectId == null) return;
    // try {
    //   final params = HistoryDiffsParams(
    //     projectId: projectId,
    //     itemId: ref.read(currentCanvasProvider)?.id ?? '',
    //     itemType: ArtifactType.canvas,
    //   );
    //   if (await ref.read(historyDiffsProvider(params).notifier).redo()) {
    //     await _applyCurrentDiffState(ref: ref);
    //   }
    // } catch (e) {
    //   debugPrint('Error in redo: $e');
    // }
  }

  // static Future<void> _applyCurrentDiffState({required WidgetRef ref}) async {
  //   try {
  //     final projectId = ref.read(projectsProvider).selectedProject?.id;
  //     if (projectId == null) return;
  //     final canvasId = ref.read(currentCanvasProvider)?.id ?? '';

  //     final serializer = CanvasSerializerService(
  //       canvasId: canvasId,
  //       projectId: projectId,
  //       repository: ArtifactsRepository(projectId: projectId),
  //     );

  //     final params = HistoryDiffsParams(
  //       projectId: projectId,
  //       itemId: canvasId,
  //       itemType: ArtifactType.canvas,
  //     );
  //     final diff = ref.read(historyDiffsProvider(params)).currentDiff;

  //     if (diff == null) throw Exception('currentDiff is null');

  //     // Reconstruct canvas state from current diff position
  //     final reconstructedState = HistoryService.reconstructState(
  //       ref: ref,
  //       targetDiff: diff,
  //       serializer: serializer,
  //     );

  //     // Apply the reconstructed state to canvas without creating new diff
  //     await serializer.deserialize(reconstructedState);
  //   } catch (e) {
  //     debugPrint('Failed to apply diff state: $e');
  //     rethrow;
  //   }
  // }

  static void closeHeadlessPalette({required WidgetRef ref}) {
    if (ref.read(headlessProvider).headlessArrow != null) {
      if (ref.read(headlessProvider).headlessArrow!.arrowProps.endPoint ==
          ConnectionPoint.none) {
        ref
            .read(canvasObjectsProvider.notifier)
            .deleteObject(ref, ref.read(headlessProvider).headlessArrow!);
      }
    }
    ref.read(headlessProvider.notifier).hidePalette();
  }

  static Future<void> insertImage({
    required WidgetRef ref,
    required ImageDragData data,
    required Offset canvasPosition,
  }) async {
    try {
      final image = await ImageService.getImage(data.imageUrl);
      if (image == null) {
        throw Exception('Failed to load dragged image');
      }

      final objectsNotifier = ref.read(canvasObjectsProvider.notifier);

      final newObj = CanvasObject(
        id: const Uuid().v4(),
        topLeft: canvasPosition,
        bottomRight: Offset(
          canvasPosition.dx + image.width,
          canvasPosition.dy + image.height,
        ),
        type: CanvasObjectType.image,
        layer: objectsNotifier.nextLayer(),
        imageProperties: ImageProperties(imageUrl: data.imageUrl),
      );

      // Center the image at the drop position
      final size = newObj.getDimensions();
      newObj.topLeft = Offset(
        canvasPosition.dx - size.width / 2,
        canvasPosition.dy - size.height / 2,
      );
      newObj.bottomRight = Offset(
        canvasPosition.dx + size.width / 2,
        canvasPosition.dy + size.height / 2,
      );

      objectsNotifier.addObject(ref, newObj);
      objectsNotifier.clearSelectedObjects();
      objectsNotifier.selectObject(newObj);

      NarwhalToast.show(
        text: 'Image added to canvas',
        type: ToastType.success,
      );
    } catch (e) {
      debugPrint('Error processing dragged image: $e');
      NarwhalToast.show(
        text: 'Failed to add image: $e',
        type: ToastType.error,
      );
    }
  }

  static Future<void> createPin({
    required WidgetRef ref,
    required Offset position,
    Artifact? item,
    CanvasObject? targetObject,
  }) async {
    Offset finalPosition = position;

    if (targetObject != null) {
      if (targetObject.isArrow) {
        // Arrow positioning: store as percentage along arrow path (0.0-1.0)
        final arrowPoints = targetObject.arrowProps.points;
        final pathPercentage =
            ArrowPathHelper.getPercentageAtPoint(arrowPoints, position);
        finalPosition = Offset(pathPercentage, 0.0);
      } else {
        // Regular object positioning: relative positioning (0.0-1.0)
        Size objSize = targetObject.getDimensions();
        finalPosition = Offset(
          (position.dx - targetObject.topLeft.dx) / objSize.width,
          (position.dy - targetObject.topLeft.dy) / objSize.height,
        );
      }
    }

    final pin = Pin(
      id: Uuid().v4(),
      linkedArtifactId: item?.id ?? '',
      canvasId: ref.read(currentCanvasProvider)?.id ?? '',
      position: finalPosition,
      pinnedObjectId: targetObject?.id,
    );

    // Expand pin BEFORE pipeHistory to avoid widget disposal issues
    if (item == null) {
      // expand and select the pin immediately for new pins
      // the pin will enter edit mode
      try {
        ref.read(expandedPinProvider.notifier).expandPin(pin);
      } catch (e) {
        // Continue with pin creation even if expansion fails
        debugPrint('Error expanding pin: $e');
      }
    }

    try {
      ref.read(pinsProvider.notifier).addPin(ref, pin);
    } catch (e) {
      debugPrint('Error in pipeHistory during pin creation: $e');
      rethrow;
    }

    ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
  }

  static Future<void> createArtifactObject({
    required WidgetRef ref,
    required Offset position,
    required Artifact? artifact,
  }) async {
    position = ref.read(canvasBoundsProvider.notifier).snap(position);
    final newObj = CanvasObject(
      id: const Uuid().v4(),
      color: Colors.transparent,
      topLeft: Offset(
        position.dx - defaultArtifactObjectDimensions.width / 2,
        position.dy - defaultArtifactObjectDimensions.height / 2,
      ),
      bottomRight: Offset(
        position.dx + defaultArtifactObjectDimensions.width / 2,
        position.dy + defaultArtifactObjectDimensions.height / 2,
      ),
      type: CanvasObjectType.artifact,
      layer: ref.read(canvasObjectsProvider.notifier).nextLayer(),
      artifactProperties: ArtifactProperties(artifactId: artifact?.id ?? ''),
    );
    // TODO: null artifact should create a note?

    try {
      ref.read(canvasObjectsProvider.notifier).addObject(ref, newObj);
    } catch (e) {
      debugPrint('Error in pipeHistory during pin creation: $e');
      rethrow;
    }

    ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
  }

  static Future<void> deletePin({
    required WidgetRef ref,
    required Pin pin,
    CanvasObject? parentObject,
  }) async {
    // this is a new pin that was never saved - remove it entirely
    ref.read(expandedPinProvider.notifier).collapsePin();
    ref.read(pinsProvider.notifier).deletePin(ref, pin);
  }

  /// Deletes a comment and all its sub-comments
  static Future<void> deleteComment({
    required WidgetRef ref,
    required String commentId,
  }) async {
    try {
      await ref
          .read(commentsProvider.notifier)
          .deleteComment(commentId: commentId);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Creates a comment pin at the specified position
  /// Automatically detects and attaches to canvas objects if position intersects with one
  static Future<void> createComment({
    required WidgetRef ref,
    required Offset position,
    CanvasObject? targetObject,
  }) async {
    Offset finalPosition = position;

    if (targetObject != null) {
      if (targetObject.isArrow) {
        // Arrow positioning: store as percentage along arrow path (0.0-1.0)
        final arrowPoints = targetObject.arrowProps.points;
        final pathPercentage =
            ArrowPathHelper.getPercentageAtPoint(arrowPoints, position);
        finalPosition = Offset(pathPercentage, 0.0);
      } else {
        // Regular object positioning: relative positioning (0.0-1.0)
        Size objSize = targetObject.getDimensions();
        finalPosition = Offset(
          (position.dx - targetObject.topLeft.dx) / objSize.width,
          (position.dy - targetObject.topLeft.dy) / objSize.height,
        );
      }
    }

    final commentId = const Uuid().v4();

    ref.read(commentsProvider.notifier).createTemporaryComment(
          commentId: commentId,
          position: finalPosition,
          objectId: targetObject?.id,
          pinnedObjectId: targetObject?.id,
        );

    ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
  }
}
