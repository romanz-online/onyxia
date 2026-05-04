import 'package:onyxia/export.dart';
import '../gestures/gestures.dart';
import '../providers/providers.dart';
import 'arrow_well.dart';

class ArrowWellsOverlay extends ConsumerWidget {
  final double scale;
  final bool showArrowWells;
  final TransformationController transformationController;
  final CanvasGestureRouter? gestureRouter;

  const ArrowWellsOverlay({
    super.key,
    required this.scale,
    required this.showArrowWells,
    required this.transformationController,
    this.gestureRouter,
  });

  void _handleArrowPreviewChange(
    CanvasObject sourceObject,
    ConnectionPoint createPoint,
    bool active,
    WidgetRef ref,
    BuildContext context,
  ) {
    final previewNotifier = ref.read(arrowPreviewProvider.notifier);
    if (!active) {
      previewNotifier.clearPreview();
      return;
    }

    previewNotifier.updatePreview(
      context,
      ref,
      sourceObject,
      createPoint,
      ref.read(canvasConfigProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showArrowWells || gestureRouter == null) return const SizedBox.shrink();

    final objects = ref.watch(canvasObjectsProvider).objects;
    final selectedObjects = ref.watch(canvasObjectsProvider).selectedObjects;
    final hoveredObjects = ref.watch(hoveredObjectsProvider);
    final toolMode = ref.watch(toolModeProvider);

    final stackChildren = <Widget>[];

    // Only show traditional arrow wells when NOT in arrow tool mode
    if (toolMode != ToolMode.arrow) {
      // Create arrow wells for ALL objects - let each well decide its own visibility
      for (final obj in objects) {
        if (obj.isArrow || obj.isBrush || obj.type == CanvasObjectType.text) {
          continue;
        }

        for (final connectionPoint in [
          ConnectionPoint.top,
          ConnectionPoint.right,
          ConnectionPoint.bottom,
          ConnectionPoint.left,
        ]) {
          stackChildren.add(
            ArrowWell(
              connectionPoint: connectionPoint,
              scale: scale,
              sourceObject: obj,
              gestureRouter: gestureRouter,
              onTargetChanged: (isTarget) => _handleArrowPreviewChange(
                obj,
                connectionPoint,
                isTarget,
                ref,
                context,
              ),
              // Pass state info so arrow well can decide its visibility
              isSourceSelected: selectedObjects.contains(obj),
              isSourceHovered: hoveredObjects.contains(obj),
              isArrowToolActive: toolMode == ToolMode.arrow,
              isGesturing: ref.watch(canvasGestureStateProvider).interactionContext != null,
            ),
          );
        }
      }
    }

    // Add hover detectors for both systems
    for (final obj in objects) {
      // Large hover region for connection point circles
      final largeHoverDetector = _buildLargeHoverDetector(obj, ref, toolMode);
      if (largeHoverDetector != null) {
        stackChildren.add(largeHoverDetector);
      }

      // Small hover region for arrow tool wells (only in arrow tool mode)
      if (toolMode == ToolMode.arrow) {
        final smallHoverDetector = _buildSmallHoverDetector(obj, ref);
        if (smallHoverDetector != null) {
          stackChildren.add(smallHoverDetector);
        }
      }
    }

    return Stack(children: stackChildren);
  }

  /// Builds large hover detector for connection point circles (gridSpacing * 3)
  Widget? _buildLargeHoverDetector(CanvasObject canvasObject, WidgetRef ref, ToolMode toolMode) {
    // Original logic for showing connection point circles
    if (![
      CanvasObjectType.rectangle,
      CanvasObjectType.diamond,
      CanvasObjectType.oblong,
      CanvasObjectType.circle,
      CanvasObjectType.rhombus,
      CanvasObjectType.trapezoid,
      CanvasObjectType.cylinder,
      CanvasObjectType.house,
      CanvasObjectType.reverseHouse,
    ].contains(canvasObject.type)) {
      return null;
    }

    try {
      final objSize = canvasObject.getDimensions();
      const double extension = CanvasBounds.gridSpacing * 3.0; // Large hover region

      return Positioned(
        left: canvasObject.topLeft.dx - extension,
        top: canvasObject.topLeft.dy - extension,
        width: objSize.width + (extension * 2),
        height: objSize.height + (extension * 2),
        child: MouseRegion(
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: (_) => ref.read(hoveredObjectsProvider.notifier).addObject(canvasObject),
          onExit: (_) => ref.read(hoveredObjectsProvider.notifier).removeObject(canvasObject),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Builds small hover detector for arrow tool wells (gridSpacing / 2)
  Widget? _buildSmallHoverDetector(CanvasObject canvasObject, WidgetRef ref) {
    // Only include objects that aren't brushes, arrows, or text
    if (canvasObject.isArrow || canvasObject.isBrush || canvasObject.type == CanvasObjectType.text) {
      return null;
    }

    try {
      final objSize = canvasObject.getDimensions();
      const double margin = CanvasBounds.gridSpacing; // Small hover region

      return Positioned(
        left: canvasObject.topLeft.dx - margin,
        top: canvasObject.topLeft.dy - margin,
        width: objSize.width + (margin * 2),
        height: objSize.height + (margin * 2),
        child: MouseRegion(
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: (event) => _handleArrowToolHoverEnter(canvasObject, event, ref),
          onExit: (event) => _handleArrowToolHoverExit(canvasObject, ref),
          onHover: (event) => _handleArrowToolHover(canvasObject, event, ref),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Handles mouse enter for arrow tool mode
  void _handleArrowToolHoverEnter(
    CanvasObject canvasObject,
    PointerEnterEvent event,
    WidgetRef ref,
  ) {
    final cursorPosition = _getCanvasCoordinates(event.position, ref);
    final margin = CanvasBounds.gridSpacing;

    if (canvasObject.isPointInObject(cursorPosition, margin: margin)) {
      _updateArrowToolPrimedObject(canvasObject, cursorPosition, ref);
    }
  }

  /// Handles mouse exit for arrow tool mode
  void _handleArrowToolHoverExit(CanvasObject canvasObject, WidgetRef ref) {
    final currentPrimed = ref.read(arrowToolPrimedObjectsProvider);
    if (currentPrimed?.object.id == canvasObject.id) {
      // Don't clear the primed object if we're actively drawing an arrow from it
      if (!_isDrawingArrowFromObject(canvasObject, ref)) {
        ref.read(arrowToolPrimedObjectsProvider.notifier).clear();
      }
    }
  }

  /// Handles mouse hover movement for arrow tool mode
  void _handleArrowToolHover(
    CanvasObject canvasObject,
    PointerHoverEvent event,
    WidgetRef ref,
  ) {
    final cursorPosition = _getCanvasCoordinates(event.position, ref);
    final margin = CanvasBounds.gridSpacing;

    // Check if cursor is within range
    final isInRange = canvasObject.isPointInObject(cursorPosition, margin: margin);
    final currentPrimed = ref.read(arrowToolPrimedObjectsProvider);
    final isCurrentlyPrimed = currentPrimed?.object.id == canvasObject.id;

    if (isInRange && !isCurrentlyPrimed) {
      // Set as primed object (replacing any existing one)
      _updateArrowToolPrimedObject(canvasObject, cursorPosition, ref);
    } else if (!isInRange && isCurrentlyPrimed) {
      // Don't clear primed object if we're actively drawing an arrow from it
      if (!_isDrawingArrowFromObject(canvasObject, ref)) {
        ref.read(arrowToolPrimedObjectsProvider.notifier).clear();
      }
    } else if (isInRange && isCurrentlyPrimed) {
      // Update cursor position for dynamic well positioning
      ref.read(arrowToolPrimedObjectsProvider.notifier).updateCursor(cursorPosition);
    }
  }

  /// Updates the arrow tool primed object, finding the closest object if multiple are in range
  void _updateArrowToolPrimedObject(CanvasObject canvasObject, Offset cursorPosition, WidgetRef ref) {
    final currentPrimed = ref.read(arrowToolPrimedObjectsProvider);

    // If no object is currently primed, or this object is closer, set it as primed
    if (currentPrimed == null) {
      ref.read(arrowToolPrimedObjectsProvider.notifier).setPrimed(canvasObject, cursorPosition);
    } else {
      // Compare distances to determine which object should be primed
      final currentDistance = (cursorPosition - currentPrimed.object.topLeft).distance;
      final newDistance = (cursorPosition - canvasObject.topLeft).distance;
      if (newDistance < currentDistance) {
        ref.read(arrowToolPrimedObjectsProvider.notifier).setPrimed(canvasObject, cursorPosition);
      }
    }
  }

  /// Converts screen coordinates to canvas coordinates
  Offset _getCanvasCoordinates(Offset screenPosition, WidgetRef ref) =>
      ref.read(canvasViewportProvider.notifier).convertToCanvasCoords(screenPosition);

  /// Checks if an arrow is currently being drawn from the given object
  bool _isDrawingArrowFromObject(CanvasObject object, WidgetRef ref) {
    final gestureState = ref.read(canvasGestureStateProvider);

    // Check if there's an active arrow being drawn
    if (gestureState.activeObject == null || !gestureState.activeObject!.isArrow) {
      return false;
    }

    // Check if we're drawing from start to end (arrow creation)
    if (gestureState.arrowMoveType != ArrowMoveType.end) {
      return false;
    }

    // Check if the active arrow's start object matches this object
    return gestureState.activeObject!.arrowProps.startObjectId == object.id;
  }
}
