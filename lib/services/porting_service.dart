import 'dart:async';
import 'dart:js_interop';

import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

/// Folder-based import/export of vault contents. Currently supports importing
/// a user-picked OS folder as a new vault — markdown files become note
/// artifacts and image files are uploaded as image artifacts. Other file
/// types are skipped.
class PortingService {
  static const _markdownExtensions = {'md', 'markdown'};
  static const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'};

  /// Prompts the user to pick a folder via the browser's file dialog.
  /// Returns the list of files inside; empty if the user cancelled.
  static Future<List<web.File>> pickFolder() async {
    final input = web.HTMLInputElement();
    input.type = 'file';
    input.setAttribute('webkitdirectory', '');
    input.setAttribute('directory', '');

    final completer = Completer<List<web.File>>();
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null) {
        completer.complete(const []);
        return;
      }
      final list = <web.File>[];
      for (var i = 0; i < files.length; i++) {
        final f = files.item(i);
        if (f != null) list.add(f);
      }
      completer.complete(list);
    });
    input.click();
    return completer.future;
  }

  /// Top-level folder name extracted from the first file's
  /// `webkitRelativePath` (e.g. "MyVault/notes/foo.md" → "MyVault").
  static String? folderNameFromFiles(List<web.File> files) {
    if (files.isEmpty) return null;
    final relPath = files.first.webkitRelativePath;
    final firstSegment = relPath.split('/').first;
    return firstSegment.isEmpty ? null : firstSegment;
  }

  /// Imports markdown and image files into the vault at [vaultId]. Unsupported
  /// extensions are silently skipped. Walks files in the order given.
  static Future<void> importFiles({
    required List<web.File> files,
    required String vaultId,
    required String userId,
  }) async {
    for (final file in files) {
      final ext = file.name.toLowerCase().split('.').last;
      if (_markdownExtensions.contains(ext)) {
        await _importMarkdown(file: file, vaultId: vaultId, userId: userId);
      } else if (_imageExtensions.contains(ext)) {
        await _importImage(file: file, vaultId: vaultId);
      }
    }
  }

  static Future<void> _importMarkdown({
    required web.File file,
    required String vaultId,
    required String userId,
  }) async {
    final reader = web.FileReader();
    final completer = Completer<String>();
    reader.onLoadEnd.listen(
      (_) => completer.complete((reader.result as JSString).toDart),
    );
    reader.readAsText(file);
    final content = await completer.future;

    // TODO: this is importing file content correctly BUT it's not creating a snapshot or ops for the note artifact, resulting in nothing appearing in the editor

    String strippedFileName = file.name;
    for (final ext in _markdownExtensions) {
      final suffix = '.$ext';
      if (strippedFileName.toLowerCase().endsWith(suffix)) {
        strippedFileName = strippedFileName.substring(
          0,
          strippedFileName.length - suffix.length,
        );
        break;
      }
    }

    await ArtifactsRepository(vaultId: vaultId).add([
      NoteArtifact(
        name: strippedFileName,
        content: content,
        createdBy: userId,
        updatedBy: userId,
      ),
    ]);
  }

  static Future<void> _importImage({
    required web.File file,
    required String vaultId,
  }) async {
    final reader = web.FileReader();
    final completer = Completer<Uint8List>();
    reader.onLoadEnd.listen((_) {
      completer.complete((reader.result as JSArrayBuffer).toDart.asUint8List());
    });
    reader.readAsArrayBuffer(file);
    final bytes = await completer.future;

    await ImageService.uploadImage(bytes, file.name, vaultId: vaultId);
  }
}
