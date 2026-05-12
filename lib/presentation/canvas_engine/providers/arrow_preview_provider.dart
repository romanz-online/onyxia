import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import 'objects_provider.dart';
import 'bounds_provider.dart';

class ArrowPreview {
  final CanvasObject arrow;
  final CanvasObject sourceObject;
  final CanvasObject? targetObject;
  final ConnectionPoint sourceConnection;
  final ConnectionPoint targetConnection;
  final CanvasObject? ghostObject;

  ArrowPreview({
    required this.arrow,
    required this.sourceObject,
    this.targetObject,
    required this.sourceConnection,
    required this.targetConnection,
    this.ghostObject,
  });

  bool get hasGhostObject => ghostObject != null;
  bool get hasTargetObject => targetObject != null;
}

class ArrowPreviewNotifier extends Notifier<ArrowPreview?> {
  @override
  ArrowPreview? build() => null;

  void setPreview({
    required BuildContext context,
    required WidgetRef ref,
    required CanvasObject sourceObject,
    required CanvasObject targetObject,
    required ConnectionPoint sourceConnection,
    required CanvasConfig canvasConfig,
  }) {
    // Determine the best connection point on the target object
    final targetConnection = _findBestConnectionPoint(
      sourceObject,
      targetObject,
      sourceConnection,
    );

    state = ArrowPreview(
      arrow: _createArrow(
        context,
        ref,
        sourceObject,
        targetObject,
        sourceConnection,
        targetConnection,
        canvasConfig,
      ),
      sourceObject: sourceObject,
      targetObject: targetObject,
      sourceConnection: sourceConnection,
      targetConnection: targetConnection,
    );
  }

  void setGhostPreview({
    required BuildContext context,
    required WidgetRef ref,
    required CanvasObject sourceObject,
    required ConnectionPoint sourceConnection,
    required CanvasObject ghostObject,
    required CanvasConfig canvasConfig,
  }) {
    // target connection is the opposite of source
    final targetConnection = switch (sourceConnection) {
      ConnectionPoint.top => ConnectionPoint.bottom,
      ConnectionPoint.left => ConnectionPoint.right,
      ConnectionPoint.right => ConnectionPoint.left,
      ConnectionPoint.bottom => ConnectionPoint.top,
      ConnectionPoint.none => ConnectionPoint.none,
    };

    state = ArrowPreview(
      arrow: _createArrow(
        context,
        ref,
        sourceObject,
        ghostObject,
        sourceConnection,
        targetConnection,
        canvasConfig,
      ),
      sourceObject: sourceObject,
      sourceConnection: sourceConnection,
      targetConnection: targetConnection,
      ghostObject: ghostObject,
    );
  }

  void clearPreview() {
    state = null;
  }

  void updatePreview(
    BuildContext context,
    WidgetRef ref,
    CanvasObject sourceObject,
    ConnectionPoint createPoint,
    CanvasConfig canvasConfig,
  ) {
    final closestObj = _findClosestObjectInDirection(
      ref.read(canvasObjectsProvider).objects,
      sourceObject,
      createPoint,
    );

    if (closestObj == null) {
      // Create ghost object preview
      final ghostObject = _createGhostObject(sourceObject, createPoint);
      setGhostPreview(
        context: context,
        ref: ref,
        sourceObject: sourceObject,
        sourceConnection: createPoint,
        ghostObject: ghostObject,
        canvasConfig: canvasConfig,
      );
    } else {
      setPreview(
        context: context,
        ref: ref,
        sourceObject: sourceObject,
        targetObject: closestObj,
        sourceConnection: createPoint,
        canvasConfig: canvasConfig,
      );
    }
  }

