import 'package:onyxia/export.dart';
import '../providers/objects_provider.dart';
import '../providers/viewport_provider.dart';

class CanvasImageUploadService {
  static Future<void> uploadAndPlaceImages({
    required WidgetRef ref,
    required BuildContext context,
    required List<PlatformFile> files,
  }) async {
    for (final file in files) {
      try {
        final vaultId = ref.read(selectedVaultProvider)?.id;
        if (vaultId == null) {
          throw StateError('No vault selected for image upload');
        }
        final artifact = await ImageService.uploadImage(
          file.bytes!,
          file.name,
          vaultId: vaultId,
        );
        final imageUrl = artifact.downloadUrl;

        final image = await ImageService.getImage(imageUrl);
        if (image == null) {
          throw Exception('Failed to load uploaded image');
        }

        final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
        final viewportCenter =
            ref.read(canvasViewportProvider.notifier).getViewportCenter();

        if (!context.mounted) return;

        final newObj = CanvasObject(
          id: const Uuid().v4(),
          color: NarwhalColors.neutral900,
          topLeft: viewportCenter,
          bottomRight: Offset(
            viewportCenter.dx + image.width,
            viewportCenter.dy + image.height,
          ),
          type: CanvasObjectType.image,
          imageProperties: ImageProperties(imageUrl: imageUrl),
        );

        final size = newObj.getDimensions();
        newObj.topLeft = Offset(
          viewportCenter.dx - size.width / 2,
          viewportCenter.dy - size.height / 2,
        );
        newObj.bottomRight = Offset(
          viewportCenter.dx + size.width / 2,
          viewportCenter.dy + size.height / 2,
        );

        objectsNotifier.addObject(newObj);
        objectsNotifier.clearSelectedObjects();
        objectsNotifier.selectObject(newObj);

        NarwhalToast.show(
          text: 'Image added to canvas',
          type: ToastType.success,
        );
      } catch (e) {
        debugPrint('Error processing image ${file.name}: $e');
        NarwhalToast.show(
          text: 'Failed to add image: ${file.name} - $e',
          type: ToastType.error,
        );
      }
    }
  }
}
