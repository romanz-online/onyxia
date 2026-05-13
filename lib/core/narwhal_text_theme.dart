import 'package:flutter/material.dart';

/// Narwhal typography theme following Segoe UI specification
/// 
/// Usage examples:
/// 
/// **Through Theme.of(context):**
/// ```dart
/// Text('Hello', style: Theme.of(context).textTheme.bodyMedium) // 12px Regular
/// Text('Title', style: Theme.of(context).textTheme.titleSmall) // 10px Bold
/// ```
/// 
/// **Direct access:**
/// ```dart
/// Text('Label', style: NarwhalTextTheme.textTheme.labelSmall) // 10px Regular
/// Text('Eyebrow', style: NarwhalTextTheme.smallEyebrow) // 10px Eyebrow
/// ```
/// 
/// **Typography mapping:**
/// - Small Regular (10px) → labelSmall
/// - Small Semi Bold (10px) → bodySmall  
/// - Small Bold (10px) → titleSmall
/// - Small Eyebrow (10px) → smallEyebrow (custom)
/// - Medium Semi-light (12px) → labelMedium
/// - Medium Regular (12px) → bodyMedium
/// - Medium Semi-bold (12px) → titleMedium
/// - Medium Bold (12px) → headlineSmall
/// - Medium Italics (12px) → displaySmall
/// - Large Semi-light (16px) → labelLarge
/// - Large Italics (16px) → bodyLarge
class NarwhalTextTheme {
  // Primary typeface
  static const String primaryFontFamily = 'Segoe UI';
  
  static TextTheme textTheme = TextTheme(
    // Small scale (10px)
    labelSmall: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400, // Regular
      fontFamily: primaryFontFamily,
    ),
    bodySmall: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600, // Semi Bold
      fontFamily: primaryFontFamily,
    ),
    titleSmall: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700, // Bold
      fontFamily: primaryFontFamily,
    ),
    
    // Medium scale (12px)
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w300, // Semi-light
      fontFamily: primaryFontFamily,
    ),
    bodyMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400, // Regular
      fontFamily: primaryFontFamily,
    ),
    titleMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600, // Semi-bold
      fontFamily: primaryFontFamily,
    ),
    headlineSmall: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700, // Bold
      fontFamily: primaryFontFamily,
    ),
    displaySmall: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400, // Regular
      fontStyle: FontStyle.italic, // Italics
      fontFamily: primaryFontFamily,
    ),
    
    // Large scale (16px)
    labelLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w300, // Semi-light
      fontFamily: primaryFontFamily,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400, // Regular
      fontStyle: FontStyle.italic, // Italics
      fontFamily: primaryFontFamily,
    ),
  );
  
  // Custom text styles for specific typography variants
  static const TextStyle smallEyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400, // Eyebrow weight
    fontFamily: primaryFontFamily,
    letterSpacing: 1.2,
  );
}