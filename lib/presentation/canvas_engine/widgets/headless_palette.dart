import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import '../gestures/gestures.dart';
import '../services/services.dart';

class HeadlessPalette extends ConsumerStatefulWidget {
  final CanvasObject arrow;

  const HeadlessPalette({super.key, required this.arrow});

  @override
  HeadlessPaletteState createState() => HeadlessPaletteState();
}

class HeadlessPaletteState extends ConsumerState<HeadlessPalette> {
  static const double menuSpacingX = 170.0;
  static const double menuSpacingY = 80.0;
  static const double borderWidth = 1.0;
  static const double buttonBorderRadius = 8.0;
  static const double menuPadding = 3.0;
  static const Size iconSize = Size(32, 32);

  static Size plainOptionSize = Size(
    iconSize.width + menuPadding * 2,
    iconSize.height + menuPadding * 2,
  );

  static Size shapePaletteSize = Size(
    plainOptionSize.width * 5,
    plainOptionSize.height * 2,
  );

  static Size addSectionSize = Size(
    shapePaletteSize.width + (borderWidth * 2) + menuPadding + 1.0,
    plainOptionSize.height - menuPadding * 2,
  );

  static const List<CanvasObjectType> shapeOptions = [
    CanvasObjectType.rectangle,
    CanvasObjectType.diamond,
    CanvasObjectType.oblong,
    CanvasObjectType.circle,
    CanvasObjectType.rhombus,
    CanvasObjectType.trapezoid,
    CanvasObjectType.cylinder,
    CanvasObjectType.house,
    CanvasObjectType.reverseHouse,
  ];

  static const Map<CanvasObjectType, IconData> _shapeIcons = {
    CanvasObjectType.rectangle: LucideIcons.square,
    CanvasObjectType.diamond: LucideIcons.diamond,
    CanvasObjectType.oblong: LucideIcons.rectangleHorizontal,
    CanvasObjectType.circle: LucideIcons.circle,
    CanvasObjectType.rhombus: LucideIcons.diamond,
    CanvasObjectType.trapezoid: LucideIcons.pentagon,
    CanvasObjectType.cylinder: LucideIcons.cylinder,
    CanvasObjectType.house: LucideIcons.house,
    CanvasObjectType.reverseHouse: LucideIcons.house,
  };

  IconData _getShapeIcon(CanvasObjectType shapeType) =>
      _shapeIcons[shapeType] ?? LucideIcons.square;

  void _onShapeSelected(CanvasObjectType shapeType) {
    final paletteState = ref.read(headlessProvider);
    if (paletteState.headlessArrow == null) return;

    final arrow = paletteState.headlessArrow!;
    final ghostObject = paletteState.ghostObject!;

    // Get the arrow direction from the last segment
    final keypoints = arrow.arrowProps.points;
    if (arrow.arrowProps.points.isEmpty || !paletteState.hasGhostObject) {
      CanvasInteractionService.closeHeadlessPalette(ref: ref);
      return;
    }

    Offset arrowDirection;
    ConnectionPoint connectionPoint;

    final lastSegment = keypoints.last - keypoints[keypoints.length - 2];
    arrowDirection = Offset(lastSegment.dx, lastSegment.dy).normalized();

    // Determine connection point based on arrow direction
    if (arrowDirection.dx.abs() > arrowDirection.dy.abs()) {
      connectionPoint = arrowDirection.dx > 0
          ? ConnectionPoint.left
          : ConnectionPoint.right;
    } else {
      connectionPoint = arrowDirection.dy > 0
          ? ConnectionPoint.top
          : ConnectionPoint.bottom;
    }

    ghostObject.color = ThemeHelper.neutral900(context);
    ref.read(canvasObjectsProvider.notifier).addObject(ghostObject);

    arrow.arrowProps.endObjectId = ghostObject.id;
    arrow.arrowProps.endPoint = connectionPoint;
    arrow.drawNewKeypoints(ref);
    arrow.pruneKeypoints();

    ref.read(canvasObjectsProvider.notifier).updateObjects();
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    ref.read(canvasObjectsProvider.notifier).selectObject(ghostObject);
    ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
    ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
    CanvasInteractionService.openTextEditor(ref: ref);
  }

