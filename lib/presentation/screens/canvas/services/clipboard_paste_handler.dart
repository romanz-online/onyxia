// Web implementation for clipboard paste handling
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:onyxia/export.dart';
import '../providers/objects_provider.dart';
import 'image_upload_service.dart';

/// Handles paste events from browser clipboard (web-specific)
void handleJsPasteImpl(web.Event event, WidgetRef ref, BuildContext context) {
  if (!ref.read(canvasConfigProvider).allowPasting) return;

  final clipboardData = (event as web.ClipboardEvent).clipboardData;
  if (clipboardData == null) return;

  // upload images
  final files = clipboardData.files;
  if (files.length > 0) {
    final platformFiles = <PlatformFile>[];

    for (var i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file != null && _isImageFile(file.name)) {
        // Read file bytes
        final reader = web.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) async {
          final bytes = (reader.result as JSArrayBuffer).toDart.asUint8List();
          platformFiles.add(PlatformFile(
            name: file.name,
            size: file.size,
            bytes: bytes,
          ));

          // Process after all files are read
          if (platformFiles.length == files.length) {
            if (context.mounted) {
              CanvasImageUploadService.uploadAndPlaceImages(
                ref: ref,
                context: context,
                files: platformFiles,
              );
            }
          }
        });
      }
    }
    return;
  }
}

bool _isImageFile(String path) {
  final lowerPath = path.toLowerCase();
  final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.webp', '.heic', '.heif', '.ico', '.svg'];
  return imageExtensions.any((ext) => lowerPath.endsWith(ext));
}
