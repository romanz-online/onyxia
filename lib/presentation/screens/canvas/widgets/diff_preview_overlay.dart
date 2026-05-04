import 'package:onyxia/export.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../providers/providers.dart';
import '../gestures/gestures.dart';
import 'painter/canvas_painter.dart';
import 'canvas_object_text_areas.dart';
import 'canvas_pin.dart';

class DiffPreviewOverlay extends ConsumerWidget {
  final VoidCallback? onCanvasReload;

  const DiffPreviewOverlay({super.key, this.onCanvasReload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyPreview = ref.watch(canvasDiffPreviewProvider);
    final projectId = ref.read(projectsProvider).selectedProject.id;
    final canvasId = ref.read(currentCanvasProvider)?.id ?? '';
    final config = ref.watch(canvasConfigProvider);

    final params = HistoryDiffsParams(
      projectId: projectId,
      itemId: canvasId,
      itemType: ArtifactType.canvas,
    );
    final selectedDiff = ref.read(historyDiffsProvider(params)).selectedDiff;

    if (historyPreview == null || selectedDiff == null) {
      return const SizedBox.shrink();
    }

    final previewObjects = historyPreview.objects;
    // final previewComments = historyPreview.comments;
    final previewPins = historyPreview.pins;
    final isRestoring = historyPreview.isRestoring;

    final dummyGestureRouter = CanvasGestureRouter(
      ref: ref,
      context: context,
      canvasConfig: config,
    );

    final transformationController = ref.watch(canvasViewportProvider);

    return Stack(
      children: [
        // completely hide original canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          color: ThemeHelper.white(context),
        ),

        InteractiveViewer(
          transformationController: transformationController,
          minScale: 0.1,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: Stack(
            children: [
              // Render historical background image or grid pattern
              Positioned.fill(
                child: Consumer(
                  builder: (context, ref, child) {
                    final canvasBounds = ref.watch(canvasBoundsProvider);
                    final historicalImageUrl = historyPreview.imageUrl;

                    return _HistoricalBackgroundWidget(
                      canvasBounds: canvasBounds,
                      historicalImageUrl: historicalImageUrl,
                    );
                  },
                ),
              ),
              // Use exact same object rendering structure as whiteboard_screen
              Consumer(
                builder: (context, ref, child) {
                  final canvasBounds = ref.watch(canvasBoundsProvider).bounds;
                  final objectTextState = ref.watch(canvasTextProvider);

                  return Stack(
                    children: [
                      // Non-interactive canvas content
                      AbsorbPointer(
                        absorbing: true, // Block interactions for canvas objects
                        child: SizedBox(
                          width: canvasBounds.width,
                          height: canvasBounds.height,
                          child: Stack(
                            children: [
                              // Paint overlay elements (selection, drag, alignment, etc.)
                              IgnorePointer(
                                ignoring: true,
                                child: CustomPaint(
                                  size: canvasBounds.size,
                                  painter: CanvasPainter(
                                    ref: ref,
                                    context: context,
                                    gestureRouter: null, // No gestures in preview
                                    objects: previewObjects,
                                    selectedObjects: [], // No selections in preview
                                    draggedObjects: [], // No dragging in preview
                                    textEditedObjId: null, // No editing in preview
                                    usersCursors: [], // No user cursors in preview
                                  ),
                                ),
                              ),
                              // First loop: Visual elements for non-arrow objects
                              ...previewObjects.where((e) => !e.isArrow).map(
                                (obj) {
                                  return CanvasObjectTextArea(
                                    canvasObject: obj,
                                    context: context,
                                    objectTextState: objectTextState,
                                    gestureRouter: dummyGestureRouter,
                                    onTextKeyPress: (_) {},
                                  );
                                },
                              ),
                              // Second arrows loop: Interactive elements (disabled in preview)
                              ...previewObjects.where((e) => e.isArrow).map(
                                    (obj) => CanvasArrowTextArea(
                                      context: context,
                                      canvasObject: obj,
                                      gestureRouter: dummyGestureRouter,
                                      objectTextState: objectTextState,
                                      onTextKeyPress: (_) {},
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      // Interactive pins layer (separate from blocked content)
                      SizedBox(
                        width: canvasBounds.width,
                        height: canvasBounds.height,
                        child: Stack(
                          children: [
                            // Render historical pins (interactive in preview)
                            ...previewPins.map(
                              (pin) {
                                CanvasObject? targetObject;
                                if (pin.pinnedObjectId != null) {
                                  targetObject = previewObjects.firstWhereOrNull(
                                    (obj) => obj.id == pin.pinnedObjectId,
                                  );
                                }

                                return CanvasPin(
                                  pin: pin,
                                  canvasObject: targetObject,
                                  position: pin.getOffset(parent: targetObject),
                                  transformationController: transformationController,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // Gray sheen overlay to slightly dim the preview
        IgnorePointer(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.1),
          ),
        ),

        // Preview indicator UI
        if (!isRestoring)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeHelper.blue500(context).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: ThemeHelper.neutral900(context).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    color: ThemeHelper.white(context),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Previewing: ${selectedDiff.title.isNotEmpty ? selectedDiff.title : DateFormat.yMd().add_jm().format(selectedDiff.timestamp)}',
                    style: NarwhalTextStyle(
                      color: ThemeHelper.white(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _restoreDiff(
                      ref,
                      historyPreview,
                      selectedDiff,
                      onCanvasReload,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeHelper.green().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: ThemeHelper.green().withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Restore',
                        style: NarwhalTextStyle(
                          color: ThemeHelper.neutral100(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Loading spinner overlay when restoring
        if (isRestoring)
          Center(
            child: NarwhalSpinner(),
          ),
      ],
    );
  }

  void _restoreDiff(
    WidgetRef ref,
    CanvasDiffPreview preview,
    HistoryDiff targetDiff,
    VoidCallback? onCanvasReload,
  ) async {
    if (preview.isRestoring) return;

    final projectId = ref.read(projectsProvider).selectedProject.id;
    final currentCanvas = ref.read(currentCanvasProvider);

    try {
      await HistoryService.restore(
        ref: ref,
        projectId: projectId,
        targetDiff: targetDiff,
        serializer: CanvasSerializerService(
          canvasId: currentCanvas?.id ?? '',
          projectId: projectId,
          repository: ArtifactsRepository(projectId: projectId),
        ),
      );

      // Only reload canvas if it's a markup canvas and callback is provided
      if (currentCanvas?.canvasType == CanvasType.markup && onCanvasReload != null) {
        onCanvasReload();
      }
    } catch (e) {
      debugPrint('Failed to restore diff: $e');
    }
  }
}

class _HistoricalBackgroundWidget extends StatefulWidget {
  final CanvasBounds canvasBounds;
  final String? historicalImageUrl;

  const _HistoricalBackgroundWidget({
    required this.canvasBounds,
    required this.historicalImageUrl,
  });

  @override
  State<_HistoricalBackgroundWidget> createState() => _HistoricalBackgroundWidgetState();
}

class _HistoricalBackgroundWidgetState extends State<_HistoricalBackgroundWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = false;
  bool _hasError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_HistoricalBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalImageUrl != widget.historicalImageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _loadImage() {
    if (widget.historicalImageUrl == null || widget.historicalImageUrl!.isEmpty) {
      setState(() {
        _loadedImage = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // Cancel any existing timeout timer
    _timeoutTimer?.cancel();

    // Check if image is already available synchronously
    final syncImage = ImageService.getImageSync(widget.historicalImageUrl!);
    if (syncImage != null) {
      setState(() {
        _loadedImage = syncImage;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // Start loading state and timeout timer
    setState(() {
      _loadedImage = null;
      _isLoading = true;
      _hasError = false;
    });

    // Start 10-second timeout timer
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });

    // Start async loading process
    _loadImageAsync();
  }

  void _loadImageAsync() async {
    try {
      // Continuously check for the image to load
      while (_isLoading && mounted) {
        final image = ImageService.getImageSync(widget.historicalImageUrl!);
        if (image != null) {
          if (mounted) {
            setState(() {
              _loadedImage = image;
              _isLoading = false;
              _hasError = false;
            });
          }
          _timeoutTimer?.cancel();
          return;
        }
        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      _timeoutTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background layer
        if (!_isLoading)
          NarwhalPaint(
            backgroundColor: ThemeHelper.neutral200(context),
            painter: _HistoricalBackgroundPainter(
              canvasBounds: widget.canvasBounds,
              loadedImage: _loadedImage,
              context: context,
            ),
          ),
        // Loading spinner overlay
        if (_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeHelper.black(context).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ThemeHelper.white(context)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading historical image...',
                    style: NarwhalTextStyle(
                      color: ThemeHelper.neutral100(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Error message overlay
        if (_hasError)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeHelper.red().withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ThemeHelper.white(context),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load historical image',
                    style: NarwhalTextStyle(
                      color: ThemeHelper.white(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Image could not be loaded after 10 seconds',
                    style: NarwhalTextStyle(
                      color: ThemeHelper.white(context).withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoricalBackgroundPainter extends NarwhalPainter {
  final CanvasBounds canvasBounds;
  final ui.Image? loadedImage;

  _HistoricalBackgroundPainter({
    required this.canvasBounds,
    required this.loadedImage,
    required BuildContext context,
  }) : super(context);

  @override
  void paint(Canvas canvas, Size size) {
    if (loadedImage != null) {
      // Draw the centered historical background image
      final double imageWidth = loadedImage!.width.toDouble();
      final double imageHeight = loadedImage!.height.toDouble();

      final double centerX = canvasBounds.bounds.width / 2;
      final double centerY = canvasBounds.bounds.height / 2;

      final double left = centerX - (imageWidth / 2);
      final double top = centerY - (imageHeight / 2);

      // Use a default Paint for image drawing
      canvas.drawImage(
        loadedImage!,
        Offset(left, top),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.low,
      );
      return;
    }

    if (canvasBounds.isLoading) {
      // Background color is handled by NarwhalPaint's Material widget
      // Nothing to paint during loading
    } else {
      // Draw the dot grid for whiteboard canvases (fallback)
      final Paint paint = createThemePaint(
        (context) => ThemeHelper.neutral500(context).withValues(alpha: 0.5),
        strokeWidth: 2.0,
        strokeCap: StrokeCap.round,
      );

      final List<Offset> points = [];
      for (double x = canvasBounds.bounds.left; x < canvasBounds.bounds.right; x += CanvasBounds.gridSpacing) {
        for (double y = canvasBounds.bounds.top; y < canvasBounds.bounds.bottom; y += CanvasBounds.gridSpacing) {
          points.add(Offset(x, y));
        }
      }

      canvas.drawPoints(ui.PointMode.points, points, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! _HistoricalBackgroundPainter) {
      return true;
    }
    return canvasBounds != oldDelegate.canvasBounds || loadedImage != oldDelegate.loadedImage;
  }
}
