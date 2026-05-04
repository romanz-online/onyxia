import 'package:onyxia/export.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import 'canvas_gesture_state.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';

/// Handles gestures for shape creation tools (rectangle, circle, etc.)
/// Implements create-and-resize behavior where dragging immediately resizes the created shape
class ShapeToolHandler extends CanvasToolGestureHandler {
  final CanvasObjectType shapeType;

  const ShapeToolHandler({required super.canvasConfig, required this.shapeType});

  @override
  ToolMode get toolMode => switch (shapeType) {
        CanvasObjectType.rectangle => ToolMode.rectangle,
        CanvasObjectType.diamond => ToolMode.diamond,
        CanvasObjectType.oblong => ToolMode.oblong,
        CanvasObjectType.circle => ToolMode.circle,
        CanvasObjectType.rhombus => ToolMode.rhombus,
        CanvasObjectType.trapezoid => ToolMode.trapezoid,
        CanvasObjectType.cylinder => ToolMode.cylinder,
        CanvasObjectType.house => ToolMode.house,
        CanvasObjectType.reverseHouse => ToolMode.reverseHouse,
        _ => ToolMode.rectangle,
      };

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(TapUpDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onTapUp =>
      (details, ref, buildContext, interactionContext) {
        if (interactionContext is ArrowWellInteraction || interactionContext is ObjectFillInteractionContext) {
          return;
        }

        const double spacing = CanvasBounds.gridSpacing;
        Offset topLeft = details.localPosition.translate(spacing * -5, spacing * -5);
        Offset bottomRight = details.localPosition.translate(spacing * 5, spacing * 5);
        if (ref.read(canvasSettingsProvider(Setting.snapToGrid))) {
          topLeft = ref.read(canvasBoundsProvider.notifier).snap(topLeft);
          bottomRight = ref.read(canvasBoundsProvider.notifier).snap(bottomRight);
        }

        final newObject = CanvasObject.initial().copyWith(
          id: const Uuid().v4(),
          layer: ref.read(canvasObjectsProvider.notifier).nextLayer(),
          color: ThemeHelper.neutral100(buildContext),
          type: shapeType,
          topLeft: topLeft,
          bottomRight: bottomRight,
        );

        ref.read(canvasObjectsProvider.notifier).addObject(ref, newObject);
        ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
        ref.read(canvasObjectsProvider.notifier).selectObject(newObject);
        print(7);
        ref.read(toolModeProvider.notifier).state = ToolMode.pointer;
        CanvasInteractionService.openTextEditor(ref: ref);
      };

  @override
  void Function(DragStartDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanStart =>
      (details, ref, buildContext, interactionContext) {
        if (interactionContext is ArrowWellInteraction || interactionContext is ObjectFillInteractionContext) {
          return;
        }

        const double spacing = CanvasBounds.gridSpacing;
        Offset topLeft = details.localPosition;
        Offset bottomRight = details.localPosition.translate(spacing, spacing);
        if (ref.read(canvasSettingsProvider(Setting.snapToGrid))) {
          topLeft = ref.read(canvasBoundsProvider.notifier).snap(topLeft);
          bottomRight = ref.read(canvasBoundsProvider.notifier).snap(bottomRight);
        }

        final newObject = CanvasObject.initial().copyWith(
          id: const Uuid().v4(),
          layer: ref.read(canvasObjectsProvider.notifier).nextLayer(),
          color: ThemeHelper.neutral100(buildContext),
          type: shapeType,
          topLeft: topLeft,
          bottomRight: bottomRight,
        );

        ref.read(canvasObjectsProvider.notifier).addObject(ref, newObject);
        ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
        ref.read(canvasObjectsProvider.notifier).selectObject(newObject);
        ref.read(canvasGestureStateProvider.notifier).setActiveObject(newObject);
      };

  @override
  void Function(DragUpdateDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanUpdate =>
      (details, ref, buildContext, interactionContext) {
        final activeObject = ref.read(canvasGestureStateProvider).activeObject;
        if (activeObject == null) return;

        final position = ref.read(canvasSettingsProvider(Setting.snapToGrid))
            ? ref.read(canvasBoundsProvider.notifier).snap(details.localPosition)
            : details.localPosition;

        activeObject.bottomRight = Offset(
          math.max(activeObject.topLeft.dx + 10, position.dx),
          math.max(activeObject.topLeft.dy + 10, position.dy),
        );

        ref.read(canvasObjectsProvider.notifier).updateObjectState(activeObject);
        ref.read(canvasGestureStateProvider.notifier).setActiveObject(activeObject);
      };

  @override
  void Function(DragEndDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanEnd =>
      (details, ref, buildContext, interactionContext) {
        final activeObject = ref.read(canvasGestureStateProvider).activeObject;

        if (activeObject != null) {
          ref.read(canvasObjectsProvider.notifier).updateObject(ref, activeObject);
          ref.read(canvasObjectsProvider.notifier).selectObject(activeObject);
          ref.read(toolModeProvider.notifier).state = ToolMode.pointer;
          CanvasInteractionService.openTextEditor(ref: ref);
        }

        ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
      };
}
