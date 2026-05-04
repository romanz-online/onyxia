import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:onyxia/export.dart';
import 'package:http/http.dart' as http;

/// Global image service for handling image upload, download, and caching
/// Singleton pattern - no WidgetRef required
class ImageService {
  // SINGLETON
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Request throttling
  static const int _maxConcurrentRequests = 2;
  static int _activeRequests = 0;
  static final List<Completer<void>> _requestQueue = [];

  /// Wait for an available request slot
  static Future<void> _waitForRequestSlot() async {
    if (_activeRequests < _maxConcurrentRequests) {
      _activeRequests++;
      return;
    }

    // Queue this request
    final completer = Completer<void>();
    _requestQueue.add(completer);
    await completer.future;
    _activeRequests++;
  }

  /// Release a request slot and process next in queue
  static void _releaseRequestSlot() {
    _activeRequests--;

    if (_requestQueue.isNotEmpty) {
      final next = _requestQueue.removeAt(0);
      next.complete();
    }
  }

  /// Upload an image to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String> uploadImage(
    Uint8List imageData,
    String fileName, {
    String userName = 'Unknown',
    String? projectId,
    String? canvasId,
    String? userId,
    String? folderId,
    String category = 'images',
    Function(double progress)? onProgress,
  }) async {
    // Determine folder structure based on context
    String folder;
    if (userId != null) {
      folder = 'avatars'; // users/{userId}/avatars/
    } else if (canvasId != null) {
      folder = 'images';
    } else if (folderId != null) {
      folder = 'images'; // projects/{projectId}/userExperience/markup/{folderId}/images/
    } else if (category == 'thumbnails') {
      folder = 'thumbnails'; // projects/{projectId}/thumbnails/
    } else if (category == 'file-uploads') {
      folder = 'file-uploads'; // projects/{projectId}/userExperience/markup/file-upload/{fileId}/images/
    } else {
      folder = 'images'; // projects/{projectId}/images/ (fallback)
    }

    final originalFile = await FileStorage().uploadFile(
      fileData: imageData,
      fileName: fileName,
      mimeType: ImageEncodingService.getMimeTypeFromFileName(fileName),
      uploadedBy: userName,
      projectId: projectId,
      canvasId: canvasId,
      userId: userId,
      folderId: folderId,
      folder: folder,
      onProgress: onProgress,
    );

    return originalFile.downloadUrl;
  }

  static Future<ui.Image?> getImageAsync(
    String imageUrl, {
    Size? targetSize,
  }) async {
    if (imageUrl.isEmpty) return null;

    final maxSafeSize = ImageHelper.getMaxSafeSize();
    targetSize ??= maxSafeSize;
    if (targetSize.width > maxSafeSize.width || targetSize.height > maxSafeSize.height) {
      targetSize = maxSafeSize;
    }

    // Check if already decoded in hot cache
    final cachedDecoded = ImageCacheService.getDecodedImage(
      imageUrl,
      targetSize: targetSize,
    );
    if (cachedDecoded != null) return cachedDecoded;

    // if already loading, just wait for loading to finish
    if (ImageCacheService.isImageLoading(imageUrl, targetSize: targetSize)) {
      final loadingFuture = ImageCacheService.getLoadingFuture(
        imageUrl,
        targetSize: targetSize,
      );

      if (loadingFuture != null) return await loadingFuture;
    }

    // if not already loading, start loading
    final loadingFuture = getImage(imageUrl, targetSize: targetSize);
    ImageCacheService.setLoadingFuture(
      imageUrl,
      loadingFuture,
      targetSize: targetSize,
    );

    try {
      return await loadingFuture;
    } catch (e) {
      debugPrint('Error loading image $imageUrl, $targetSize: $e');
      return null;
    } finally {
      ImageCacheService.removeLoadingFuture(imageUrl, targetSize: targetSize);
    }
  }

  static Future<void> preloadImages(
    List<String> imageUrls, {
    Size? targetSize,
  }) async {
    await Future.wait(
      imageUrls.map((url) => getImageAsync(url, targetSize: targetSize)),
    );
  }

  static ui.Image? getImageSync(
    String imageUrl, {
    Size? targetSize,
  }) {
    if (imageUrl.isEmpty) return null;

    final maxSafeSize = ImageHelper.getMaxSafeSize();
    targetSize ??= maxSafeSize;
    if (targetSize.width > maxSafeSize.width || targetSize.height > maxSafeSize.height) {
      targetSize = maxSafeSize;
    }

    // Check hot decoded cache first
    final cachedDecoded = ImageCacheService.getDecodedImage(imageUrl, targetSize: targetSize);
    if (cachedDecoded != null) {
      return cachedDecoded;
    }

    // Check if we have encoded bytes (need to decode asynchronously)
    final encodedBytes = ImageCacheService.getEncodedBytes(imageUrl, targetSize: targetSize);
    if (encodedBytes != null) {
      // Have bytes but not decoded - start async decode
      if (!ImageCacheService.isImageLoading(imageUrl, targetSize: targetSize)) {
        getImageAsync(imageUrl, targetSize: targetSize);
      }
      return null; // Will be available next frame
    }

    // Not cached at all - start loading
    if (!ImageCacheService.isImageLoading(imageUrl, targetSize: targetSize)) {
      getImageAsync(imageUrl, targetSize: targetSize);
    }

    return null;
  }

  static Future<ui.Image?> getImage(
    String imageUrl, {
    Size? targetSize,
  }) async {
    if (imageUrl.isEmpty) return null;

    final maxSafeSize = ImageHelper.getMaxSafeSize();
    targetSize ??= maxSafeSize;
    if (targetSize.width > maxSafeSize.width || targetSize.height > maxSafeSize.height) {
      targetSize = maxSafeSize;
    }

    try {
      // Check decoded hot cache first
      final cachedDecoded = ImageCacheService.getDecodedImage(imageUrl, targetSize: targetSize);
      if (cachedDecoded != null) return cachedDecoded;

      // Check encoded bytes cache
      Uint8List? rawBytes = ImageCacheService.getEncodedBytes(imageUrl, targetSize: targetSize);

      // If not in cache, download
      if (rawBytes == null) {
        if (imageUrl.startsWith('data:image/')) {
          // base-64 image
          rawBytes = ImageEncodingService.decodeBase64Image(imageUrl);
        } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          await _waitForRequestSlot();
          try {
            http.Response? response;
            for (int attempt = 0; attempt < 4; attempt++) {
              response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 10));
              if (response.statusCode != 429) break;
              await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, 2s, 4s, 8s
            }
            if (response!.statusCode == 200) {
              rawBytes = response.bodyBytes;
            } else {
              throw Exception('HTTP ${response.statusCode}: Failed to download image');
            }
          } finally {
            _releaseRequestSlot();
          }
        } else {
          rawBytes = await FileStorage().downloadFile(imageUrl);
        }

        if (rawBytes == null) return null;

        // Cache the encoded bytes
        ImageCacheService.cacheBytes(imageUrl, rawBytes, targetSize: targetSize);
      }

      // Decode the bytes
      final dimensions = ImageHelper.getImageDimensions(rawBytes);
      if (dimensions == null) return null;

      final (originalWidth, originalHeight) = dimensions;

      ui.Image decodedImage;
      if (targetSize.width > originalWidth && targetSize.height > originalHeight) {
        final decoded = await ImageEncodingService.decodeImageFromBytes(rawBytes);
        if (decoded == null) return null;
        decodedImage = decoded;
      } else {
        final scale = math.min(
          targetSize.width / originalWidth,
          targetSize.height / originalHeight,
        );

        // Decode directly to target size
        final codec = await ui.instantiateImageCodec(
          rawBytes,
          targetWidth: (originalWidth * scale).round(),
          targetHeight: (originalHeight * scale).round(),
        );
        final frame = await codec.getNextFrame();
        decodedImage = frame.image;
      }

      // Cache the decoded image in hot cache
      ImageCacheService.cacheDecodedImage(imageUrl, decodedImage, targetSize: targetSize);

      return decodedImage;
    } catch (e) {
      debugPrint('Error in getImage $imageUrl, $targetSize: $e');
      return null;
    }
  }

  static Future<Uint8List?> getImageBytes(
    String imageUrl, {
    Size? targetSize,
  }) async {
    if (imageUrl.isEmpty) return null;

    try {
      final resizedImage = await getImage(imageUrl, targetSize: targetSize);
      if (resizedImage != null) {
        final resizedBytes = await resizedImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        resizedImage.dispose();

        return resizedBytes!.buffer.asUint8List();
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error in getImageBytes $imageUrl, $targetSize: $e');
      return null;
    }
  }
}
