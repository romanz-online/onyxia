import 'package:onyxia/export.dart';
import 'dart:ui' as ui;

class CachedImageBytes {
  final Uint8List bytes;
  final DateTime cachedAt;
  final int sizeInBytes;
  final String url;

  const CachedImageBytes({
    required this.bytes,
    required this.cachedAt,
    required this.sizeInBytes,
    required this.url,
  });
}

/// Service dedicated to handling image caching functionality
/// Two-tier cache: encoded bytes (100MB) + hot decoded images (10 images LRU)
/// Singleton pattern - provides centralized image cache management
class ImageCacheService {
  // SINGLETON
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache configuration
  static const int _maxBytesCacheSizeBytes = 100 * 1024 * 1024; // 100MB for encoded bytes
  static const int _maxDecodedCacheCount = 10; // Keep 10 decoded images in hot cache
  static const Duration _cacheExpiration = Duration(hours: 1); // Cache expiration time

  // Two-tier cache storage
  final Map<String, CachedImageBytes> _bytesCache = {}; // Encoded image bytes
  final Map<String, ui.Image> _decodedCache = {}; // Hot cache of decoded images
  final Map<String, DateTime> _decodedCacheAge = {}; // Track LRU for decoded cache
  final Map<String, Future<ui.Image?>> _loadingImageBytes = {};
  int _currentCacheSizeBytes = 0;

  /// Get encoded image bytes from cache
  static Uint8List? getEncodedBytes(String imageUrl, {Size? targetSize}) {
    if (imageUrl.isEmpty) return null;

    imageUrl = _constructImageUrl(imageUrl, targetSize);

    final cached = _instance._bytesCache[imageUrl];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.cachedAt) > _cacheExpiration) {
      _instance._removeCachedBytes(imageUrl);
      return null;
    }

    return cached.bytes;
  }

  /// Get decoded image from hot cache
  static ui.Image? getDecodedImage(String imageUrl, {Size? targetSize}) {
    if (imageUrl.isEmpty) return null;

    imageUrl = _constructImageUrl(imageUrl, targetSize);

    final decoded = _instance._decodedCache[imageUrl];
    if (decoded != null) {
      // Update access time for LRU
      _instance._decodedCacheAge[imageUrl] = DateTime.now();
    }

    return decoded;
  }

  /// Get any cached decoded image for this URL, regardless of size
  /// Returns the largest cached version for better quality when stretched
  /// Used as fallback during resize operations
  static ui.Image? getFallbackImage(String imageUrl) {
    if (imageUrl.isEmpty) return null;

    ui.Image? bestMatch;
    int bestPixels = 0;

    // Search through decoded cache for any matching URL
    for (final entry in _instance._decodedCache.entries) {
      if (entry.key.startsWith('${imageUrl}_')) {
        final image = entry.value;
        final pixels = image.width * image.height;

        // Pick largest version for better quality
        if (pixels > bestPixels) {
          bestMatch = image;
          bestPixels = pixels;

          // Update LRU access time
          _instance._decodedCacheAge[entry.key] = DateTime.now();
        }
      }
    }

    return bestMatch;
  }

  /// Remove specific image from cache (both encoded and decoded)
  static void remove(String imageUrl, {Size? targetSize}) {
    final url = _constructImageUrl(imageUrl, targetSize);
    _instance._removeCachedBytes(url);
    // _instance._decodedCache[url]?.dispose();
    _instance._decodedCache.remove(url);
    _instance._decodedCacheAge.remove(url);
  }

  /// Cache encoded image bytes
  static void cacheBytes(
    String imageUrl,
    Uint8List bytes, {
    Size? targetSize,
  }) {
    imageUrl = _constructImageUrl(imageUrl, targetSize);

    final cached = CachedImageBytes(
      bytes: bytes,
      cachedAt: DateTime.now(),
      sizeInBytes: bytes.length, // Actual compressed size
      url: imageUrl,
    );

    _instance._removeCachedBytes(imageUrl);

    _instance._bytesCache[imageUrl] = cached;
    _instance._currentCacheSizeBytes += cached.sizeInBytes;

    _instance._evictOldBytes();
  }

  /// Cache decoded image in hot cache with LRU eviction
  static void cacheDecodedImage(
    String imageUrl,
    ui.Image image, {
    Size? targetSize,
  }) {
    imageUrl = _constructImageUrl(imageUrl, targetSize);

    // Remove old if exists
    // _instance._decodedCache[imageUrl]?.dispose();
    _instance._decodedCache.remove(imageUrl);

    // Add to hot cache
    _instance._decodedCache[imageUrl] = image;
    _instance._decodedCacheAge[imageUrl] = DateTime.now();

    // Evict oldest if over limit
    while (_instance._decodedCache.length > _maxDecodedCacheCount) {
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _instance._decodedCacheAge.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        // _instance._decodedCache[oldestKey]?.dispose();
        _instance._decodedCache.remove(oldestKey);
        _instance._decodedCacheAge.remove(oldestKey);
      }
    }
  }

  /// Check if image bytes are currently being loaded
  static bool isImageLoading(String imageUrl, {Size? targetSize}) {
    return _instance._loadingImageBytes.containsKey(_constructImageUrl(
      imageUrl,
      targetSize,
    ));
  }

  /// Get the loading future for image bytes that are currently being loaded
  static Future<ui.Image?>? getLoadingFuture(
    String imageUrl, {
    Size? targetSize,
  }) {
    return _instance._loadingImageBytes[_constructImageUrl(imageUrl, targetSize)];
  }

  /// Set a loading future for image bytes
  static void setLoadingFuture(
    String imageUrl,
    Future<ui.Image?> future, {
    Size? targetSize,
  }) {
    _instance._loadingImageBytes[_constructImageUrl(
      imageUrl,
      targetSize,
    )] = future;
  }

  /// Remove a loading future for image bytes
  static void removeLoadingFuture(
    String imageUrl, {
    Size? targetSize,
  }) {
    _instance._loadingImageBytes.remove(_constructImageUrl(
      imageUrl,
      targetSize,
    ));
  }

  /// Remove cached encoded bytes
  void _removeCachedBytes(String imageUrl) {
    final cached = _bytesCache.remove(imageUrl);
    if (cached != null) {
      _currentCacheSizeBytes -= cached.sizeInBytes;
    }
  }

  /// Evict old bytes from cache when over limit
  void _evictOldBytes() {
    // Remove expired images first
    final expiredUrls = _bytesCache.entries
        .where((entry) => DateTime.now().difference(entry.value.cachedAt) > _cacheExpiration)
        .map((entry) => entry.key)
        .toList();

    for (final url in expiredUrls) {
      _removeCachedBytes(url);
    }

    // Remove oldest images if still over limits
    while (_currentCacheSizeBytes > _maxBytesCacheSizeBytes) {
      if (_bytesCache.isEmpty) break;

      // Find oldest cached bytes
      String? oldestUrl;
      DateTime? oldestTime;

      for (final entry in _bytesCache.entries) {
        if (oldestTime == null || entry.value.cachedAt.isBefore(oldestTime)) {
          oldestTime = entry.value.cachedAt;
          oldestUrl = entry.key;
        }
      }

      if (oldestUrl != null) {
        _removeCachedBytes(oldestUrl);
      }
    }
  }

  static String _constructImageUrl(String imageUrl, Size? targetSize) {
    if (targetSize == null) {
      return '${imageUrl}_original';
    } else {
      // Round to integers to avoid floating-point precision issues during object movement
      final width = targetSize.width.round();
      final height = targetSize.height.round();
      return '${imageUrl}_${width}x$height';
    }
  }
}
