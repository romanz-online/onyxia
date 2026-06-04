import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';

class CommentToolBehavior extends CanvasToolGestureHandler {
  const CommentToolBehavior({required super.canvasConfig});

  @override
  ToolMode get toolMode => .comment;

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
        _createComment(details.localPosition, targetObject, ref);
        break;
      case BackgroundInteraction():
        _createComment(details.localPosition, null, ref);
        break;
      case _:
        return;
    }

    ref.read(toolModeProvider.notifier).set(.pointer);
  };

  Future<void> _createComment(
    Offset localPosition,
    CanvasObject? targetObject,
    WidgetRef ref,
  ) async {
    await CanvasInteractionService.createComment(
      ref: ref,
      position: localPosition,
      targetObject: targetObject,
    );
  }
}
