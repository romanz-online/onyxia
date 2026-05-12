import 'package:onyxia/export.dart';

enum Setting {
  showComments,
  showArtifacts,
  snapToGrid,
  showMinimap,
  showToolbar,
  showSearchOverlay,
}

final canvasSettingsProvider =
    NotifierProvider.family<CanvasSettingNotifier, bool, Setting>(
  CanvasSettingNotifier.new,
);

class CanvasSettingNotifier extends Notifier<bool> {
  CanvasSettingNotifier(this.setting);
  final Setting setting;

  @override
  bool build() => switch (setting) {
        // Default values
        Setting.showComments => true,
        Setting.showArtifacts => true,
        Setting.snapToGrid => true,
        Setting.showMinimap => true,
        Setting.showToolbar => true,
        Setting.showSearchOverlay => false,
      };

  void set(bool value) => state = value;

  void toggle() => state = !state;

  void update(bool Function(bool) updater) => state = updater(state);
}
