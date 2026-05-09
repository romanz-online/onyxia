import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import '../providers/providers.dart';
import '../gestures/gestures.dart';
import 'interaction_service.dart';

/// Service for handling arrow well interactions
/// Provides shared methods for arrow creation and completion that can be used
/// by both arrow tool handler and pointer tool handler
class ArrowInteractionService {
  static void autoCompleteArrow(
    CanvasObject sourceObject,
    ConnectionPoint startPoint,
    WidgetRef ref,
    BuildContext context,
  ) {
    ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);

    final arrowPreview = ref.read(arrowPreviewProvider);
    if (arrowPreview == null) return;

    CanvasObject? endObject;
    bool createdObject = false;
    final List<CanvasObject> objectsToAdd = [];
    final List<Pin> pinsToAdd = [];

    if (arrowPreview.hasGhostObject) {
      final ghostObject = arrowPreview.ghostObject!;

      ghostObject.layer = ref.read(canvasObjectsProvider.notifier).nextLayer();
      ghostObject.color = sourceObject.color;
      ghostObject.topLeft =
          ref.read(canvasBoundsProvider.notifier).clamp(ghostObject.topLeft);
      ghostObject.bottomRight = ref
          .read(canvasBoundsProvider.notifier)
          .clamp(ghostObject.bottomRight);

      objectsToAdd.add(ghostObject);
      createdObject = true;

      endObject = ghostObject;
    } else if (arrowPreview.hasTargetObject) {
      endObject = arrowPreview.targetObject!;
    }

    if (endObject == null) return;

    arrowPreview.arrow.layer =
        ref.read(canvasObjectsProvider.notifier).nextLayer();
    arrowPreview.arrow.color = ThemeHelper.neutral600(context);
    arrowPreview.arrow.stroke = StrokeType.solid;
    arrowPreview.arrow.arrowProps.startTip = ArrowTip.none;
    arrowPreview.arrow.arrowProps.endTip = ArrowTip.triangle;

    CanvasInteractionService.pipeHistory(
        ref: ref,
        operation: () async {
          ref.read(pinsProvider.notifier).addPins(ref, pinsToAdd);
          objectsToAdd.add(arrowPreview.arrow);
          ref
              .read(canvasObjectsProvider.notifier)
              .addObjects(ref, objectsToAdd);
          arrowPreview.arrow.pruneKeypoints();
          ref.read(canvasObjectsProvider.notifier).updateObjects(ref);
        });

    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    if (createdObject) {
      ref.read(canvasObjectsProvider.notifier).selectObject(endObject);
      if (!endObject.isImage && !endObject.isArrow && !endObject.isBrush) {
        CanvasInteractionService.openTextEditor(ref: ref);
      }
    } else {
      ref.read(canvasObjectsProvider.notifier).selectObject(arrowPreview.arrow);
    }

    ref.read(arrowPreviewProvider.notifier).clearPreview();
  }

  static CanvasObject startArrowWellPan(
    DragStartDetails details,
    CanvasObject sourceObject,
    ConnectionPoint createPoint,
    WidgetRef ref,
    BuildContext context,
    CanvasConfig canvasConfig, {
    Offset? startRelativeOffset,
  }) {
    final arrow = CanvasObject(
      id: const Uuid().v4(),
      layer: ref.read(canvasObjectsProvider.notifier).nextLayer(),
      color: NarwhalColors.neutral600,
      type: CanvasObjectType.arrow,
      topLeft: Offset.zero,
      bottomRight: Offset.zero,
      stroke: StrokeType.solid,
      arrowProperties: ArrowProperties(
        startObjectId: sourceObject.id,
        endAbsoluteOffset: ref
            .read(canvasViewportProvider.notifier)
            .convertToCanvasCoords(details.globalPosition),
        startPoint: createPoint,
        startRelativeOffset: startRelativeOffset,
        arrowType: canvasConfig.defaultArrowType,
      ),
    );

    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    ref.read(canvasObjectsProvider.notifier).addObject(ref, arrow);
    ref.read(canvasObjectsProvider.notifier).selectObject(arrow);

    return arrow;
  }

  static void updateArrowPan(
    DragUpdateDetails details,
    WidgetRef ref,
    CanvasObject? arrow, {
    ArrowMoveType part = ArrowMoveType.end,
  }) {
    if (arrow == null || !arrow.isArrow) return;

    ref
        .read(canvasGestureStateProvider.notifier)
        .updateAccumulatedDelta(details.delta);

    final canvasPosition = ref
        .read(canvasViewportProvider.notifier)
        .convertToCanvasCoords(details.globalPosition);
    if (part == ArrowMoveType.start) {
      final endObj = arrow.getEndObject(ref);
      if (endObj.id.isEmpty) return;

      final startObj = ref.read(canvasObjectsProvider).objects.firstWhere(
            (obj) =>
                !obj.isArrow &&
                !obj.isBrush &&
                obj.isPointInObject(canvasPosition),
            orElse: () => CanvasObject.initial(),
          );

      arrow.handleMoveStartPoint(ref, startObj, endObj, canvasPosition);
    } else if (part == ArrowMoveType.end) {
      final startObj = arrow.getStartObject(ref);
      if (startObj.id.isEmpty) return;

      final endObj = ref.read(canvasObjectsProvider).objects.firstWhere(
            (obj) =>
                !obj.isArrow &&
                !obj.isBrush &&
                obj.isPointInObject(canvasPosition),
            orElse: () => CanvasObject.initial(),
          );

      arrow.handleMoveEndPoint(ref, startObj, endObj, canvasPosition);
    } else {
      return;
    }

    ref.read(canvasObjectsProvider.notifier).updateObjectState(arrow);

    ref.read(arrowPrimedObjectsProvider.notifier).set(ref
        .read(canvasObjectsProvider)
        .objects
        .where((obj) =>
            !obj.isArrow &&
            !obj.isBrush &&
            obj.id != arrow.arrowProps.startObjectId &&
            obj.id != arrow.arrowProps.endObjectId &&
            obj.isPointInObject(
              canvasPosition,
              margin: CanvasBounds.gridSpacing * 3,
            ))
        .toList());
  }

  static void endArrowPan(
    DragEndDetails details,
    WidgetRef ref,
    CanvasObject? arrow,
    bool isNewArrow,
    CanvasConfig canvasConfig,
  ) {
    if (arrow == null || !arrow.isArrow) return;

    arrow.pruneKeypoints();
    arrow.updateArrowBounds();
    ref.read(canvasObjectsProvider.notifier).updateObjectState(arrow);

    if (arrow.arrowProps.endPoint == ConnectionPoint.none &&
        arrow.arrowProps.points.isNotEmpty &&
        isNewArrow) {
      ref.read(headlessProvider.notifier).showPalette(
            headlessArrow: arrow,
            canvasConfig: canvasConfig,
            ref: ref,
          );
    } else {
      if (arrow.arrowProps.startPoint == ConnectionPoint.none ||
          arrow.arrowProps.endPoint == ConnectionPoint.none ||
          arrow.arrowProps.points.isEmpty) {
        // not a valid arrow, delete
        ref.read(canvasObjectsProvider.notifier).deleteObject(ref, arrow);
      } else {
        ref.read(canvasObjectsProvider.notifier).updateObject(ref, arrow);
      }
      ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
    }
  }
}
