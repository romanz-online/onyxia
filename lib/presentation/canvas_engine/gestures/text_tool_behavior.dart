import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';

class TextToolBehavior extends CanvasToolGestureHandler {
  const TextToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => ToolMode.text;

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(
          TapUpDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onTapUp => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ObjectFillInteractionContext(:final targetObject):
                ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
                ref
                    .read(canvasObjectsProvider.notifier)
                    .selectObject(targetObject);
                CanvasInteractionService.openTextEditor(ref: ref);
                break;
              case BackgroundInteraction():
                _createTextObject(details.localPosition, ref);
                break;
              case _:
                return;
            }

            ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
          };

  void _createTextObject(Offset tapPosition, WidgetRef ref) {
    const double width = CanvasBounds.gridSpacing * 7;
    const double height = CanvasBounds.gridSpacing * 2;
    final double leftX = tapPosition.dx - (width / 2);
    final double topY = tapPosition.dy;

    final textObject = CanvasObject(
      id: const Uuid().v4(),
      type: CanvasObjectType.text,
      topLeft: Offset(leftX, topY),
      bottomRight: Offset(leftX + width, topY + height),
      createdAt: DateTime.now(),
      color: Colors.transparent,
    );

    ref.read(canvasObjectsProvider.notifier).addObject(textObject);
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    ref.read(canvasObjectsProvider.notifier).selectObject(textObject);
    CanvasInteractionService.openTextEditor(ref: ref);
  }
}
