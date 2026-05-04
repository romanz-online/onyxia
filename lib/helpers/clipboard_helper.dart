import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web-specific clipboard helper using native browser Clipboard API
Future<bool> hasFilesInClipboard() async {
  try {
    final clipboardItems = await web.window.navigator.clipboard.read().toDart;

    // Convert JSArray to List
    final itemsList = clipboardItems.toDart;

    for (var i = 0; i < itemsList.length; i++) {
      final typesList = itemsList[i].types.toDart;

      // Check if clipboard contains files
      // Files can be indicated by: 'Files', 'application/x-moz-file', image MIME types, etc.
      for (var j = 0; j < typesList.length; j++) {
        final type = typesList[j].toDart.toLowerCase();
        if (type.contains('file') || type.startsWith('image/')) {
          return true;
        }
      }
    }

    return false;
  } catch (e) {
    // Clipboard access might be denied or unavailable
    return false;
  }
}
