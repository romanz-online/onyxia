import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_service.dart';

/// Custom ImageProvider that uses ImageService.getImage() to handle large images properly
/// with caching, size constraints, and proper error handling
class NarwhalImageProvider extends ImageProvider<NarwhalImageProvider> {
  const NarwhalImageProvider(this.imageUrl, {this.targetSize});

  final String imageUrl;
  final Size? targetSize;

  @override
  Future<NarwhalImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NarwhalImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(NarwhalImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: imageUrl,
    );
  }

  Future<ui.Codec> _loadAsync(NarwhalImageProvider key, ImageDecoderCallback decode) async {
    try {
      final image = await ImageService.getImageAsync(
        key.imageUrl,
        targetSize: key.targetSize,
      );

      if (image != null) {
        // Convert ui.Image to bytes for the decoder
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          return decode(buffer);
        }
      }

      // Fallback: if ImageService fails, throw an error
      throw Exception('Failed to load image: ${key.imageUrl}');
    } catch (e) {
      throw Exception('Error loading image ${key.imageUrl}: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is NarwhalImageProvider
        && other.imageUrl == imageUrl
        && other.targetSize == targetSize;
  }

  @override
  int get hashCode => Object.hash(imageUrl, targetSize);

  @override
  String toString() => 'NarwhalImageProvider("$imageUrl", targetSize: $targetSize)';
}