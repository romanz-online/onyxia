import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';

class ImageToolBehavior extends CanvasToolGestureHandler {
  const ImageToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => ToolMode.image;

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(
          TapDownDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onTapDown => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ArrowToolWellInteraction():
              case ArrowWellInteraction():
              case ArrowTextInteraction():
              case ObjectResizeInteraction():
              case ArrowResizeInteraction():
              case ArrowMoveInteraction():
              case ObjectFillInteractionContext():
                ref.read(toolModeProvider.notifier).state = ToolMode.pointer;
                break;
              case BackgroundInteraction():
                break;
            }
          };
}
