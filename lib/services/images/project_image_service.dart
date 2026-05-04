import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

/// Service for generating project image colors based on project titles
class ProjectImageService {
  /// Gets a consistent list of bytes derived from the project name for color generation
  static List<int> getProjectColorBytes(String projectTitle) {
    final title = projectTitle.isEmpty ? 'Untitled Project' : projectTitle;
    final bytes = utf8.encode(title);
    final digest = md5.convert(bytes).bytes;

    // Ensure we have at least 6 bytes for the colors (with some minimum values to avoid too dark colors)
    return [
      (digest[0] % 156) + 100, // red (100-255)
      (digest[1] % 156) + 100, // green (100-255)
      (digest[2] % 156) + 100, // blue (100-255)
      (digest[3] % 156) + 100, // red (100-255)
      (digest[4] % 156) + 100, // green (100-255)
      (digest[5] % 156) + 100, // blue (100-255)
    ];
  }

  /// Returns gradient colors based on the project title
  static List<Color> getProjectGradientColors(String projectTitle) {
    final bytes = getProjectColorBytes(projectTitle);

    return [
      Color.fromARGB(255, bytes[0], bytes[1], bytes[2]),
      Color.fromARGB(255, bytes[3], bytes[4], bytes[5]),
    ];
  }

  /// Extracts initials from a project title
  static String getProjectInitials(String projectTitle) {
    if (projectTitle.isEmpty) return 'P';

    final words = projectTitle.split(' ');
    String initials = '';

    if (words.isNotEmpty) {
      // Get first letter of first word
      if (words[0].isNotEmpty) {
        initials += words[0][0].toUpperCase();
      }

      // Get first letter of second word if it exists
      if (words.length > 1 && words[1].isNotEmpty) {
        initials += words[1][0].toUpperCase();
      }
    }

    // If we couldn't get initials, use the first letter of the title
    if (initials.isEmpty && projectTitle.isNotEmpty) {
      initials = projectTitle[0].toUpperCase();
    }

    // If still empty, use "P" for Project
    if (initials.isEmpty) {
      initials = 'P';
    }

    // Limit to 2 characters
    if (initials.length > 2) {
      initials = initials.substring(0, 2);
    }

    return initials;
  }
}
