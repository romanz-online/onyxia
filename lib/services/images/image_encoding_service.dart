import 'dart:ui' as ui;
import 'package:onyxia/export.dart';

/// Service dedicated to handling image encoding and decoding functionality
class ImageEncodingService {
  /// Decode base64 image data
  static Uint8List decodeBase64Image(String dataUri) {
    final RegExp base64Pattern = RegExp(r'data:image/[^;]+;base64,(.+)');
    final match = base64Pattern.firstMatch(dataUri);

    if (match == null) {
      throw FormatException('Invalid base64 data URI format');
    }

    final base64String = match.group(1)!;
    return base64Decode(base64String);
  }

  /// Decode bytes to ui.Image
  static Future<ui.Image?> decodeImageFromBytes(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        throw FormatException('Image bytes are empty');
      }

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error decoding image from bytes: $e');
      return null;
    }
  }

  /// Get MIME type from file name
  static String getMimeTypeFromFileName(String fileName) => switch (fileName.toLowerCase().split('.').last) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'bmp' => 'image/bmp',
        _ => 'image/png',
      };

  /// Validate if a string is a valid base64 image data URI
  static bool isValidBase64DataUri(String dataUri) =>
      RegExp(r'^data:image/[^;]+;base64,[A-Za-z0-9+/]+={0,2}$').hasMatch(dataUri);

  /// Validate if a string is a valid image URL
  static bool isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
