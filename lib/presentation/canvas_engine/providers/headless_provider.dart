import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import 'objects_provider.dart';
import 'bounds_provider.dart';

class HeadlessState {
  final CanvasObject? headlessArrow;
  final CanvasObject? ghostObject;
  final CanvasObjectType? hoveredShapeType;
  final CanvasConfig? canvasConfig;
  final String? sourceArtifactId;
  final List<Artifact>? children;
  final Artifact? hoveredItem;

  const HeadlessState({
    this.headlessArrow,
    this.ghostObject,
    this.hoveredShapeType,
    this.canvasConfig,
    this.sourceArtifactId,
    this.children,
    this.hoveredItem,
  });

  HeadlessState copyWith({
    CanvasObject? headlessArrow,
    CanvasObject? ghostObject,
    CanvasObjectType? hoveredShapeType,
    CanvasConfig? canvasConfig,
    String? sourceArtifactId,
    List<Artifact>? children,
    Artifact? hoveredItem,
    bool clearHeadlessArrow = false,
    bool clearGhostObject = false,
    bool clearHoveredShapeType = false,
    bool clearCanvasConfig = false,
    bool clearSourceArtifactId = false,
    bool clearChildren = false,
    bool clearHoveredItem = false,
  }) {
    return HeadlessState(
      headlessArrow:
          clearHeadlessArrow ? null : (headlessArrow ?? this.headlessArrow),
      ghostObject: clearGhostObject ? null : (ghostObject ?? this.ghostObject),
      hoveredShapeType: clearHoveredShapeType
          ? null
          : (hoveredShapeType ?? this.hoveredShapeType),
      canvasConfig:
          clearCanvasConfig ? null : (canvasConfig ?? this.canvasConfig),
      sourceArtifactId: clearSourceArtifactId
          ? null
          : (sourceArtifactId ?? this.sourceArtifactId),
      children: clearChildren ? null : (children ?? this.children),
      hoveredItem: clearHoveredItem ? null : (hoveredItem ?? this.hoveredItem),
    );
  }

  bool get isVisible => headlessArrow != null;
  bool get hasGhostObject => ghostObject != null;
  bool get isFlowCanvas => canvasConfig?.canvasType == CanvasType.flow;
  bool get hasChildren => children != null && children!.isNotEmpty;
}

class HeadlessArrowNotifier extends Notifier<HeadlessState> {
  @override
  HeadlessState build() => const HeadlessState();

  void showPalette({
    required CanvasObject headlessArrow,
    required CanvasConfig canvasConfig,
  }) {
    String? sourceArtifactId;
    List<Artifact>? children;

    // For flow canvases, try to find the source item and its child notes
    if (canvasConfig.canvasType == CanvasType.flow) {
      sourceArtifactId = _extractSourceArtifactId(headlessArrow);
      if (sourceArtifactId != null) {
        children = _findChildren(sourceArtifactId);
      }
    }

    state = state.copyWith(
      headlessArrow: headlessArrow,
      canvasConfig: canvasConfig,
      sourceArtifactId: sourceArtifactId,
      children: children,
    );
  }

  void hidePalette() {
    state = state.copyWith(
      clearHeadlessArrow: true,
      clearGhostObject: true,
      clearHoveredShapeType: true,
      clearCanvasConfig: true,
      clearSourceArtifactId: true,
      clearChildren: true,
      clearHoveredItem: true,
    );
  }

  void setHoveredShape(BuildContext context, CanvasObjectType? shapeType) {
    state = state.copyWith(
      hoveredShapeType: shapeType,
      clearHoveredShapeType: shapeType == null,
    );

    // Update ghost object when hovering
    if (shapeType != null && state.headlessArrow != null) {
      final ghostObject = _createGhostObject(
        context,
        shapeType,
        state.headlessArrow!,
      );
      state = state.copyWith(ghostObject: ghostObject);
    } else {
      state = state.copyWith(clearGhostObject: true);
    }
  }

  void setHoveredItem(BuildContext context, Artifact? item) {
    state = state.copyWith(
      hoveredItem: item,
      clearHoveredItem: item == null,
    );

    // Update ghost object when hovering over a note
    if (item != null && state.headlessArrow != null) {
      final ghostObject = _createArtifactGhostObject(
        context,
        item,
        state.headlessArrow!,
      );
      state = state.copyWith(ghostObject: ghostObject);
    } else {
      state = state.copyWith(clearGhostObject: true);
    }
  }

