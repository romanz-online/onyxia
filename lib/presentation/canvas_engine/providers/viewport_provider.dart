import 'package:onyxia/export.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'bounds_provider.dart';

/// Provider for a TransformationController used on the canvas
final canvasViewportProvider = NotifierProvider.autoDispose<
    TransformationNotifier, TransformationController>(
  TransformationNotifier.new,
);

/// A Notifier that manages the TransformationController
class TransformationNotifier extends Notifier<TransformationController> {
  BuildContext? context;

  @override
  TransformationController build() {
    final controller = TransformationController();
    ref.onDispose(() {
      context = null;
      controller.dispose();
    });
    return controller;
  }

  double get minScale => 0.01;
  double get maxScale => 10.0;

  /// Centers the viewport on the current canvas bounds.
  /// Called directly by the loader service after bounds are guaranteed to be ready.
  void centerViewport(BuildContext ctx) {
    if (!ref.mounted) return;
    context = ctx;
    final mediaQuery = MediaQuery.maybeOf(ctx);
    if (mediaQuery == null) return;
    final canvasBoundsState = ref.read(canvasBoundsProvider);
    final screenSize = mediaQuery.size;
    final canvasSize = canvasBoundsState.bounds.size;
    double centerX = (screenSize.width - canvasSize.width) / 2;
    double centerY = (screenSize.height - canvasSize.height) / 2;
    setTransformation(Matrix4.identity()
      ..translateByDouble(centerX, centerY, 0.0, 1.0)
      ..scaleByDouble(1.0, 1.0, 1.0, 1.0));
  }

  void reset() {
    if (!ref.mounted || context == null) return;
    centerViewport(context!);
  }

  /// Sets a specific transformation matrix
  void setTransformation(Matrix4 matrix) {
    if (!ref.mounted) return;
    state = TransformationController(_clampViewport(matrix));
  }

  Matrix4 _clampViewport(Matrix4 matrix) {
    if (!ref.mounted || context == null) return matrix;

    // Check if MediaQuery is available before using it
    final mediaQuery = MediaQuery.maybeOf(context!);
    if (mediaQuery == null) return matrix;

    final screenSize = mediaQuery.size;
    final viewportSize = Size(screenSize.width, screenSize.height);

    final scale = matrix.getMaxScaleOnAxis();
    final canvasBounds = ref.read(canvasBoundsProvider);
    final Size canvasSize = canvasBounds.bounds.size;
    final double scaledCanvasWidth = canvasSize.width * scale;
    final double scaledCanvasHeight = canvasSize.height * scale;

    double minX, maxX, minY, maxY;

    if (scaledCanvasWidth <= viewportSize.width) {
      final idealOffsetX = (viewportSize.width - scaledCanvasWidth) / 2;
      minX = idealOffsetX;
      maxX = idealOffsetX;
    } else {
      minX = viewportSize.width - scaledCanvasWidth;
      maxX = 0.0;
    }

    if (scaledCanvasHeight <= viewportSize.height) {
      final idealOffsetY = (viewportSize.height - scaledCanvasHeight) / 2;
      minY = idealOffsetY;
      maxY = idealOffsetY;
    } else {
      minY = viewportSize.height - scaledCanvasHeight;
      maxY = 0.0;
    }

    final translation = matrix.getTranslation();
    final double clampedX = translation.x.clamp(minX, maxX);
    final double clampedY = translation.y.clamp(minY, maxY);

    if (clampedX != translation.x || clampedY != translation.y) {
      return Matrix4.identity()
        ..translateByDouble(clampedX, clampedY, 0.0, 1.0)
        ..scaleByDouble(scale, scale, scale, 1.0);
    } else {
      return matrix;
    }
  }

  void panCanvas(Offset delta) {
    final translation = state.value.getTranslation();
    final scale = state.value.getMaxScaleOnAxis();

    final newDelta = Offset(delta.dx * scale, delta.dy * scale);

    setTransformation(Matrix4.identity()
      ..translateByDouble(
          translation.x + newDelta.dx, translation.y + newDelta.dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0));
  }