  CanvasObject _createGhostObject(
    CanvasObject sourceObject,
    ConnectionPoint createPoint,
  ) {
    const double previewArrowLength = CanvasBounds.gridSpacing * 8;

    // Get the starting position from the connection point
    final arrowStartPos = createPoint.getOffset(sourceObject);

    // Determine direction based on create point
    Offset direction = Offset.zero;
    switch (createPoint) {
      case ConnectionPoint.top:
        direction = const Offset(0, -1);
        break;
      case ConnectionPoint.bottom:
        direction = const Offset(0, 1);
        break;
      case ConnectionPoint.left:
        direction = const Offset(-1, 0);
        break;
      case ConnectionPoint.right:
      case ConnectionPoint.none:
        direction = const Offset(1, 0);
        break;
    }

    // Calculate ghost object position
    final arrowEndPos = arrowStartPos + (direction * previewArrowLength);
    final arrowLength = (arrowStartPos - arrowEndPos).distance;
    final sourceObjDimensions = sourceObject.getDimensions();

    // Position ghost object so the arrow connects to the appropriate side
    Offset ghostTopLeft = sourceObject.topLeft;
    switch (createPoint) {
      case ConnectionPoint.top:
        ghostTopLeft += Offset(0, -arrowLength - sourceObjDimensions.height);
        break;
      case ConnectionPoint.bottom:
        ghostTopLeft += Offset(0, arrowLength + sourceObjDimensions.height);
        break;
      case ConnectionPoint.left:
        ghostTopLeft += Offset(-arrowLength - sourceObjDimensions.width, 0);
        break;
      case ConnectionPoint.right:
        ghostTopLeft += Offset(arrowLength + sourceObjDimensions.width, 0);
        break;
      case ConnectionPoint.none:
        return CanvasObject.initial();
    }

    final ghostBottomRight = ghostTopLeft +
        Offset(sourceObjDimensions.width, sourceObjDimensions.height);

    // Clone the source object with new position and styling
    return CanvasObject(
      id: const Uuid().v4(),
      layer: 0,
      color: sourceObject.color.withValues(alpha: 0.5), // Ghost styling
      type: sourceObject.type,
      topLeft: ghostTopLeft,
      bottomRight: ghostBottomRight,
      stroke: sourceObject.stroke,
      arrowProperties:
          sourceObject.hasArrowProps ? sourceObject.arrowProps : null,
      imageProperties:
          sourceObject.hasImageProps ? sourceObject.imageProps : null,
      brushProperties:
          sourceObject.hasBrushProps ? sourceObject.brushProps : null,
      artifactProperties:
          sourceObject.hasArtifactProps ? sourceObject.artifactProps : null,
    );
  }

  CanvasObject _createArrow(
    BuildContext context,
    WidgetRef ref,
    CanvasObject startObj,
    CanvasObject endObj,
    ConnectionPoint startPoint,
    ConnectionPoint endPoint,
    CanvasConfig canvasConfig,
  ) {
    final arrowObj = CanvasObject(
      id: const Uuid().v4(),
      layer: 0,
      color: ThemeHelper.neutral500(context).withValues(alpha: 0.5),
      type: CanvasObjectType.arrow,
      topLeft: Offset.zero,
      bottomRight: Offset.zero,
      stroke: StrokeType.solid,
      arrowProperties: ArrowProperties(
        points: [],
        startObjectId: startObj.id,
        endObjectId: endObj.id,
        startPoint: startPoint,
        endPoint: endPoint,
        startRelativeOffset: Offset.zero,
        endRelativeOffset: Offset.zero,
        startTip: ArrowTip.none,
        endTip: ArrowTip.triangle,
        arrowType: canvasConfig.defaultArrowType,
      ),
    );

    arrowObj.drawNewKeypoints(ref, startObject: startObj, endObject: endObj);

    return arrowObj;
  }