  CanvasObject _createGhostObject(
    BuildContext context,
    CanvasObjectType shapeType,
    CanvasObject arrow,
  ) {
    final arrowProps = arrow.arrowProps;
    const double spacing = CanvasBounds.gridSpacing;
    const double shapeOffset = spacing * 5;

    // Determine where to place the ghost object
    Offset ghostPosition;

    // Check if arrow needs end shape (disconnected end)
    final needsEndShape = arrowProps.endPoint == ConnectionPoint.none;

    if (needsEndShape && arrowProps.points.isNotEmpty) {
      // Place ghost object at the end of the arrow
      final lastKeypoint = arrowProps.points.last;
      final secondLastKeypoint = arrowProps.points.length > 1
          ? arrowProps.points[arrowProps.points.length - 2]
          : arrowProps.points[0];

      // Calculate direction from second-to-last to last keypoint
      final direction = lastKeypoint - secondLastKeypoint;
      final normalizedDirection = direction.distance > 0
          ? direction / direction.distance
          : const Offset(1, 0);

      ghostPosition = lastKeypoint + (normalizedDirection * shapeOffset);
    } else {
      // Fallback: place at arrow's current position
      ghostPosition = Offset(
        (arrow.topLeft.dx + arrow.bottomRight.dx) / 2 + shapeOffset,
        (arrow.topLeft.dy + arrow.bottomRight.dy) / 2,
      );
    }

    // Create default-sized shape
    final Offset topLeft = ghostPosition.translate(
      spacing * -5,
      spacing * -5,
    );
    final Offset bottomRight = ghostPosition.translate(
      spacing * 5,
      spacing * 5,
    );

    return CanvasObject(
      id: const Uuid().v4(),
      layer: 0,
      color: NarwhalColors.neutral100.withValues(alpha: 0.5),
      type: shapeType,
      topLeft: topLeft,
      bottomRight: bottomRight,
      stroke: StrokeType.solid,
    );
  }

  CanvasObject _createArtifactGhostObject(
    BuildContext context,
    Artifact item,
    CanvasObject arrow,
  ) {
    final arrowProps = arrow.arrowProps;
    const double spacing = CanvasBounds.gridSpacing;
    const double shapeOffset = spacing * 5;

    // Determine where to place the ghost object (same logic as shapes)
    Offset ghostPosition;

    final needsEndShape = arrowProps.endPoint == ConnectionPoint.none;

    if (needsEndShape && arrowProps.points.isNotEmpty) {
      final lastKeypoint = arrowProps.points.last;
      final secondLastKeypoint = arrowProps.points.length > 1
          ? arrowProps.points[arrowProps.points.length - 2]
          : arrowProps.points[0];

      final direction = lastKeypoint - secondLastKeypoint;
      final normalizedDirection = direction.distance > 0
          ? direction / direction.distance
          : const Offset(1, 0);

      ghostPosition = lastKeypoint + (normalizedDirection * shapeOffset);
    } else {
      ghostPosition = Offset(
        (arrow.topLeft.dx + arrow.bottomRight.dx) / 2 + shapeOffset,
        (arrow.topLeft.dy + arrow.bottomRight.dy) / 2,
      );
    }

    // Create item object with larger default size than shapes
    final Offset topLeft = ghostPosition.translate(
      spacing * -6,
      spacing * -4,
    );
    final Offset bottomRight = ghostPosition.translate(
      spacing * 6,
      spacing * 4,
    );

    return CanvasObject(
      id: const Uuid().v4(),
      layer: 0,
      color: NarwhalColors.neutral100.withValues(alpha: 0.5),
      type: CanvasObjectType.artifact,
      topLeft: topLeft,
      bottomRight: bottomRight,
      stroke: StrokeType.solid,
      artifactProperties: ArtifactProperties(artifactId: item.id),
    );
  }

  String? _extractSourceArtifactId(CanvasObject headlessArrow) {
    final startObjectId = headlessArrow.arrowProps.startObjectId;
    if (startObjectId == null) return null;

    // Find the source object from the objects provider
    final objects = ref.read(canvasObjectsProvider).objects;
    final sourceObject =
        objects.firstWhereOrNull((obj) => obj.id == startObjectId);

    if (sourceObject != null &&
        sourceObject.type == CanvasObjectType.artifact) {
      return sourceObject.artifactProps.artifactId;
    }

    return null;
  }

  List<Artifact>? _findChildren(String parentArtifactId) {
    final notes = this.ref.read(artifactsProvider).value ?? const <Artifact>[];

    // Filter notes where parentId matches the source item
    final children =
        notes.where((req) => req.parentFolderId == parentArtifactId).toList();

    return children.isNotEmpty ? children : null;
  }
}

final headlessProvider =
    NotifierProvider.autoDispose<HeadlessArrowNotifier, HeadlessState>(
  HeadlessArrowNotifier.new,
);