  void updateZoom({required double increment}) {
    if (!ref.mounted || context == null) return;

    final mediaQuery = MediaQuery.maybeOf(context!);
    if (mediaQuery == null) return;

    final screenSize = mediaQuery.size;
    final viewportSize = screenSize;

    final currentMatrix = state.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    double adjustedIncrement = increment;

    final newScale =
        (currentScale + adjustedIncrement).clamp(minScale, maxScale);

    if (currentScale == newScale) return;

    final currentTranslation = currentMatrix.getTranslation();

    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    final contentCenterX =
        (viewportCenter.dx - currentTranslation.x) / currentScale;
    final contentCenterY =
        (viewportCenter.dy - currentTranslation.y) / currentScale;

    final newTranslationX = viewportCenter.dx - (contentCenterX * newScale);
    final newTranslationY = viewportCenter.dy - (contentCenterY * newScale);

    setTransformation(Matrix4.identity()
      ..translateByDouble(newTranslationX, newTranslationY, 0.0, 1.0)
      ..scaleByDouble(newScale, newScale, newScale, 1.0));
  }

  String getCurrentZoomAsString() {
    final currentScale = state.value.getMaxScaleOnAxis();
    final selected = ref.read(selectedArtifactProvider);
    final currentCanvas = selected is CanvasArtifact ? selected : null;

    if (currentCanvas?.canvasType == CanvasType.markup) {
      final percentage = (currentScale * 100).round();
      return '$percentage%';
    } else {
      return '${(currentScale * 100).round()}%';
    }
  }

  Matrix4 getInverse() => Matrix4.inverted(state.value);

  /// Returns the visible region in canvas object coordinates.
  Rect getVisibleObjectRect(Size ivSize) {
    final inverseTransform = Matrix4.inverted(state.value);

    final topLeftContent = _contentPoint(inverseTransform, Offset.zero);
    final bottomRightContent =
        _contentPoint(inverseTransform, Offset(ivSize.width, ivSize.height));

    final boundsState = ref.read(canvasBoundsProvider);
    final boundsOffset =
        Offset(boundsState.bounds.left, boundsState.bounds.top);
    return Rect.fromPoints(
        topLeftContent + boundsOffset, bottomRightContent + boundsOffset);
  }

  Offset _contentPoint(Matrix4 inverseTransform, Offset point) {
    final v64.Vector3 result =
        inverseTransform.transform3(v64.Vector3(point.dx, point.dy, 0));
    return Offset(result.x, result.y);
  }

  Offset getViewportCenter() {
    if (!ref.mounted || context == null) return Offset.zero;

    final mediaQuery = MediaQuery.maybeOf(context!);
    if (mediaQuery == null) return Offset.zero;

    final transform = state.value;

    final screenSize = mediaQuery.size;
    final Offset viewportCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );

    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final v64.Vector3 untransformedCenter = inverseTransform.transform3(
      v64.Vector3(viewportCenter.dx, viewportCenter.dy, 0),
    );

    final Offset canvasPosition = Offset(
      untransformedCenter.x,
      untransformedCenter.y,
    );

    return ref.read(canvasBoundsProvider.notifier).clamp(canvasPosition);
  }

  Offset convertToCanvasCoords(Offset offset) {
    final v64.Vector3 untransformedPosition = getInverse().transform3(
      v64.Vector3(offset.dx, offset.dy, 0),
    );
    return Offset(untransformedPosition.x, untransformedPosition.y);
  }

  Offset convertToScreenCoords(Offset canvasOffset) {
    final adjustedOffset = Offset(canvasOffset.dx, canvasOffset.dy);
    final v64.Vector3 transformedPosition = state.value.transform3(
      v64.Vector3(adjustedOffset.dx, adjustedOffset.dy, 0),
    );
    return Offset(transformedPosition.x, transformedPosition.y);
  }
}
