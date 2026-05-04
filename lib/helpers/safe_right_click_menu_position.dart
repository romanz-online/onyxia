import 'package:flutter/material.dart';

class SafeMenuPosition {
  static Offset calculateSafePosition({
    required Offset preferredPosition,
    required Size menuSize,
    required Size screenSize,
    double padding = 8.0,
  }) {
    double safeLeft = preferredPosition.dx;
    double safeTop = preferredPosition.dy;

    // Check right boundary
    if (safeLeft + menuSize.width > screenSize.width - padding) {
      safeLeft = screenSize.width - menuSize.width - padding;
    }

    // Check left boundary
    if (safeLeft < padding) {
      safeLeft = padding;
    }

    // Check bottom boundary
    if (safeTop + menuSize.height > screenSize.height - padding) {
      safeTop = screenSize.height - menuSize.height - padding;
    }

    // Check top boundary
    if (safeTop < padding) {
      safeTop = padding;
    }

    return Offset(safeLeft, safeTop);
  }

  static Offset calculateSubmenuPosition({
    required Offset parentPosition,
    required Size parentSize,
    required Size submenuSize,
    required Size screenSize,
    double padding = 8.0,
  }) {
    // Try to position submenu to the right of parent
    Offset preferredPosition = Offset(
      parentPosition.dx + parentSize.width,
      parentPosition.dy - 54, // Keeping original offset
    );

    // If submenu would go off right edge, position it to the left
    if (preferredPosition.dx + submenuSize.width > screenSize.width - padding) {
      preferredPosition = Offset(
        parentPosition.dx - submenuSize.width,
        preferredPosition.dy,
      );
    }

    return calculateSafePosition(
      preferredPosition: preferredPosition,
      menuSize: submenuSize,
      screenSize: screenSize,
      padding: padding,
    );
  }
}