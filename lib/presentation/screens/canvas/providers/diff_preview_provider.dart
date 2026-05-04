import 'package:onyxia/export.dart';

class CanvasDiffPreview {
  final List<CanvasObject> objects;
  final List<Comment> comments;
  final List<Pin> pins;
  final String? imageUrl;
  final bool isRestoring;

  CanvasDiffPreview({
    required this.objects,
    this.comments = const [],
    this.pins = const [],
    this.imageUrl,
    this.isRestoring = false,
  });

  CanvasDiffPreview copyWith({
    List<CanvasObject>? objects,
    List<Comment>? comments,
    List<Pin>? pins,
    String? imageUrl,
    bool? isRestoring,
  }) {
    return CanvasDiffPreview(
      objects: objects ?? this.objects,
      comments: comments ?? this.comments,
      pins: pins ?? this.pins,
      imageUrl: imageUrl ?? this.imageUrl,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class CanvasDiffPreviewNotifier extends StateNotifier<CanvasDiffPreview?> {
  CanvasDiffPreviewNotifier() : super(null);

  void showHistoricalState({
    required List<CanvasObject> objects,
    List<Comment> comments = const [],
    List<Pin> pins = const [],
    String? imageUrl,
  }) {
    state = CanvasDiffPreview(
      objects: objects,
      comments: comments,
      pins: pins,
      imageUrl: imageUrl,
    );
  }

  void clearPreview() {
    state = null;
  }

  void setRestoring(bool isRestoring) {
    if (state != null) {
      state = state!.copyWith(isRestoring: isRestoring);
    }
  }

  bool get isPreviewActive => state != null;
  bool get isRestoring => state?.isRestoring ?? false;

  List<CanvasObject> get previewObjects => state?.objects ?? [];
  List<Comment> get previewComments => state?.comments ?? [];
  List<Pin> get previewPins => state?.pins ?? [];
}

final canvasDiffPreviewProvider = StateNotifierProvider.autoDispose<CanvasDiffPreviewNotifier, CanvasDiffPreview?>(
  (ref) => CanvasDiffPreviewNotifier(),
);
