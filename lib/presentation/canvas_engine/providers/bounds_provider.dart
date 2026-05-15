import 'package:onyxia/export.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';

class CanvasBounds {
  final Rect bounds;
  final ui.Image? backgroundImage;
  final ui.Codec? backgroundCodec;
  final bool isAnimated;
  final int frameCount;
  final int currentFrame;
  final bool isLoading;
  final bool hasError;
  final double marginX;
  final double marginY;
  static const double gridSpacing = 18.0;
  static const double margin = 400.0;
  static const Rect defaultBounds = Rect.fromLTWH(0, 0, 5000, 5000);

  const CanvasBounds({
    required this.bounds,
    this.backgroundImage,
    this.backgroundCodec,
    this.isAnimated = false,
    this.frameCount = 1,
    this.currentFrame = 0,
    this.isLoading = false,
    this.hasError = false,
    this.marginX = 0.0,
    this.marginY = 0.0,
  });

  CanvasBounds copyWith({
    Rect? bounds,
    ui.Image? backgroundImage,
    ui.Codec? backgroundCodec,
    bool? isAnimated,
    int? frameCount,
    int? currentFrame,
    bool? isLoading,
    bool? hasError,
    double? marginX,
    double? marginY,
  }) {
    return CanvasBounds(
      bounds: bounds ?? this.bounds,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundCodec: backgroundCodec ?? this.backgroundCodec,
      isAnimated: isAnimated ?? this.isAnimated,
      frameCount: frameCount ?? this.frameCount,
      currentFrame: currentFrame ?? this.currentFrame,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      marginX: marginX ?? this.marginX,
      marginY: marginY ?? this.marginY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasBounds &&
          runtimeType == other.runtimeType &&
          bounds == other.bounds &&
          backgroundImage == other.backgroundImage &&
          backgroundCodec == other.backgroundCodec &&
          isAnimated == other.isAnimated &&
          frameCount == other.frameCount &&
          currentFrame == other.currentFrame &&
          isLoading == other.isLoading &&
          hasError == other.hasError &&
          marginX == other.marginX &&
          marginY == other.marginY;

  @override
  int get hashCode =>
      bounds.hashCode ^
      backgroundImage.hashCode ^
      backgroundCodec.hashCode ^
      isAnimated.hashCode ^
      frameCount.hashCode ^
      currentFrame.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      marginX.hashCode ^
      marginY.hashCode;
}

class CanvasBoundsNotifier extends Notifier<CanvasBounds> {
  Timer? _animationTimer;
  int _loadGeneration = 0;

  @override
  CanvasBounds build() {
    ref.onDispose(() {
      _animationTimer?.cancel();
      _animationTimer = null;
    });

    ref.listen(selectedArtifactProvider, (previous, next) {
      final prevCanvas = previous is CanvasArtifact ? previous : null;
      final nextCanvas = next is CanvasArtifact ? next : null;
      if (nextCanvas != prevCanvas) {
        // Only reinitialize bounds if properties that actually affect bounds have changed
        bool needsReinitialize = false;

        if (prevCanvas == null || nextCanvas == null) {
          needsReinitialize = true;
        } else if (prevCanvas.canvasType != nextCanvas.canvasType) {
          needsReinitialize = true;
        } else if (nextCanvas.canvasType == CanvasType.markup &&
            prevCanvas.imageUrl != nextCanvas.imageUrl) {
          needsReinitialize = true;
        }

        if (needsReinitialize) {
          initializeBounds(nextCanvas);
        }
      }
    });

    return const CanvasBounds(
      bounds: CanvasBounds.defaultBounds,
      isLoading: false,
    );
  }

  /// Initialize bounds based on canvas type
  Future<void> initializeBounds(CanvasArtifact? canvas) async {
    if (!ref.mounted) return;

    _loadGeneration++;
    final myGeneration = _loadGeneration;

    if (canvas == null) {
      if (ref.mounted && _loadGeneration == myGeneration) {
        state = const CanvasBounds(
            bounds: CanvasBounds.defaultBounds, isLoading: false);
      }
      return;
    }

    switch (canvas.canvasType) {
      case CanvasType.whiteboard:
      case CanvasType.flow:
        if (ref.mounted && _loadGeneration == myGeneration) {
          state = const CanvasBounds(
              bounds: CanvasBounds.defaultBounds, isLoading: false);
        }
        break;

      case CanvasType.markup:
        if (canvas.imageUrl != null && canvas.imageUrl!.isNotEmpty) {
          // Set loading state before starting async operation
          if (ref.mounted && _loadGeneration == myGeneration) {
            state = const CanvasBounds(
              bounds: CanvasBounds.defaultBounds,
              isLoading: true,
              hasError: false,
              backgroundImage: null,
            );
          }
          await _loadImageAndSetBounds(canvas.imageUrl!, myGeneration);
        } else {
          if (ref.mounted && _loadGeneration == myGeneration) {
            state = const CanvasBounds(
                bounds: CanvasBounds.defaultBounds, isLoading: false);
          }
        }
        break;
    }
  }

  Future<void> _loadImageAndSetBounds(String imageUrl, int generation) async {
    if (!ref.mounted) return;

    try {
      // Stop any existing animation
      _animationTimer?.cancel();
      _animationTimer = null;

      ui.Image? image;
      ui.Codec? codec;
      bool isAnimated = false;
      int frameCount = 1;

      image = await ImageService.getImage(imageUrl);

      if (image != null) {
        // For animated images, we need to get the bytes to create codec
        if (imageUrl.endsWith('.gif')) {
          final bytes = await ImageService.getImageBytes(imageUrl);
          if (bytes != null) {
            codec = await ui.instantiateImageCodec(bytes);
            frameCount = codec.frameCount;
            isAnimated = frameCount > 1;

            if (isAnimated) {
              final ui.FrameInfo frameInfo = await codec.getNextFrame();
              image = frameInfo.image;
            }
          }
        }
      }

      if (image != null) {
        // Calculate dynamic margins for markup canvases to ensure good viewport utilization

        // Calculate independent margins for each dimension
        double marginX = math.max(200.0, (1920.0 - image.width));
        double marginY = math.max(200.0, (1080.0 - image.height));

        // Set bounds to image dimensions with independent dynamic margins
        // IMPORTANT: need to handle margins this way and NOT in InteractiveViewer
        // because InteractiveViewer's margins are NOT usable/clickable
        final imageBounds = Rect.fromLTWH(
          -marginX,
          -marginY,
          image.width.toDouble() + (marginX * 2),
          image.height.toDouble() + (marginY * 2),
        );

        // Set the final state with loaded image
        if (ref.mounted && _loadGeneration == generation) {
          state = CanvasBounds(
            bounds: imageBounds,
            backgroundImage: image,
            backgroundCodec: codec,
            isAnimated: isAnimated,
            frameCount: frameCount,
            currentFrame: 0,
            isLoading: false,
            hasError: false,
            marginX: marginX,
            marginY: marginY,
          );
        }

        // Start animation if it's an animated GIF
        if (ref.mounted &&
            _loadGeneration == generation &&
            isAnimated &&
            codec != null) {
          _startAnimation(codec);
        }
      } else {
        debugPrint('Failed to load image: $imageUrl');
        if (ref.mounted && _loadGeneration == generation) {
          state = const CanvasBounds(
            bounds: CanvasBounds.defaultBounds,
            isLoading: false,
            hasError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading canvas image: $e');
      if (ref.mounted && _loadGeneration == generation) {
        state = const CanvasBounds(
          bounds: CanvasBounds.defaultBounds,
          isLoading: false,
          hasError: true,
        );
      }
    }
  }

  void _startAnimation(ui.Codec codec) async {
    if (!ref.mounted) return;

    int currentFrame = 0;

    void nextFrame() async {
      if (!ref.mounted || state.hasError) return;

      try {
        // Reset codec to start from beginning if we've reached the end
        if (currentFrame >= state.frameCount) {
          currentFrame = 0;
        }

        // Get the next frame
        final frameInfo = await codec.getNextFrame();

        if (ref.mounted && state.isAnimated) {
          state = state.copyWith(
            backgroundImage: frameInfo.image,
            currentFrame: currentFrame,
          );

          currentFrame++;

          // Schedule next frame based on frame duration
          if (ref.mounted) {
            _animationTimer = Timer(frameInfo.duration, nextFrame);
          }
        }
      } catch (e) {
        // Stop animation on error
        _animationTimer?.cancel();
        _animationTimer = null;
      }
    }

    // Start the animation loop
    nextFrame();
  }

  void stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  void resumeAnimation() {
    if (state.isAnimated &&
        state.backgroundCodec != null &&
        _animationTimer == null) {
      _startAnimation(state.backgroundCodec!);
    }
  }

  /// Snap position to grid
  Offset snap(Offset position) => Offset(
      (position.dx / CanvasBounds.gridSpacing).round() *
          CanvasBounds.gridSpacing,
      (position.dy / CanvasBounds.gridSpacing).round() *
          CanvasBounds.gridSpacing);

  /// Clamp position to canvas bounds
  Offset clamp(Offset position) => Offset(
      position.dx.clamp(state.bounds.left, state.bounds.right),
      position.dy.clamp(state.bounds.top, state.bounds.bottom));

  /// Get current bounds
  Rect get bounds => state.bounds;

  /// Get background image if available
  ui.Image? get backgroundImage => state.backgroundImage;
}

final canvasBoundsProvider =
    NotifierProvider.autoDispose<CanvasBoundsNotifier, CanvasBounds>(
  CanvasBoundsNotifier.new,
);
