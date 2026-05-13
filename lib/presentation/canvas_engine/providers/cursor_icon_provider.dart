import 'package:onyxia/export.dart';

final canvasMousePressedProvider =
    NotifierProvider.autoDispose<CanvasMousePressedNotifier, bool>(
  CanvasMousePressedNotifier.new,
);

class CanvasMousePressedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final cursorIconOverrideProvider =
    NotifierProvider.autoDispose<CursorIconOverrideNotifier, MouseCursor?>(
  CursorIconOverrideNotifier.new,
);

class CursorIconOverrideNotifier extends Notifier<MouseCursor?> {
  @override
  MouseCursor? build() => null;

  void set(MouseCursor? cursor) {
    if (cursor != state) {
      state = cursor;
    }
  }
}