  void _onItemSelected(Artifact item) {
    final paletteState = ref.read(headlessProvider);
    if (paletteState.headlessArrow == null) return;

    final arrow = paletteState.headlessArrow!;
    final ghostObject = paletteState.ghostObject!;

    // Get the arrow direction from the last segment
    final keypoints = arrow.arrowProps.points;
    if (arrow.arrowProps.points.isEmpty || !paletteState.hasGhostObject) {
      CanvasInteractionService.closeHeadlessPalette(ref: ref);
      return;
    }

    Offset arrowDirection;
    ConnectionPoint connectionPoint;

    final lastSegment = keypoints.last - keypoints[keypoints.length - 2];
    arrowDirection = Offset(lastSegment.dx, lastSegment.dy).normalized();

    // Determine connection point based on arrow direction
    if (arrowDirection.dx.abs() > arrowDirection.dy.abs()) {
      connectionPoint = arrowDirection.dx > 0
          ? ConnectionPoint.left
          : ConnectionPoint.right;
    } else {
      connectionPoint = arrowDirection.dy > 0
          ? ConnectionPoint.top
          : ConnectionPoint.bottom;
    }

    ghostObject.color = Colors.transparent;
    ref.read(canvasObjectsProvider.notifier).addObject(ghostObject);

    arrow.arrowProps.endObjectId = ghostObject.id;
    arrow.arrowProps.endPoint = connectionPoint;
    arrow.drawNewKeypoints(ref);
    arrow.pruneKeypoints();

    ref.read(canvasObjectsProvider.notifier).updateObjects();
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    ref.read(canvasObjectsProvider.notifier).selectObject(ghostObject);
    ref.read(canvasGestureStateProvider.notifier).resetInteraction(ref);
    ref.read(toolModeProvider.notifier).set(ToolMode.pointer);
  }

  @override
  Widget build(BuildContext context) {
    final paletteState = ref.watch(headlessProvider);

    if (!paletteState.isVisible) return const SizedBox.shrink();

    final config = ref.watch(canvasConfigProvider);

    // Different layouts for flow vs other canvas types
    if (config.canvasType == CanvasType.flow) {
      return _buildNotesPaletteLayout(paletteState);
    } else {
      return _buildShapesPaletteLayout(paletteState);
    }
  }

