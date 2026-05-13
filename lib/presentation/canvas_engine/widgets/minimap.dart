import 'package:onyxia/export.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../providers/providers.dart';

class Minimap extends ConsumerStatefulWidget {
  final CanvasArtifact canvas;
  const Minimap({super.key, required this.canvas});

  @override
  MinimapState createState() => MinimapState();
}

class MinimapState extends ConsumerState<Minimap> {
  bool _imagesPreloaded = false;
  List<String> _lastImageUrls = [];
  final double _baseMinimapSize = 200.0;
  final double _zoomControlsHeight = 32.0;
  bool _isExpandHovered = false;

  void zoomIn() {
    if (!mounted) return;
    try {
      ref.read(canvasViewportProvider.notifier).updateZoom(increment: 0.05);
    } catch (e) {
      debugPrint('Minimap zoomIn error: $e');
    }
  }

  void zoomOut() {
    if (!mounted) return;
    try {
      ref.read(canvasViewportProvider.notifier).updateZoom(increment: -0.05);
    } catch (e) {
      debugPrint('Minimap zoomOut error: $e');
    }
  }

  /// Extract all image URLs that need to be preloaded
  List<String> _extractImageUrls(
    List<CanvasObject> objects,
    CanvasArtifact? currentCanvas,
  ) {
    final imageUrls = <String>[];

    // Add object images
    for (final object in objects) {
      if (object.isImage && object.imageProps.imageUrl.isNotEmpty) {
        imageUrls.add(object.imageProps.imageUrl);
      }
    }

    // Add markup canvas background image
    if (currentCanvas?.canvasType == CanvasType.markup &&
        currentCanvas?.imageUrl != null &&
        currentCanvas!.imageUrl!.isNotEmpty) {
      imageUrls.add(currentCanvas.imageUrl!);
    }

    return imageUrls;
  }

