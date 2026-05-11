import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../widgets/canvas_right_click_menu.dart';

/// Handles gestures when pan tool is active
/// Responsible for viewport panning and navigation
class PanToolBehavior extends CanvasToolGestureHandler {
  const PanToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => ToolMode.pan;

  @override
  bool get allowsViewportPanning => true;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(
          TapDownDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onSecondaryTapDown => (
            details,
            ref,
            buildContext,
            interactionContext,
          ) {
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
}
