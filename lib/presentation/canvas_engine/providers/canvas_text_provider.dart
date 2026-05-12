import 'package:onyxia/export.dart';

class CanvasTextState {
  final TextEditingController controller;
  final String editingObjId;
  final FocusNode focusNode;

  CanvasTextState({
    required this.controller,
    this.editingObjId = '',
    required this.focusNode,
  });

  CanvasTextState copyWith({
    TextEditingController? controller,
    String? editingObjId,
    FocusNode? focusNode,
  }) {
    return CanvasTextState(
      controller: controller ?? this.controller,
      editingObjId: editingObjId ?? this.editingObjId,
      focusNode: focusNode ?? this.focusNode,
    );
  }
}

class CanvasTextNotifier extends Notifier<CanvasTextState> {
  @override
  CanvasTextState build() {
    final initialState = CanvasTextState(
      controller: TextEditingController(),
      editingObjId: '',
      focusNode: FocusNode(),
    );

    ref.onDispose(() {
      state.controller.dispose();
      state.focusNode.dispose();
    });

    return initialState;
  }

  void startEditing(String content, String objId) {
    state.controller.text = content;
    state = state.copyWith(editingObjId: objId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.mounted) {
        state.focusNode.requestFocus();
      }
    });
  }

  void stopEditing() {
    if (!isEditing) return;
    state.focusNode.unfocus();
    state = CanvasTextState(
      controller: TextEditingController(),
      editingObjId: '',
      focusNode: state.focusNode,
    );
  }

  bool get isEditing => state.editingObjId.isNotEmpty;
  bool get hasFocus => state.focusNode.hasFocus;
  String get editingObjId => state.editingObjId;
  TextEditingController get controller => state.controller;
  String get text => state.controller.text;
}

final canvasTextProvider =
    NotifierProvider.autoDispose<CanvasTextNotifier, CanvasTextState>(
  CanvasTextNotifier.new,
);
