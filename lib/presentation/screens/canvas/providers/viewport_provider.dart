import 'package:onyxia/export.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'bounds_provider.dart';
import 'objects_provider.dart';

/// Provider for a TransformationController used on the canvas
final canvasViewportProvider = StateNotifierProvider.autoDispose<TransformationNotifier, TransformationController>(
  (ref) {
    return TransformationNotifier(ref);
  },
);

/// A StateNotifier that manages the TransformationController
class TransformationNotifier extends StateNotifier<TransformationController> {
  BuildContext? context;
  final Ref ref;
  bool _disposed = false;

  TransformationNotifier(this.ref) : super(TransformationController());

  double get minScale => 0.01;
  double get maxScale => 10.0;

  @override
  void dispose() {
    _disposed = true;
    context = null;
    super.dispose();
  }

  /// Centers the viewport on the current canvas bounds.
  /// Called directly by the loader service after bounds are guaranteed to be ready.
  void centerViewport(BuildContext ctx) {
    if (_disposed) return;
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
    if (_disposed || context == null) return;
    centerViewport(context!);
  }

  /// Sets a specific transformation matrix
  void setTransformation(Matrix4 matrix) {
    if (_disposed) return;
    state = TransformationController(_clampViewport(matrix));
  }

  Matrix4 _clampViewport(Matrix4 matrix) {
    if (_disposed || context == null) return matrix;

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

    // When zoomed in, we need to allow the canvas to move more to show all content
    // This is the key fix: boundaries need to be adjusted based on zoom level
    double minX, maxX, minY, maxY;

    if (scaledCanvasWidth <= viewportSize.width) {
      // Canvas is smaller than or equal to viewport width
      // Center it horizontally and restrict movement
      final idealOffsetX = (viewportSize.width - scaledCanvasWidth) / 2;
      minX = idealOffsetX;
      maxX = idealOffsetX;
    } else {
      // Canvas is larger than viewport width
      // Allow scrolling to see all content
      minX = viewportSize.width - scaledCanvasWidth;
      maxX = 0.0;
    }

    if (scaledCanvasHeight <= viewportSize.height) {
      // Canvas is smaller than or equal to viewport height
      // Center it vertically and restrict movement
      final idealOffsetY = (viewportSize.height - scaledCanvasHeight) / 2;
      minY = idealOffsetY;
      maxY = idealOffsetY;
    } else {
      // Canvas is larger than viewport height
      // Allow scrolling to see all content
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

    // Adjust delta based on zoom level to maintain consistent sensitivity
    final newDelta = Offset(delta.dx * scale, delta.dy * scale);

    setTransformation(Matrix4.identity()
      ..translateByDouble(translation.x + newDelta.dx, translation.y + newDelta.dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0));
  }

  void updateZoom({required double increment}) {
    if (_disposed || context == null) return;

    // Check if MediaQuery is available before using it
    final mediaQuery = MediaQuery.maybeOf(context!);
    if (mediaQuery == null) return;

    final screenSize = mediaQuery.size;
    final viewportSize = screenSize;

    final currentMatrix = state.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // For all canvas types, apply increment directly
    // Since markup canvases now use 1.0 as base scale, no adjustment needed
    double adjustedIncrement = increment;

    final newScale = (currentScale + adjustedIncrement).clamp(minScale, maxScale);

    if (currentScale == newScale) return; // No change needed

    final currentTranslation = currentMatrix.getTranslation();

    // Calculate viewport center
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    // Calculate the point in content space that's currently at viewport center
    final contentCenterX = (viewportCenter.dx - currentTranslation.x) / currentScale;
    final contentCenterY = (viewportCenter.dy - currentTranslation.y) / currentScale;

    // Calculate new translation to keep the same content point at viewport center
    final newTranslationX = viewportCenter.dx - (contentCenterX * newScale);
    final newTranslationY = viewportCenter.dy - (contentCenterY * newScale);

    setTransformation(Matrix4.identity()
      ..translateByDouble(newTranslationX, newTranslationY, 0.0, 1.0)
      ..scaleByDouble(newScale, newScale, newScale, 1.0));
  }

  String getCurrentZoomAsString() {
    final currentScale = state.value.getMaxScaleOnAxis();
    final currentCanvas = ref.read(currentCanvasProvider);

    if (currentCanvas?.canvasType == CanvasType.markup) {
      // For markup canvases, show percentage relative to natural size (1.0)
      // Since _baseFitScale is now 1.0, this is equivalent to the else branch
      final percentage = (currentScale * 100).round();
      return '$percentage%';
    } else {
      // For other canvases, show percentage relative to 1.0
      return '${(currentScale * 100).round()}%';
    }
  }

  Matrix4 getInverse() => Matrix4.inverted(state.value);

  /// Returns the visible region in canvas object coordinates.
  /// For markup canvases, (0,0) is the image top-left.
  /// For whiteboard canvases, (0,0) is the top-left of the 5000x5000 canvas.
  ///
  /// [ivSize] is the InteractiveViewer's logical size (screen size minus top bar).
  /// Pass this from the minimap's own context to avoid depending on notifier.context,
  /// which may be null before init() is called after navigation.
  Rect getVisibleObjectRect(Size ivSize) {
    final inverseTransform = Matrix4.inverted(state.value);

    // IV corners → content space
    final topLeftContent = _contentPoint(inverseTransform, Offset.zero);
    final bottomRightContent = _contentPoint(inverseTransform, Offset(ivSize.width, ivSize.height));

    // Shift from content space to object space via bounds origin
    final boundsState = ref.read(canvasBoundsProvider);
    final boundsOffset = Offset(boundsState.bounds.left, boundsState.bounds.top);
    return Rect.fromPoints(topLeftContent + boundsOffset, bottomRightContent + boundsOffset);
  }

  Offset _contentPoint(Matrix4 inverseTransform, Offset point) {
    final v64.Vector3 result = inverseTransform.transform3(v64.Vector3(point.dx, point.dy, 0));
    return Offset(result.x, result.y);
  }

  Offset getViewportCenter() {
    if (_disposed || context == null) return Offset.zero;

    // Check if MediaQuery is available before using it
    final mediaQuery = MediaQuery.maybeOf(context!);
    if (mediaQuery == null) return Offset.zero;

    final transform = state.value;

    final screenSize = mediaQuery.size;
    // Calculate the viewport center in canvas coordinates
    final Offset viewportCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );

    // Convert viewport center to canvas coordinates
    // The inverse of the transformation matrix converts from screen to canvas coordinates
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final v64.Vector3 untransformedCenter = inverseTransform.transform3(
      v64.Vector3(viewportCenter.dx, viewportCenter.dy, 0),
    );

    // Create an offset from the untransformed center
    final Offset canvasPosition = Offset(
      untransformedCenter.x,
      untransformedCenter.y,
    );

    // Clamp to canvas bounds
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
