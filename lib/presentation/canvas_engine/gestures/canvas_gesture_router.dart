import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'canvas_gesture_state.dart';
import 'canvas_interaction_context.dart';
import 'canvas_tool_gesture_handler.dart';
import 'pointer_tool_behavior.dart';
import 'pan_tool_behavior.dart';
import 'shape_tool_behavior.dart';
import 'text_tool_behavior.dart';
import 'image_tool_behavior.dart';
import 'brush_tool_behavior.dart';
import 'arrow_tool_behavior.dart';
import 'comment_tool_behavior.dart';
import 'artifact_tool_behavior.dart';

/// Central router that delegates gestures to appropriate tool handlers
/// Replaces scattered gesture handling in canvas screens
class CanvasGestureRouter {
  late final Map<ToolMode, CanvasToolGestureHandler> _handlers;
  final WidgetRef ref;
  final BuildContext context;
  final CanvasConfig canvasConfig;

  CanvasGestureRouter({
    required this.ref,
    required this.context,
    required this.canvasConfig,
  }) {
    _initializeHandlers();
  }

  void _initializeHandlers() {
    _handlers = {
      .pointer: PointerToolBehavior(canvasConfig: canvasConfig),
      .pan: PanToolBehavior(canvasConfig: canvasConfig),
      .rectangle: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .rectangle,
      ),
      .diamond: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .diamond,
      ),
      .oblong: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .oblong,
      ),
      .circle: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .circle,
      ),
      .rhombus: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .rhombus,
      ),
      .trapezoid: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .trapezoid,
      ),
      .cylinder: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .cylinder,
      ),
      .house: ShapeToolBehavior(canvasConfig: canvasConfig, shapeType: .house),
      .reverseHouse: ShapeToolBehavior(
        canvasConfig: canvasConfig,
        shapeType: .reverseHouse,
      ),
      .text: TextToolBehavior(canvasConfig: canvasConfig),
      .image: ImageToolBehavior(canvasConfig: canvasConfig),
      .brush: BrushToolBehavior(canvasConfig: canvasConfig),
      .arrow: ArrowToolBehavior(canvasConfig: canvasConfig),
      .comment: CommentToolBehavior(canvasConfig: canvasConfig),
      .artifact: ArtifactToolBehavior(canvasConfig: canvasConfig),
    };
  }

  /// Route tap down gesture with canvas interaction context
  void Function(TapDownDetails)? getHandleTapDown(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onTapDown;
    return handler != null
        ? (details) => handler(details, ref, context, interactionContext)
        : null;
  }

  /// Route tap up gesture with canvas interaction context
  /// If dragging was in progress (storedInteractionContext exists), triggers onPanEnd instead
  void Function(TapUpDetails)? getHandleTapUp(
    CanvasInteractionContext interactionContext,
  ) {
    return (details) {
      final storedContext = ref
          .read(canvasGestureStateProvider)
          .interactionContext;
      if (storedContext != null) {
        // There was dragging - use getHandlePanEnd instead
        final panEndHandler = getHandlePanEnd();
        if (panEndHandler != null) {
          panEndHandler(
            DragEndDetails(
              globalPosition: details.globalPosition,
              localPosition: details.localPosition,
              velocity: Velocity.zero,
            ),
          );
        }
      } else {
        // Normal tap - use normal onTapUp
        final tapUpHandler = _getCurrentHandler().onTapUp;
        if (tapUpHandler != null) {
          tapUpHandler(details, ref, context, interactionContext);
        }
      }
    };
  }

  void Function(DragDownDetails)? getHandlePanDown(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onPanStart;
    // convert DragDownDetails to DragStartDetails -- they're basically the same thing
    return handler != null
        ? (details) {
            handler(
              DragStartDetails(
                globalPosition: details.globalPosition,
                localPosition: details.localPosition,
              ),
              ref,
              context,
              interactionContext,
            );
          }
        : null;
  }

  /// Route pan start gesture with canvas interaction context
  void Function(DragStartDetails)? getHandlePanStart(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onPanStart;
    return handler != null
        ? (details) {
            // Store the interaction context for continuous gestures
            ref
                .read(canvasGestureStateProvider.notifier)
                .storeContext(interactionContext);
            handler(details, ref, context, interactionContext);
          }
        : null;
  }

  /// Route pan update gesture using stored interaction context
  void Function(DragUpdateDetails)? getHandlePanUpdate() {
    final handler = _getCurrentHandler().onPanUpdate;
    return handler != null
        ? (details) {
            final storedContext = ref
                .read(canvasGestureStateProvider)
                .interactionContext;
            if (storedContext != null) {
              handler(details, ref, context, storedContext);
            }
          }
        : null;
  }

  /// Route pan end gesture using stored interaction context, then clear it
  void Function(DragEndDetails)? getHandlePanEnd() {
    final handler = _getCurrentHandler().onPanEnd;
    return handler != null
        ? (details) {
            final storedContext = ref
                .read(canvasGestureStateProvider)
                .interactionContext;
            if (storedContext != null) {
              handler(details, ref, context, storedContext);
              ref.read(canvasGestureStateProvider.notifier).clearContext();
            }
          }
        : null;
  }

  /// Route secondary tap down with canvas interaction context
  void Function(TapDownDetails)? getHandleSecondaryTapDown(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onSecondaryTapDown;
    return handler != null
        ? (details) => handler(details, ref, context, interactionContext)
        : null;
  }

  /// Route secondary tap up gesture with canvas interaction context
  void Function(TapUpDetails)? getHandleSecondaryTapUp(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onSecondaryTapUp;
    return handler != null
        ? (details) => handler(details, ref, context, interactionContext)
        : null;
  }

  /// Route hover gesture with canvas interaction context
  void Function(PointerHoverEvent)? getHandleHover(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onHover;
    return handler != null
        ? (event) => handler(event, ref, context, interactionContext)
        : null;
  }

  /// Route enter gesture with canvas interaction context
  void Function(PointerEnterEvent)? getHandleEnter(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onEnter;
    return handler != null
        ? (event) => handler(event, ref, context, interactionContext)
        : null;
  }

  /// Route exit gesture with canvas interaction context
  void Function(PointerExitEvent)? getHandleExit(
    CanvasInteractionContext interactionContext,
  ) {
    final handler = _getCurrentHandler().onExit;
    return handler != null
        ? (event) => handler(event, ref, context, interactionContext)
        : null;
  }

  /// Get the handler for the current tool mode
  CanvasToolGestureHandler _getCurrentHandler() =>
      _handlers[ref.read(toolModeProvider)] ?? _handlers[ToolMode.pointer]!;

  /// Check if current tool allows viewport panning
  bool get allowsViewportPanning =>
      _getCurrentHandler().allowsViewportPanning &&
      !CanvasInteractionService.isFocusingText(context: context, ref: ref);

  /// Check if current tool allows viewport scaling
  bool get allowsViewportScaling => _getCurrentHandler().allowsViewportScaling;
}