  /// Preload all required images
  Future<void> _preloadImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) {
      setState(() => _imagesPreloaded = true);
      return;
    }

    try {
      await ImageService.preloadImages(imageUrls);
      if (mounted) {
        setState(() => _imagesPreloaded = true);
      }
    } catch (e) {
      debugPrint('Error preloading minimap images: $e');
      if (mounted) {
        // Show minimap even if preload failed
        setState(() => _imagesPreloaded = true);
      }
    }
  }

  /// Check if two lists of strings are equal
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Calculate responsive scale factor by snapping to closest predefined resolution
  double get responsiveScale {
    final screenSize = MediaQuery.of(context).size;

    // Predefined resolutions with their scale factors (relative to 1920x1080)
    final resolutions = <Size, double>{
      const Size(1920, 1080): 1.0, // Base resolution
      const Size(1366, 768): 0.71, // 1366/1920 ≈ 0.71
      const Size(1536, 864): 0.8, // 1536/1920 = 0.8
      const Size(1280, 720): 0.67, // 1280/1920 ≈ 0.67
    };

    // Find the closest resolution by calculating distance
    Size closestResolution = const Size(1920, 1080);
    double minDistance = double.infinity;

    for (final resolution in resolutions.keys) {
      final distance = math.sqrt(
          math.pow(screenSize.width - resolution.width, 2) +
              math.pow(screenSize.height - resolution.height, 2));

      if (distance < minDistance) {
        minDistance = distance;
        closestResolution = resolution;
      }
    }

    return resolutions[closestResolution]!;
  }

  /// Get display bounds for minimap - uses image dimensions for markup, canvas bounds for others
  Size get displayBounds {
    final currentCanvas = widget.canvas;
    final canvasBoundsState = ref.watch(canvasBoundsProvider);
    final canvasBounds = canvasBoundsState.bounds;

    // Return canvas bounds while data is loading or for non-markup canvases
    if (canvasBoundsState.isLoading ||
        currentCanvas.canvasType != CanvasType.markup) {
      return canvasBounds.size;
    }

    // For markup canvases, use actual image dimensions if available
    final backgroundImage = canvasBoundsState.backgroundImage;
    if (backgroundImage != null) {
      return Size(
          backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    }

    // Fallback to canvas bounds if image not available
    return canvasBounds.size;
  }

  /// Calculate dynamic minimap size based on canvas type and bounds (base size before Transform.scale)
  Size get minimapSize {
    final currentCanvas = widget.canvas;
    final canvasBoundsState = ref.watch(canvasBoundsProvider);

    // Return default size while data is loading
    if (canvasBoundsState.isLoading) {
      return Size(_baseMinimapSize, _baseMinimapSize);
    }

    // For markup canvases, calculate size to maintain aspect ratio of the actual image
    if (currentCanvas.canvasType == CanvasType.markup) {
      final displaySize = displayBounds;
      final aspectRatio = displaySize.height / displaySize.width;
      final dynamicHeight = _baseMinimapSize * aspectRatio;
      return Size(_baseMinimapSize, dynamicHeight);
    }

    // Default size for all other canvas types (whiteboard)
    // Make it a perfect square including zoom controls
    final minimapHeight = _baseMinimapSize - _zoomControlsHeight; // 168
    return Size(_baseMinimapSize, minimapHeight); // 200×168
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    try {
      final showMinimap =
          ref.watch(canvasSettingsProvider(Setting.showMinimap));
      final objects = ref.watch(canvasObjectsProvider);
      final currentCanvas = widget.canvas;
      final canvasBoundsState = ref.watch(canvasBoundsProvider);
      final canvasBounds = canvasBoundsState.bounds;

      // Wait for canvas data to load before rendering minimap
      if (canvasBoundsState.isLoading) return const SizedBox.shrink();

      // For markup canvases, also wait for the background image to load
      if (currentCanvas.canvasType == CanvasType.markup &&
          currentCanvas.imageUrl != null &&
          currentCanvas.imageUrl!.isNotEmpty &&
          canvasBoundsState.backgroundImage == null &&
          !canvasBoundsState.hasError) {
        return const SizedBox.shrink(); // Hide minimap while image is loading
      }

      // Check if we need to preload images
      final imageUrls = _extractImageUrls(objects.objects, currentCanvas);
      final imageUrlsChanged = !_listEquals(_lastImageUrls, imageUrls);

      if (!_imagesPreloaded || imageUrlsChanged) {
        if (imageUrlsChanged) {
          _imagesPreloaded = false;
          _lastImageUrls = List.from(imageUrls);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadImages(imageUrls);
        });

        // Show loading indicator while preloading images
        return SizedBox(
          width: _baseMinimapSize,
          height: _baseMinimapSize,
          child: Center(
            child: NarwhalSpinner(),
          ),
        );
      }

      final Size currentMinimapSize = minimapSize;
      final Size currentDisplayBounds = displayBounds;
      final double scale =
          currentMinimapSize.width / currentDisplayBounds.width;

      // Get the current viewport size
      final viewportSize = MediaQuery.of(context).size;

      // Watch viewport to trigger rebuilds on pan/zoom
      ref.watch(canvasViewportProvider);

      // Get the visible region in object coordinates from the viewport provider
      final Rect visibleRegion = ref
          .read(canvasViewportProvider.notifier)
          .getVisibleObjectRect(viewportSize);
      final double rScale = 1.0; // responsiveScale;

      // If minimap is hidden, show only zoom controls with extended hover region
      if (!showMinimap) {
        return _buildHiddenZoomControls(rScale, currentMinimapSize);
      }

      return Transform.scale(
        scale: rScale,
        alignment: Alignment.bottomRight,
        child: Stack(
          children: [
            // Minimap - only show if showMinimap is true
            Positioned(
              // bottom = bottom margin + zoom controller height
              bottom: 20 + 32 / rScale,
              right: 20,
              child: Container(
                width: currentMinimapSize.width,
                height: currentMinimapSize.height,
                decoration: BoxDecoration(
                  color: ThemeHelper.neutral100(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.neutral900(context).withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: ThemeHelper.neutral400(context),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: ThemeHelper.neutral400(context),
                      width: 1,
                    ),
                    right: BorderSide(
                      color: ThemeHelper.neutral400(context),
                      width: 1,
                    ),
                    bottom: BorderSide.none,
                  ),
                ),
                child: Stack(
                  children: [
                    // Canvas objects
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                      child: NarwhalPaint(
                        size: currentMinimapSize,
                        painter: MinimapCanvasPainter(
                          ref: ref,
                          context: context,
                          objects: objects.objects,
                          selectedObjects: objects.selectedObjects,
                          currentCanvas: currentCanvas,
                          canvasBounds: canvasBounds,
                          scale: scale,
                        ),
                      ),
                    ),

                    // Viewport indicator
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                      child: NarwhalPaint(
                        size: currentMinimapSize,
                        painter: MinimapViewportPainter(
                          context: context,
                          visibleRegion: visibleRegion,
                          minimapScale: scale,
                        ),
                      ),
                    ),

                    // Draggable area for panning
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _handleMinimapPan(
                          details.localPosition,
                          viewportSize,
                          scale,
                        ),
                        onPanUpdate: (details) => _handleMinimapPan(
                          details.localPosition,
                          viewportSize,
                          scale,
                        ),
                      ),
                    ),

                    // X button to hide minimap
                    Positioned(
                      top: 4,
                      right: 4,
                      child: NarwhalIconButton(
                        icon: NarwhalIcons.close,
                        size: 20,
                        onPressed: () => ref
                            .read(canvasSettingsProvider(Setting.showMinimap)
                                .notifier)
                            .set(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom controls
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                width: currentMinimapSize.width,
                height: 32 / rScale,
                decoration: BoxDecoration(
                  color: ThemeHelper.neutral100(context),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  border: Border.all(
                    color: ThemeHelper.neutral400(context),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.neutral900(context).withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildZoomControls(currentMinimapSize),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Minimap build error: $e');
      return const SizedBox.shrink();
    }
  }

  /// Build zoom controls widget
  Widget _buildZoomControls(Size currentMinimapSize) {
    // Watch viewport to ensure zoom text updates
    ref.watch(canvasViewportProvider);
    final showMinimap = ref.read(canvasSettingsProvider(Setting.showMinimap));

    return Container(
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(showMinimap ? 0.0 : 10.0),
            topRight: Radius.circular(showMinimap ? 0.0 : 10.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(10.0),
          ),
        ),
        child: Row(
          children: [
            NarwhalIconButton(
              icon: NarwhalIcons.minus,
              onPressed: zoomOut,
            ),
            Container(width: 1, color: ThemeHelper.neutral400(context)),
            Expanded(
              child: InkWell(
                onTap: ref.read(canvasViewportProvider.notifier).reset,
                child: Container(
                  // Dynamic width minus buttons
                  width: currentMinimapSize.width - 68.0,
                  color: ThemeHelper.neutral200(context),
                  child: Center(
                    child: Text(
                      ref
                          .read(canvasViewportProvider.notifier)
                          .getCurrentZoomAsString(),
                      style: NarwhalTextStyle(
                        fontSize: 14.0,
                        color: ThemeHelper.neutral800(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 1, color: ThemeHelper.neutral400(context)),
            NarwhalIconButton(
              icon: NarwhalIcons.add,
              onPressed: zoomIn,
            ),
          ],
        ));
  }

  /// Build zoom controls only (when minimap is hidden) with extended hover region for up-arrow button
  Widget _buildHiddenZoomControls(double rScale, Size currentMinimapSize) {
    return Transform.scale(
      scale: rScale,
      alignment: Alignment.bottomRight,
      child: Stack(
        children: [
          // Extended hover detection region (zoom controls + 32px above)
          Positioned(
            bottom: 20,
            right: 20,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isExpandHovered = true),
              onExit: (_) => setState(() => _isExpandHovered = false),
              child: Container(
                width: currentMinimapSize.width,
                height: 64 / rScale, // 32px zoom controls + 32px above
                color: Colors.transparent,
              ),
            ),
          ),
          // Up-arrow button (positioned above zoom controls when hovered)
          if (_isExpandHovered)
            Positioned(
              bottom: 52 / rScale, // 20 + 32 (above zoom controls)
              // Centered horizontally (24 = button width)
              right: 20 + (currentMinimapSize.width - 24) / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isExpandHovered = true),
                onExit: (_) => setState(() => _isExpandHovered = false),
                child: NarwhalIconButton(
                  icon: NarwhalIcons.dropdownArrowUp,
                  size: 28,
                  onPressed: () => ref
                      .read(
                          canvasSettingsProvider(Setting.showMinimap).notifier)
                      .set(true),
                ),
              ),
            ),
          // Zoom controls
          Positioned(
            bottom: 20,
            right: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isExpandHovered = true),
              onExit: (_) => setState(() => _isExpandHovered = false),
              child: Container(
                width: currentMinimapSize.width,
                height: 32 / rScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    // This wraps the ZoomControls, which use Theme colors, not Theme-Canvas colors.
                    color: ThemeHelper.neutral400(context),
                    width: 1,
                  ),
                  color: ThemeHelper.neutral100(context),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.black(context).withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildZoomControls(currentMinimapSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMinimapPan(
      Offset position, Size viewportSize, double minimapScale) {
    final bounds = ref.read(canvasBoundsProvider).bounds;

    // Convert minimap click to object coordinates (image-relative for markup,
    // canvas-relative for whiteboard)
    final objectX = position.dx / minimapScale;
    final objectY = position.dy / minimapScale;

    // Convert object coords to content/InteractiveViewer coords via bounds origin.
    // bounds.left is negative for markup (e.g. -marginX), so subtracting it adds the offset.
    final contentX = objectX - bounds.left;
    final contentY = objectY - bounds.top;

    final viewportCenterX = viewportSize.width / 2;
    final viewportCenterY = viewportSize.height / 2;

    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();

    ref
        .read(canvasViewportProvider.notifier)
        .setTransformation(Matrix4.identity()
          ..translateByDouble(viewportCenterX - contentX * scale,
              viewportCenterY - contentY * scale, 0.0, 1.0)
          ..scaleByDouble(scale, scale, scale, 1.0));
  }
}

class MinimapCanvasPainter extends NarwhalPainter {
  final WidgetRef ref;
  final List<CanvasObject> objects;
  final List<CanvasObject> selectedObjects;
  final CanvasArtifact? currentCanvas;
  final Rect canvasBounds;
  final double scale;

  MinimapCanvasPainter({
    required this.ref,
    required BuildContext context,
    required this.objects,
    required this.selectedObjects,
    this.currentCanvas,
    required this.canvasBounds,
    required this.scale,
  }) : super(context);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale, scale);

    _drawMarkupImage(canvas);

    final strokePaint = Paint()
      ..color = ThemeHelper.neutral900(context)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final object in objects) {
      final fillPaint = Paint()
        ..color = object.color
        ..style = PaintingStyle.fill;

      switch (object.type) {
        case CanvasObjectType.circle:
          _drawCircle(canvas, object, fillPaint);
          break;
        case CanvasObjectType.brush:
          _drawBrush(canvas, object, fillPaint);
          break;
        // case ObjectType.triangle:
        //   _drawTriangle(canvas, object, fillPaint);
        //   break;
        // case ObjectType.line:
        // case ObjectType.dashedLine:
        // case ObjectType.dotDashLine:
        //   _drawLine(canvas, object, fillPaint);
        //   break;
        case CanvasObjectType.arrow:
          _drawArrow(canvas, object);
          break;
        case CanvasObjectType.image:
          _drawImage(canvas, object, fillPaint, strokePaint);
          break;
        default:
          _drawRectangle(canvas, object, fillPaint, strokePaint);
          break;
      }
    }
  }

  void _drawCircle(Canvas canvas, CanvasObject object, Paint paint) {
    final center = Offset(
      (object.topLeft.dx + object.bottomRight.dx) / 2,
      (object.topLeft.dy + object.bottomRight.dy) / 2,
    );
    final width = (object.bottomRight.dx - object.topLeft.dx).abs();
    final height = (object.bottomRight.dy - object.topLeft.dy).abs();
    final ovalRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    canvas.drawOval(ovalRect, paint);
  }

  void _drawRectangle(
      Canvas canvas, CanvasObject object, Paint fillPaint, Paint strokePaint) {
    canvas.drawRect(
      Rect.fromPoints(object.topLeft, object.bottomRight),
      fillPaint,
    );

    if (object.stroke != StrokeType.none) {
      canvas.drawRect(
        Rect.fromPoints(object.topLeft, object.bottomRight),
        strokePaint,
      );
    }
  }

  void _drawBrush(Canvas canvas, CanvasObject object, Paint paint) {
    if (!object.isBrush || object.brushProps.points.isEmpty) return;

    Paint paint = Paint()
      ..strokeWidth = 5
      ..color = object.color
      ..style = PaintingStyle.stroke;

    final points = object.brushProps.points;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, CanvasObject object) {
    if (!object.isArrow || object.arrowProps.points.isEmpty) return;

    Paint paint = Paint()
      ..strokeWidth = 5
      ..color = object.color
      ..style = PaintingStyle.stroke;

    final points = object.arrowProps.points;

    if (points.isEmpty) return;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawImage(
    Canvas canvas,
    CanvasObject object,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    if (!object.isImage) return;

    // Get preloaded image synchronously - images are guaranteed to be cached
    final image = ImageService.getImageSync(object.imageProps.imageUrl);
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromPoints(object.topLeft, object.bottomRight),
        Paint(),
      );
    }
  }

  void _drawMarkupImage(Canvas canvas) {
    if (currentCanvas?.canvasType != CanvasType.markup ||
        currentCanvas?.imageUrl == null ||
        currentCanvas!.imageUrl!.isEmpty) {
      return;
    }

    // Get the image from canvasBoundsProvider instead of ImageLoader cache
    final canvasBoundsState = ref.read(canvasBoundsProvider);
    final ui.Image? image = canvasBoundsState.backgroundImage;

    if (image != null) {
      // For markup canvases, draw the image to fill the entire scaled area
      // Since the minimap scale is now based on image dimensions, draw from (0,0) to image size
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      // Draw image to fill its natural dimensions in the scaled canvas
      final destRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        destRect,
        Paint(),
      );
    }
  }

  @override
  bool shouldRepaint(MinimapCanvasPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.selectedObjects != selectedObjects ||
        oldDelegate.currentCanvas != currentCanvas ||
        oldDelegate.canvasBounds != canvasBounds ||
        oldDelegate.scale != scale;
  }
}

class MinimapViewportPainter extends NarwhalPainter {
  final Rect visibleRegion;
  final double minimapScale;

  MinimapViewportPainter({
    required this.visibleRegion,
    required this.minimapScale,
    required BuildContext context,
  }) : super(context);

  @override
  void paint(Canvas canvas, Size size) {
    // visibleRegion is already in object coordinates (image-relative for markup,
    // canvas-relative for whiteboard), so no special per-type handling needed.
    final viewportRect = Rect.fromLTWH(
      visibleRegion.left * minimapScale,
      visibleRegion.top * minimapScale,
      visibleRegion.width * minimapScale,
      visibleRegion.height * minimapScale,
    );

    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = ThemeHelper.blue400(context).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = ThemeHelper.blue400(context)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(MinimapViewportPainter oldDelegate) {
    return oldDelegate.visibleRegion != visibleRegion ||
        oldDelegate.minimapScale != minimapScale;
  }
}
