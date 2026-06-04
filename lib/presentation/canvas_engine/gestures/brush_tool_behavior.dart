import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_gesture_state.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../utils/colors.dart';

/// Handles gestures for brush/freehand drawing tool
/// Creates stroke objects by tracking pan gestures
class BrushToolBehavior extends CanvasToolGestureHandler {
  const BrushToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => .brush;

  @override
  bool get allowsViewportPanning => false;

  @override
  void Function(
    DragStartDetails,
    WidgetRef,
    BuildContext,
    CanvasInteractionContext,
  )?
  get onPanStart => (details, ref, buildContext, interactionContext) {
    if (interactionContext is ArrowWellInteraction) return;

    final brush = CanvasObject(
      id: const Uuid().v4(),
      type: .brush,
      topLeft: details.localPosition,
      bottomRight: details.localPosition,
      color: CanvasColors.neutral600,
      brushProperties: BrushProperties(points: [details.localPosition]),
    );

    ref.read(canvasObjectsProvider.notifier).addObject(brush);
    ref.read(canvasGestureStateProvider.notifier).setActiveObject(brush);
  };

  @override
  void Function(
    DragUpdateDetails,
    WidgetRef,
    BuildContext,
    CanvasInteractionContext,
  )?
  get onPanUpdate => (details, ref, buildContext, interactionContext) {
    final brushObject = ref.read(canvasGestureStateProvider).activeObject;
    if (brushObject == null || !brushObject.isBrush) return;

    brushObject.brushProps.points = [
      ...brushObject.brushProps.points,
      details.localPosition,
    ];

    // Update bounding box
    final allPoints = brushObject.brushProps.points;
    final minX = allPoints.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final maxX = allPoints.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final minY = allPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxY = allPoints.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    brushObject.topLeft = Offset(minX, minY);
    brushObject.bottomRight = Offset(maxX, maxY);

    ref.read(canvasObjectsProvider.notifier).updateObject(brushObject);
  };

  @override
  void Function(
    DragEndDetails,
    WidgetRef,
    BuildContext,
    CanvasInteractionContext,
  )?
  get onPanEnd => (details, ref, buildContext, interactionContext) {
    final brushObject = ref.read(canvasGestureStateProvider).activeObject;
    if (brushObject == null || !brushObject.isBrush) return;

    ref.read(canvasObjectsProvider.notifier).selectObject(brushObject);
    ref.read(toolModeProvider.notifier).set(.pointer);
    ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
  };
}
