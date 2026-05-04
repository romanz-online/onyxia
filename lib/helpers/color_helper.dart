import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

/// Handy extension method to create random colors
extension RandomColor on Color {
  static Color getRandom() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 1.0);
  }

  /// Quick and dirty method to create a random color from the userID
  static Color getRandomFromId(String id) {
    if (id.isEmpty) return Colors.grey; // or default color
    final seed = utf8.encode(id).reduce((value, element) => value + element);
    return Color((Random(seed).nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 1.0);
  }
}

/// Helper class for color conversion between Color and String
class ColorHelper {
  /// Convert a Color to a hex string representation
  static String colorToString(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Convert a hex string back to a Color object
  static Color stringToColor(String colorString) {
    if (colorString.isEmpty) return Colors.transparent;

    // Remove the '#' if present
    String hexString = colorString.replaceFirst('#', '');

    // Parse the hex string to an integer
    try {
      return Color(int.parse(hexString, radix: 16) | 0xFF000000); // Ensure alpha is set to 255
    } catch (e) {
      return Colors.transparent; // Return transparent if parsing fails
    }
  }
}
