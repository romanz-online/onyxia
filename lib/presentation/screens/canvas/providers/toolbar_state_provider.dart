import 'package:onyxia/export.dart';

class ToolbarState {
  final bool showShapesSubmenu;

  const ToolbarState({
    this.showShapesSubmenu = false,
  });

  ToolbarState copyWith({bool? showShapesSubmenu}) {
    return ToolbarState(
      showShapesSubmenu: showShapesSubmenu ?? this.showShapesSubmenu,
    );
  }
}

class ToolbarStateNotifier extends StateNotifier<ToolbarState> {
  ToolbarStateNotifier() : super(const ToolbarState());

  void hideSubmenu() {
    state = state.copyWith(showShapesSubmenu: false);
  }

  void toggleShapesSubmenu() {
    state = state.copyWith(showShapesSubmenu: !state.showShapesSubmenu);
  }
}

final toolbarStateProvider =
    StateNotifierProvider.autoDispose<ToolbarStateNotifier, ToolbarState>((ref) => ToolbarStateNotifier());
