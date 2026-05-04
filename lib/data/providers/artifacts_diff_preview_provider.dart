import 'package:onyxia/export.dart';

class ArtifactsDiffPreview {
  final Note? note;
  final HistoryDiff? targetDiff;
  final bool isRestoring;

  ArtifactsDiffPreview({
    this.note,
    this.targetDiff,
    this.isRestoring = false,
  });

  ArtifactsDiffPreview copyWith({
    Note? note,
    HistoryDiff? targetDiff,
    bool? isRestoring,
  }) {
    return ArtifactsDiffPreview(
      note: note ?? this.note,
      targetDiff: targetDiff ?? this.targetDiff,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class ArtifactsDiffPreviewNotifier extends StateNotifier<ArtifactsDiffPreview?> {
  ArtifactsDiffPreviewNotifier() : super(null);

  void showHistoricalState({
    required Note note,
    required HistoryDiff targetDiff,
  }) {
    state = ArtifactsDiffPreview(
      note: note,
      targetDiff: targetDiff,
    );
  }

  void clearPreview() {
    state = null;
  }

  void setRestoring(bool isRestoring) {
    if (state == null) {
      state = ArtifactsDiffPreview(isRestoring: isRestoring);
    } else {
      state = state!.copyWith(isRestoring: isRestoring);
    }
  }

  bool get isPreviewActive => state != null;
  bool get isRestoring => state?.isRestoring ?? false;
  Note? get previewNote => state?.note;
}

final artifactsDiffPreviewProvider =
    StateNotifierProvider<ArtifactsDiffPreviewNotifier, ArtifactsDiffPreview?>(
  (ref) => ArtifactsDiffPreviewNotifier(),
);
