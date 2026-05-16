import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:onyxia/export.dart';
import 'package:http/http.dart' as http;

class ImageService {
  static const _bucket = 'vault-files';
  static const _maxImageBytes = 10 * 1024 * 1024;
  static const _maxCached = 32;

  static final LinkedHashMap<String, ui.Image> _decodedCache = LinkedHashMap();
  static final Map<String, Future<ui.Image?>> _inflight = {};

  /// Upload [bytes] to Supabase Storage and create an `ArtifactType.image`
  /// row in `artifacts`. Returns the new artifact; caller can read
  /// `.downloadUrl` for the public URL.
  static Future<ImageArtifact> uploadImage(
    Uint8List bytes,
    String fileName, {
    required String vaultId,
  }) async {
    if (bytes.length > _maxImageBytes) {
      throw ArgumentError(
        'Image too large (${bytes.length} bytes, max 10MB)',
      );
    }
    final mime = _mimeFromFileName(fileName);
    final id = const Uuid().v4();
    final storagePath = 'vaults/$vaultId/images/${id}_$fileName';

    await Supabase.instance.client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );

    final artifact = ImageArtifact(
      id: id,
      name: fileName,
      storagePath: storagePath,
      mimeType: mime,
    );
    await ArtifactsRepository(vaultId: vaultId).add([artifact]);
    return artifact;
  }

  /// Fetch + decode an image from [url]. Cached in-memory (LRU, 32 entries).
  /// Returns null if the URL is empty, the HTTP request fails, or decoding
  /// fails — callers (canvas painter, upload service) explicitly handle null.
  static Future<ui.Image?> getImage(String url) async {
    if (url.isEmpty) return null;

    final cached = _decodedCache.remove(url);
    if (cached != null) {
      _decodedCache[url] = cached;
      return cached;
    }
    final pending = _inflight[url];
    if (pending != null) return pending;

    final future = _loadAndDecode(url);
    _inflight[url] = future;
    try {
      final image = await future;
      if (image != null) _put(url, image);
      return image;
    } finally {
      _inflight.remove(url);
    }
  }

  /// Returns the cached image if present; otherwise kicks off an async load
  /// and returns null (caller will see it next frame).
  static ui.Image? getImageSync(String url) {
    if (url.isEmpty) return null;
    final cached = _decodedCache[url];
    if (cached != null) return cached;
    if (!_inflight.containsKey(url)) getImage(url);
    return null;
  }

  static Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(getImage));
  }

  /// Raw bytes (no decode, no cache). Used for animated-GIF frame inspection.
  static Future<Uint8List?> getImageBytes(String url) async {
    if (url.isEmpty) return null;
    final response = await http.get(Uri.parse(url));
    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  // ---------------- private ----------------

  static Future<ui.Image?> _loadAndDecode(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('ImageService: HTTP ${response.statusCode} for $url');
        return null;
      }
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('ImageService: failed to load $url — $e');
      return null;
    }
  }

  static void _put(String url, ui.Image image) {
    _decodedCache[url] = image;
    while (_decodedCache.length > _maxCached) {
      _decodedCache.remove(_decodedCache.keys.first);
    }
  }

  static String _mimeFromFileName(String name) =>
      switch (name.toLowerCase().split('.').last) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/png',
      };
}
