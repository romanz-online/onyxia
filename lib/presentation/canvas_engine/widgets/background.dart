import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'dart:ui' as ui;

class Background extends ConsumerStatefulWidget {
  final CanvasArtifact canvas;
  const Background({super.key, required this.canvas});

  @override
  ConsumerState<Background> createState() => BackgroundState();
}

class BackgroundState extends ConsumerState<Background>
    with WidgetsBindingObserver {
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    try {
      final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);

      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          canvasBoundsNotifier.stopAnimation();
          break;
        case AppLifecycleState.resumed:
          canvasBoundsNotifier.resumeAnimation();
          break;
        case AppLifecycleState.detached:
          canvasBoundsNotifier.stopAnimation();
          break;
        case AppLifecycleState.hidden:
          canvasBoundsNotifier.stopAnimation();
          break;
      }
    } catch (e) {
      // Ignore errors during disposal
      debugPrint('Error in didChangeAppLifecycleState: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed) {
      // Return a simple container if disposed
      return Container(
        color: ThemeHelper.neutral200(context),
      );
    }

    try {
      final canvasBounds = ref.watch(canvasBoundsProvider);
      final currentCanvas = widget.canvas;

      // Show loading indicator while bounds are being initialized
      if (canvasBounds.isLoading) {
        return Container(
          color: ThemeHelper.neutral200(context),
          child: Center(
            child: NarwhalSpinner(),
          ),
        );
      }

      // For markup canvases, show loading indicator if image is expected but not loaded yet
      if (currentCanvas.canvasType == CanvasType.markup &&
          currentCanvas.imageUrl != null &&
          currentCanvas.imageUrl!.isNotEmpty &&
          canvasBounds.backgroundImage == null &&
          !canvasBounds.hasError) {
        return Container(
          color: ThemeHelper.neutral200(context),
          child: Center(
            child: NarwhalSpinner(),
          ),
        );
      }

      return RepaintBoundary(
        child: NarwhalPaint(
          backgroundColor: ThemeHelper.neutral200(context),
          painter: _CanvasBackgroundPainter(
            canvasBounds: canvasBounds,
            context: context,
          ),
        ),
      );
    } catch (e) {
      // Return fallback container if ref access fails
      debugPrint('Canvas background build error: $e');
      return Container(color: ThemeHelper.neutral200(context));
    }
  }
}

class _CanvasBackgroundPainter extends NarwhalPainter {
  final CanvasBounds canvasBounds;

  _CanvasBackgroundPainter({
    required this.canvasBounds,
    required BuildContext context,
  }) : super(context);

  /// Create dots using NarwhalPainter convenience methods
  ui.Picture _createDotsPicture(Rect bounds) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, bounds);

    final Paint paint = createThemePaint(
      (context) => ThemeHelper.neutral500(context).withValues(alpha: 0.5),
      strokeWidth: 2.0,
      strokeCap: StrokeCap.round,
    );

    final List<Offset> points = [];
    for (double x = bounds.left;
        x < bounds.right;
        x += CanvasBounds.gridSpacing) {
      for (double y = bounds.top;
          y < bounds.bottom;
          y += CanvasBounds.gridSpacing) {
        points.add(Offset(x, y));
      }
    }

    canvas.drawPoints(ui.PointMode.points, points, paint);

    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (canvasBounds.backgroundImage != null) {
        // Background color is handled by NarwhalPaint's Material widget
        // Draw the centered background image
        final image = canvasBounds.backgroundImage!;
        final double imageWidth = image.width.toDouble();
        final double imageHeight = image.height.toDouble();

        final double centerX = canvasBounds.bounds.width / 2;
        final double centerY = canvasBounds.bounds.height / 2;

        final double left = centerX - (imageWidth / 2);
        final double top = centerY - (imageHeight / 2);

        canvas.drawImage(
          image,
          Offset(left, top),
          Paint()
            ..isAntiAlias = false
            ..filterQuality = FilterQuality.high,
        );
      } else if (canvasBounds.isLoading) {
        // Background color is handled by NarwhalPaint's Material widget
        // Nothing to paint during loading
      } else if (canvasBounds.hasError) {
        // Draw error state - fallback to dot grid
        NarwhalToast.show(type: ToastType.error, text: 'Error loading image');
      } else {
        // Draw the dot grid for whiteboard canvases
        // Use the new instance method that leverages NarwhalPainter
        canvas.drawPicture(_createDotsPicture(canvasBounds.bounds));
      }
    } catch (e) {
      // Fallback to dot grid on any painting error
      debugPrint('Canvas background paint error: $e');
      try {
        canvas.drawPicture(_createDotsPicture(canvasBounds.bounds));
      } catch (fallbackError) {
        debugPrint('Canvas background fallback paint error: $fallbackError');
        // Last resort - do nothing, let the background color show
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! _CanvasBackgroundPainter) return true;

    return canvasBounds != oldDelegate.canvasBounds;
  }
}
