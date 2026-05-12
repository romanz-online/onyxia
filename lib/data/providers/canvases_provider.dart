import 'package:onyxia/export.dart';

final canvasByIdProvider =
    Provider.family<CanvasArtifact?, String>((ref, canvasId) {
  return (ref.watch(artifactsProvider).value ?? const <Artifact>[])
      .whereType<CanvasArtifact>()
      .firstWhereOrNull((canvas) => canvas.name == canvasId);
});
