import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';

class ArtifactToolBehavior extends CanvasToolGestureHandler {
  const ArtifactToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => .artifact;

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(
    TapUpDetails,
    WidgetRef,
    BuildContext,
    CanvasInteractionContext,
  )?
  get onTapUp => (details, ref, buildContext, interactionContext) {
    switch (interactionContext) {
      case ObjectFillInteractionContext(:final targetObject):
        CanvasInteractionService.createPin(
          ref: ref,
          position: details.localPosition,
          targetObject: targetObject,
        );
        break;
      case BackgroundInteraction():
        if (canvasConfig.allowArtifactsOnBackground) {
          switch (canvasConfig.artifactDisplay) {
            case .pin:
              CanvasInteractionService.createPin(
                ref: ref,
                position: details.localPosition,
                targetObject: null,
              );
              break;
            case .object:
              CanvasInteractionService.createArtifactObject(
                ref: ref,
                position: details.localPosition,
                artifact: null,
              );
              break;
          }
        }
        break;
      case _:
        return;
    }

    ref.read(toolModeProvider.notifier).set(.pointer);
  };
}
