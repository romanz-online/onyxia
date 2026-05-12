import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_gesture_state.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import '../services/services.dart';

/// Handles gestures for arrow tool
/// Handles arrow well interactions: clicks for auto-completion and pans for arrow creation
class ArrowToolBehavior extends CanvasToolGestureHandler {
  ArrowToolBehavior({required super.canvasConfig});

  Offset? _lastHoverPosition;

  @override
  ToolMode get toolMode => ToolMode.arrow;

  @override
  bool get allowsViewportPanning => false;

  @override
  bool get allowsViewportScaling => true;

  @override
  void Function(
          TapUpDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onTapUp => (details, ref, buildContext, interactionContext) {
            final gestureState = ref.read(canvasGestureStateProvider);

            switch (interactionContext) {
              case ArrowToolWellInteraction(
                  :final sourceObject,
                  :final startOffset,
                  :final closestEdge
                ):
                if (gestureState.interactionContext == null) {
                  final arrow = ArrowInteractionService.startArrowWellPan(
                    DragStartDetails(
                        globalPosition: details.globalPosition,
                        localPosition: details.localPosition),
                    sourceObject,
                    closestEdge,
                    ref,
                    buildContext,
                    canvasConfig,
                    startRelativeOffset: startOffset,
                  );
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setActiveObject(arrow);
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setArrowMoveType(ArrowMoveType.end);
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .storeContext(interactionContext);
                  _lastHoverPosition = details.globalPosition;
                }
                break;
              case ObjectFillInteractionContext(:final targetObject):
                final arrowToolWellData =
                    ref.read(arrowToolPrimedObjectsProvider);

                if (gestureState.interactionContext == null &&
                    arrowToolWellData != null) {
                  final arrow = ArrowInteractionService.startArrowWellPan(
                    DragStartDetails(
                        globalPosition: details.globalPosition,
                        localPosition: details.localPosition),
                    targetObject,
                    arrowToolWellData.closestEdge,
                    ref,
                    buildContext,
                    canvasConfig,
                    startRelativeOffset: arrowToolWellData.relativeOffset,
                  );
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setActiveObject(arrow);
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setArrowMoveType(ArrowMoveType.end);
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .storeContext(interactionContext);
                  _lastHoverPosition = details.globalPosition;
                }
                break;
              case BackgroundInteraction():
                if (gestureState.interactionContext != null) {
                  ArrowInteractionService.endArrowPan(DragEndDetails(), ref,
                      gestureState.activeObject, true, canvasConfig);
                  ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
                }
                break;
              default:
                if (gestureState.interactionContext != null) {
                  ArrowInteractionService.updateArrowPan(
                    DragUpdateDetails(
                      globalPosition: details.globalPosition,
                      localPosition: details.localPosition,
                      delta: Offset.zero,
                    ),
                    ref,
                    gestureState.activeObject,
                  );
                  ArrowInteractionService.endArrowPan(
                    DragEndDetails(),
                    ref,
                    gestureState.activeObject,
                    true,
                    canvasConfig,
                  );
                } else {
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .resetInteraction(ref);
                  ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
                }
                break;
            }
          };

  @override
  void Function(
          PointerHoverEvent, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onHover => (event, ref, buildContext, interactionContext) {
            final gestureState = ref.read(canvasGestureStateProvider);
            if (gestureState.interactionContext == null ||
                gestureState.activeObject?.isArrow == false) {
              return;
            }

            ArrowInteractionService.updateArrowPan(
              DragUpdateDetails(
                globalPosition: event.position,
                localPosition: event.localPosition,
                delta: _lastHoverPosition != null
                    ? event.position - _lastHoverPosition!
                    : Offset.zero,
              ),
              ref,
              gestureState.activeObject,
            );

            _lastHoverPosition = event.position;
          };

  @override
  void Function(
          DragStartDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanStart => (details, ref, buildContext, interactionContext) {
            switch (interactionContext) {
              case ArrowToolWellInteraction(
                  :final sourceObject,
                  :final startOffset,
                  :final closestEdge
                ):
                final arrow = ArrowInteractionService.startArrowWellPan(
                  details,
                  sourceObject,
                  closestEdge,
                  ref,
                  buildContext,
                  canvasConfig,
                  startRelativeOffset: startOffset,
                );
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setActiveObject(arrow);
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .setArrowMoveType(ArrowMoveType.end);
              case ObjectFillInteractionContext(:final targetObject):
                final arrowToolWellData =
                    ref.read(arrowToolPrimedObjectsProvider);
                if (arrowToolWellData != null) {
                  final arrow = ArrowInteractionService.startArrowWellPan(
                    DragStartDetails(
                        globalPosition: details.globalPosition,
                        localPosition: details.localPosition),
                    targetObject,
                    arrowToolWellData.closestEdge,
                    ref,
                    buildContext,
                    canvasConfig,
                    startRelativeOffset: arrowToolWellData.relativeOffset,
                  );
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setActiveObject(arrow);
                  ref
                      .read(canvasGestureStateProvider.notifier)
                      .setArrowMoveType(ArrowMoveType.end);
                }
                break;
              case _:
                break;
            }
          };

  @override
  void Function(
          DragUpdateDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanUpdate => (details, ref, buildContext, interactionContext) {
            ArrowInteractionService.updateArrowPan(details, ref,
                ref.read(canvasGestureStateProvider).activeObject);
          };

  @override
  void Function(
          DragEndDetails, WidgetRef, BuildContext, CanvasInteractionContext)?
      get onPanEnd => (details, ref, buildContext, interactionContext) {
            ArrowInteractionService.endArrowPan(
                details,
                ref,
                ref.read(canvasGestureStateProvider).activeObject,
                true,
                canvasConfig);

            // don't do this when drawing an arrow because it closes the headless palette
            if (ref.read(canvasGestureStateProvider).activeObject == null) {
              ref
                  .read(canvasGestureStateProvider.notifier)
                  .resetInteraction(ref);
            }
          };
}
