import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

class ImageRenderingLimitations {
  final int? maxWidth;
  final int? maxHeight;
  final int? maxPixels;
  final int? maxFileSize;
  final String platform;
  final String? browserName;
  final String? browserVersion;
  final String renderingEngine;

  const ImageRenderingLimitations({
    this.maxWidth,
    this.maxHeight,
    this.maxPixels,
    this.maxFileSize,
    required this.platform,
    this.browserName,
    this.browserVersion,
    required this.renderingEngine,
  });

  @override
  String toString() {
    return 'ImageRenderingLimitations('
        'platform: $platform, '
        'renderingEngine: $renderingEngine, '
        'maxWidth: $maxWidth, '
        'maxHeight: $maxHeight, '
        'maxPixels: $maxPixels, '
        'maxFileSize: $maxFileSize '
        ')';
  }
}

class ImageHelper {
  ImageHelper._();

  static const Map<String, ImageRenderingLimitations> _platformLimitations = {
    'flutter_web_chromium': ImageRenderingLimitations(
      maxWidth: 16384,
      maxHeight: 16384,
      maxPixels: 268435456,
      maxFileSize: null,
      platform: 'Web',
      browserName: 'Chromium',
      renderingEngine: 'WebGL',
    ),
    'flutter_web_firefox': ImageRenderingLimitations(
      maxWidth: 16384,
      maxHeight: 16384,
      maxPixels: 268435456,
      maxFileSize: null,
      platform: 'Web',
      browserName: 'Firefox',
      renderingEngine: 'WebGL',
    ),
    'flutter_web_safari': ImageRenderingLimitations(
      maxWidth: 16384,
      maxHeight: 16384,
      maxPixels: 268435456,
      maxFileSize: null,
      platform: 'Web',
      browserName: 'Safari',
      renderingEngine: 'WebGL',
    ),
    'flutter_web_webgl_low_end': ImageRenderingLimitations(
      maxWidth: 4096,
      maxHeight: 4096,
      maxPixels: 16777216,
      maxFileSize: null,
      platform: 'Web',
      renderingEngine: 'WebGL (Low-end)',
    ),
    'flutter_web_canvas2d': ImageRenderingLimitations(
      maxWidth: 32767,
      maxHeight: 32767,
      maxPixels: null,
      maxFileSize: null,
      platform: 'Web',
      renderingEngine: 'Canvas2D',
    ),
    'flutter_web_html': ImageRenderingLimitations(
      maxWidth: null,
      maxHeight: null,
      maxPixels: null,
      maxFileSize: null,
      platform: 'Web',
      renderingEngine: 'HTML',
    ),
  };

  static ImageRenderingLimitations _getWebPlatformLimitations() {
    final userAgent = web.window.navigator.userAgent.toLowerCase();

    if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
      return _platformLimitations['flutter_web_safari']!;
    } else if (userAgent.contains('firefox')) {
      return _platformLimitations['flutter_web_firefox']!;
    } else {
      // Chrome, Brave, Edge, and other Chromium-based browsers
      return _platformLimitations['flutter_web_chromium']!;
    }
  }

  /// Get the maximum safe size for the current platform
  static Size getMaxSafeSize() {
    final limitations = _getWebPlatformLimitations();

    final maxWidth = limitations.maxWidth ?? 16384;
    final maxHeight = limitations.maxHeight ?? 16384;

    return Size(maxWidth.toDouble(), maxHeight.toDouble());
  }

  /// Get image dimensions from header without full decoding
  static (int width, int height)? getImageDimensions(
    Uint8List imageData,
  ) {
    if (imageData.length < 8) return null;

    // PNG format: 89 50 4E 47 0D 0A 1A 0A
    if (imageData.length >= 24 &&
        imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      final width = (imageData[16] << 24) | (imageData[17] << 16) | (imageData[18] << 8) | imageData[19];
      final height = (imageData[20] << 24) | (imageData[21] << 16) | (imageData[22] << 8) | imageData[23];
      return (width, height);
    }

    // JPEG format: FF D8
    if (imageData[0] == 0xFF && imageData[1] == 0xD8) {
      int offset = 2; // Skip initial FF D8

      while (offset < imageData.length - 1) {
        if (imageData[offset] != 0xFF) break;

        final marker = imageData[offset + 1];
        offset += 2;

        if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
          // SOF markers
          if (offset + 7 >= imageData.length) break;
          final height = (imageData[offset + 3] << 8) | imageData[offset + 4];
          final width = (imageData[offset + 5] << 8) | imageData[offset + 6];
          return (width, height);
        }

        // Skip segment data
        if (offset + 1 >= imageData.length) break;
        final segmentLength = (imageData[offset] << 8) | imageData[offset + 1];
        offset += segmentLength;
      }
    }

    // GIF format: 47 49 46
    if (imageData.length >= 10 && imageData[0] == 0x47 && imageData[1] == 0x49 && imageData[2] == 0x46) {
      final width = imageData[6] | (imageData[7] << 8);
      final height = imageData[8] | (imageData[9] << 8);
      return (width, height);
    }

    // WebP format: 52 49 46 46 ... 57 45 42 50
    if (imageData.length >= 30 &&
        imageData[0] == 0x52 &&
        imageData[1] == 0x49 &&
        imageData[2] == 0x46 &&
        imageData[3] == 0x46 &&
        imageData[8] == 0x57 &&
        imageData[9] == 0x45 &&
        imageData[10] == 0x42 &&
        imageData[11] == 0x50) {
      if (imageData.length < 30) return null;

      // Check VP8 format
      if (imageData[12] == 0x56 && imageData[13] == 0x50 && imageData[14] == 0x38 && imageData[15] == 0x20) {
        if (imageData.length < 30) return null;
        final width = ((imageData[26] | (imageData[27] << 8)) & 0x3FFF) + 1;
        final height = ((imageData[28] | (imageData[29] << 8)) & 0x3FFF) + 1;
        return (width, height);
      }

      // Check VP8L format
      if (imageData[12] == 0x56 && imageData[13] == 0x50 && imageData[14] == 0x38 && imageData[15] == 0x4C) {
        if (imageData.length < 25) return null;
        final bits = (imageData[21]) | (imageData[22] << 8) | (imageData[23] << 16) | (imageData[24] << 24);
        final width = (bits & 0x3FFF) + 1;
        final height = ((bits >> 14) & 0x3FFF) + 1;
        return (width, height);
      }
    }

    return null;
  }
}
