import 'package:onyxia/export.dart';

// Provider to get a stream of canvases
final canvasesProvider = StreamProvider.family((ref, String projectId) {
  return ArtifactsRepository(projectId: projectId).getCanvasesStream();
});

// Provider to get a specific canvas by ID
final canvasByIdProvider =
    Provider.family<CanvasArtifact?, ({String projectId, String canvasId})>(
        (ref, params) {
  final canvasesAsync = ref.watch(canvasesProvider(params.projectId));

  return canvasesAsync.when(
    data: (canvases) => canvases
        .cast<CanvasArtifact?>()
        .firstWhereOrNull((canvas) => canvas?.name == params.canvasId),
    loading: () => null,
    error: (err, stack) => null,
  );
});
