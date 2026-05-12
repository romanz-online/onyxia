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

class ToolbarStateNotifier extends Notifier<ToolbarState> {
  @override
  ToolbarState build() => const ToolbarState();

  void hideSubmenu() {
    state = state.copyWith(showShapesSubmenu: false);
  }

  void toggleShapesSubmenu() {
    state = state.copyWith(showShapesSubmenu: !state.showShapesSubmenu);
  }
}

final toolbarStateProvider =
    NotifierProvider.autoDispose<ToolbarStateNotifier, ToolbarState>(
  ToolbarStateNotifier.new,
);
