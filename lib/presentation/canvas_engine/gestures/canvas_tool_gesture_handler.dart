import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import '../providers/providers.dart';
import 'canvas_interaction_context.dart';

/// Abstract base class for tool-specific gesture handlers
/// Each tool mode has its own implementation that defines how gestures should be handled
abstract class CanvasToolGestureHandler {
  final CanvasConfig canvasConfig;

  const CanvasToolGestureHandler({required this.canvasConfig});

  /// Handle tap down gesture - return null if tool doesn't handle this gesture
  void Function(TapDownDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onTapDown => null;

  /// Handle tap up gesture - return null if tool doesn't handle this gesture
  void Function(TapUpDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onTapUp => null;

  /// Handle pan start gesture - return null if tool doesn't handle this gesture
  void Function(DragStartDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanStart => null;

  /// Handle pan update gesture - return null if tool doesn't handle this gesture
  void Function(DragUpdateDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanUpdate => null;

  /// Handle pan end gesture - return null if tool doesn't handle this gesture
  void Function(DragEndDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onPanEnd => null;

  /// Handle secondary tap down (right click) - return null if tool doesn't handle this gesture
  void Function(TapDownDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onSecondaryTapDown => null;

  /// Handle secondary tap up (right click release) - return null if tool doesn't handle this gesture
  void Function(TapUpDetails, WidgetRef, BuildContext, CanvasInteractionContext)? get onSecondaryTapUp => null;

  /// Handle hover gesture - return null if tool doesn't handle this gesture
  void Function(PointerHoverEvent, WidgetRef, BuildContext, CanvasInteractionContext)? get onHover => null;

  /// Handle pointer enter gesture - return null if tool doesn't handle this gesture
  void Function(PointerEnterEvent, WidgetRef, BuildContext, CanvasInteractionContext)? get onEnter => null;

  /// Handle pointer exit gesture - return null if tool doesn't handle this gesture
  void Function(PointerExitEvent, WidgetRef, BuildContext, CanvasInteractionContext)? get onExit => null;

  /// Get the tool mode this handler is responsible for
  ToolMode get toolMode;

  /// Whether this tool allows InteractiveViewer panning
  bool get allowsViewportPanning => true;

  /// Whether this tool allows InteractiveViewer scaling
  bool get allowsViewportScaling => true;
}