  ConnectionPoint _findBestConnectionPoint(
    CanvasObject sourceObject,
    CanvasObject targetObject,
    ConnectionPoint sourceAnchor,
  ) {
    final sourcePos = sourceAnchor.getOffset(sourceObject);

    final targetCenter = Offset(
      (targetObject.topLeft.dx + targetObject.bottomRight.dx) / 2,
      (targetObject.topLeft.dy + targetObject.bottomRight.dy) / 2,
    );

    final direction = targetCenter - sourcePos;

    // Choose the connection point that's closest to the direction from source to target
    if (direction.dx.abs() > direction.dy.abs()) {
      // Horizontal direction is dominant
      return direction.dx > 0 ? ConnectionPoint.left : ConnectionPoint.right;
    } else {
      // Vertical direction is dominant
      return direction.dy > 0 ? ConnectionPoint.top : ConnectionPoint.bottom;
    }
  }

  CanvasObject? _findClosestObjectInDirection(
    List<CanvasObject> objects,
    CanvasObject sourceObject,
    ConnectionPoint createPoint,
  ) {
    if (createPoint == ConnectionPoint.none) return null;

    final sourcePosition = createPoint.getOffset(sourceObject);

    final searchDirection = switch (createPoint) {
      ConnectionPoint.top => const Offset(0, -1),
      ConnectionPoint.bottom => const Offset(0, 1),
      ConnectionPoint.left => const Offset(-1, 0),
      ConnectionPoint.right => const Offset(1, 0),
      ConnectionPoint.none => Offset.zero,
    };

    // Priority order: opposite first, then perpendicular pair, never same-direction
    final targetPointPriority = switch (createPoint) {
      ConnectionPoint.top => [
          ConnectionPoint.bottom,
          ConnectionPoint.left,
          ConnectionPoint.right
        ],
      ConnectionPoint.bottom => [
          ConnectionPoint.top,
          ConnectionPoint.left,
          ConnectionPoint.right
        ],
      ConnectionPoint.left => [
          ConnectionPoint.right,
          ConnectionPoint.top,
          ConnectionPoint.bottom
        ],
      ConnectionPoint.right => [
          ConnectionPoint.left,
          ConnectionPoint.top,
          ConnectionPoint.bottom
        ],
      ConnectionPoint.none => <ConnectionPoint>[],
    };

    double closestDistance = double.infinity;
    CanvasObject? closestObject;

    for (final obj in objects.where((e) => !e.isArrow && !e.isBrush)) {
      if (obj.id == sourceObject.id) continue;

      // Skip objects that are not sufficiently far away (gridSpacing*2 margin)
      final margin = CanvasBounds.gridSpacing * 2;
      if (!(obj.bottomRight.dx <= sourceObject.topLeft.dx - margin ||
          obj.topLeft.dx >= sourceObject.bottomRight.dx + margin ||
          obj.bottomRight.dy <= sourceObject.topLeft.dy - margin ||
          obj.topLeft.dy >= sourceObject.bottomRight.dy + margin)) {
        continue;
      }

      // Use the opposite connection point for directional alignment check
      final oppositePtPos = targetPointPriority.first.getOffset(obj);
      final directionToOpposite = oppositePtPos - sourcePosition;
      final distToOpposite = directionToOpposite.distance;
      if (distToOpposite == 0) continue;

      final dotProduct = directionToOpposite.dx * searchDirection.dx +
          directionToOpposite.dy * searchDirection.dy;
      if (dotProduct <= 0) continue;

      final normalizedDir = directionToOpposite / distToOpposite;
      final alignment = normalizedDir.dx * searchDirection.dx +
          normalizedDir.dy * searchDirection.dy;
      if (alignment <= 0.3) continue;

      // Score = min distance from sourcePosition to any valid target connection point
      double minDist = double.infinity;
      for (final targetPoint in targetPointPriority) {
        final dist = (targetPoint.getOffset(obj) - sourcePosition).distance;
        if (dist < minDist) minDist = dist;
      }

      if (minDist < 300 && minDist < closestDistance) {
        closestDistance = minDist;
        closestObject = obj;
      }
    }

    return closestObject;
  }
}

final arrowPreviewProvider =
    NotifierProvider.autoDispose<ArrowPreviewNotifier, ArrowPreview?>(
  ArrowPreviewNotifier.new,
);