  Widget _buildShapesPaletteLayout(HeadlessState paletteState) {
    // Calculate menu dimensions (original logic for shapes)
    final menuHeight =
        shapePaletteSize.height + addSectionSize.height + borderWidth * 2;
    final menuWidth = shapePaletteSize.width + borderWidth * 2;

    // Calculate arrow direction from last two keypoints to determine menu offset
    double offsetX = 0;
    double offsetY = 0;

    final arrowKeypoints = widget.arrow.arrowProps.points;
    if (arrowKeypoints.isEmpty) return const SizedBox.shrink();

    final direction =
        arrowKeypoints.last - arrowKeypoints[arrowKeypoints.length - 2];

    if (direction.dx > 0) {
      // Arrow going right, offset menu left
      offsetX = -menuSpacingX;
    } else if (direction.dx < 0) {
      // Arrow going left, offset menu right
      offsetX = menuSpacingX;
    }

    if (direction.dy > 0) {
      // Arrow going down, offset menu up
      offsetY = -menuSpacingY;
    } else if (direction.dy < 0) {
      // Arrow going up, offset menu down
      offsetY = menuSpacingY;
    }

    final lastKeypoint = ref
        .read(canvasViewportProvider.notifier)
        .convertToScreenCoords(arrowKeypoints.last);
    final desiredX = lastKeypoint.dx - menuWidth / 2 + offsetX;
    final desiredY = lastKeypoint.dy - menuHeight + offsetY;

    // Get viewport dimensions
    final screenSize = MediaQuery.of(context).size;
    final viewportWidth = screenSize.width;
    final viewportHeight = screenSize.height;

    // Define margin from viewport edges
    const double viewportMargin = 16.0;

    // Constrain X position to viewport
    final viewportMinX = viewportMargin;
    final viewportMaxX = viewportWidth - menuWidth - viewportMargin;
    final x = desiredX.clamp(viewportMinX, viewportMaxX);

    // Constrain Y position to viewport
    final viewportMinY = viewportMargin;
    final viewportMaxY = viewportHeight - menuHeight - viewportMargin;
    final y = desiredY.clamp(viewportMinY, viewportMaxY);

    return Stack(
      children: [
        // Full-screen gesture detector to detect clicks outside palette
        Positioned.fill(
          child: GestureDetector(
            behavior: .translucent,
            onTapDown: (details) {
              // Check if tap is outside the palette bounds
              final tapX = details.globalPosition.dx;
              final tapY = details.globalPosition.dy;

              final paletteLeft = x;
              final paletteRight = x + menuWidth;
              final paletteTop = y;
              final paletteBottom = y + menuHeight;

              final isOutsidePalette =
                  tapX < paletteLeft ||
                  tapX > paletteRight ||
                  tapY < paletteTop ||
                  tapY > paletteBottom;

              if (isOutsidePalette) {
                final paletteState = ref.read(headlessProvider);
                if (paletteState.headlessArrow == null) return;

                final arrow = paletteState.headlessArrow!;
                ref.read(canvasObjectsProvider.notifier).deleteObject(arrow);
                ref
                    .read(canvasGestureStateProvider.notifier)
                    .resetInteraction(ref);
              }
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        // The actual shapes palette
        Positioned(
          left: x,
          top: y,
          child: Material(
            elevation: 8,
            borderRadius: .circular(buttonBorderRadius),
            color: ThemeHelper.neutral900(context),
            child: Container(
              decoration: BoxDecoration(
                border: .all(
                  color: ThemeHelper.neutral600(context),
                  width: borderWidth,
                ),
                borderRadius: .circular(buttonBorderRadius),
              ),
              child: Column(
                mainAxisSize: .min,
                children: [
                  // Shapes palette
                  Container(
                    padding: .all(menuPadding),
                    child: _buildShapesPalette(),
                  ),
                  // Add section for shapes
                  Container(
                    height: addSectionSize.height,
                    width: addSectionSize.width,
                    decoration: BoxDecoration(
                      color: ThemeHelper.neutral400(
                        context,
                      ).withValues(alpha: 0.05),
                      borderRadius: .only(
                        bottomLeft: .circular(buttonBorderRadius),
                        bottomRight: .circular(buttonBorderRadius),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: .center,
                        children: [
                          if (paletteState.hoveredShapeType != null) ...[
                            Text(
                              'Add',
                              style: TextStyle(fontSize: 14, fontWeight: .w600),
                            ),
                            const Gap(4),
                            Icon(
                              _getShapeIcon(paletteState.hoveredShapeType!),
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesPaletteLayout(HeadlessState paletteState) {
    final arrowKeypoints = widget.arrow.arrowProps.points;
    if (arrowKeypoints.isEmpty) return const SizedBox.shrink();

    // Get arrow position for positioning the menu
    final lastKeypoint = ref
        .read(canvasViewportProvider.notifier)
        .convertToScreenCoords(arrowKeypoints.last);

    // Calculate arrow direction for basic positioning offset
    final direction =
        arrowKeypoints.last - arrowKeypoints[arrowKeypoints.length - 2];
    double offsetX = direction.dx > 0
        ? -50
        : 50; // Simple offset, no fixed calculations
    double offsetY = direction.dy > 0 ? -50 : 50;

    final desiredX = lastKeypoint.dx + offsetX;
    final desiredY = lastKeypoint.dy + offsetY;

    // Get viewport dimensions for boundary constraints
    final screenSize = MediaQuery.of(context).size;
    const double viewportMargin = 16.0;

    return Stack(
      children: [
        // Full-screen gesture detector to detect clicks outside palette
        Positioned.fill(
          child: GestureDetector(
            behavior: .translucent,
            onTapDown: (details) {
              // Close palette when clicking outside (simplified logic)
              final paletteState = ref.read(headlessProvider);
              if (paletteState.headlessArrow == null) return;

              final arrow = paletteState.headlessArrow!;
              ref.read(canvasObjectsProvider.notifier).deleteObject(arrow);
              ref
                  .read(canvasGestureStateProvider.notifier)
                  .resetInteraction(ref);
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        // Notes palette with right-click menu styling
        Positioned(
          left: desiredX.clamp(
            viewportMargin,
            screenSize.width - 250 - viewportMargin,
          ),
          top: desiredY.clamp(
            viewportMargin,
            screenSize.height - 300 - viewportMargin,
          ),
          child: IntrinsicHeight(
            child: IntrinsicWidth(
              child: Material(
                elevation: 12,
                shadowColor: ThemeHelper.white(context).withValues(alpha: 0.15),
                borderRadius: .circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeHelper.neutral900(context),
                    borderRadius: .circular(8),
                    border: .all(
                      color: ThemeHelper.neutral500(
                        context,
                      ).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: .symmetric(vertical: 8),
                    child: _buildNotesPalette(paletteState),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesPalette(HeadlessState paletteState) {
    if (!paletteState.hasChildren) {
      return Container(
        padding: .all(16),
        child: Text(
          'No child notes available',
          style: TextStyle(
            fontSize: 14,
            color: ThemeHelper.neutral500(context),
          ),
          textAlign: .center,
        ),
      );
    }

    // Show notes in a scrollable column with right-click menu styling
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 400,
        minWidth: 200,
        maxWidth: 300,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: paletteState.children!
              .map((item) => _buildMenuItem(item))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(Artifact item) {
    final isHovered = ref.watch(headlessProvider).hoveredItem == item;
    final itemTitle = item.name.isEmpty ? 'Untitled' : item.name;

    return MouseRegion(
      onEnter: (_) =>
          ref.read(headlessProvider.notifier).setHoveredItem(context, item),
      onExit: (_) =>
          ref.read(headlessProvider.notifier).setHoveredItem(context, null),
      child: GestureDetector(
        onTap: () => _onItemSelected(item),
        child: Container(
          height: 40,
          margin: .symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isHovered
                ? ThemeHelper.neutral700(context)
                : Colors.transparent,
            borderRadius: .circular(6),
          ),
          child: Padding(
            padding: .symmetric(horizontal: 12, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: ThemeHelper.neutral300(context),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    itemTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: .w500,
                      color: ThemeHelper.neutral300(context),
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapesPalette() {
    return Column(
      mainAxisSize: .min,
      children: [
        Row(
          mainAxisSize: .min,
          children: shapeOptions
              .sublist(0, 5)
              .map((shapeType) => _buildShapeButton(shapeType: shapeType))
              .toList(),
        ),
        Row(
          mainAxisSize: .min,
          children: shapeOptions
              .sublist(5)
              .map((shapeType) => _buildShapeButton(shapeType: shapeType))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildShapeButton({required CanvasObjectType shapeType}) {
    return Container(
      margin: .all(menuPadding),
      child: MouseRegion(
        onEnter: (_) => ref
            .read(headlessProvider.notifier)
            .setHoveredShape(context, shapeType),
        onExit: (_) =>
            ref.read(headlessProvider.notifier).setHoveredShape(context, null),
        child: OnyxiaIconButton(
          icon: _getShapeIcon(shapeType),
          onPressed: () => _onShapeSelected(shapeType),
          size: iconSize.width,
        ),
      ),
    );
  }
}
