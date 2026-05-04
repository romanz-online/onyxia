import 'package:onyxia/export.dart';

enum Setting {
  showComments,
  showArtifacts,
  snapToGrid,
  showMinimap,
  showToolbar,
  showSearchOverlay,
}

final canvasSettingsProvider = StateProvider.family<bool, Setting>((ref, setting) => switch (setting) {
      // Default values
      Setting.showComments => true,
      Setting.showArtifacts => true,
      Setting.snapToGrid => true,
      Setting.showMinimap => true,
      Setting.showToolbar => true,
      Setting.showSearchOverlay => false,
    });
