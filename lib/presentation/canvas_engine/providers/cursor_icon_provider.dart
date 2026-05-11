import 'package:onyxia/export.dart';

final canvasMousePressedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final cursorIconOverrideProvider =
    StateNotifierProvider.autoDispose<CursorIconOverrideNotifier, MouseCursor?>(
        (ref) {
  return CursorIconOverrideNotifier();
});

class CursorIconOverrideNotifier extends StateNotifier<MouseCursor?> {
  CursorIconOverrideNotifier() : super(null);

  void setCursor(MouseCursor? cursor) {
    if (cursor != state) {
      state = cursor;
    }
  }
}
