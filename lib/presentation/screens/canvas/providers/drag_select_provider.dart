import 'package:onyxia/export.dart';
import 'settings.dart';
import 'bounds_provider.dart';
import 'objects_provider.dart';

@immutable
class DragSelectState {
  const DragSelectState({
    this.dragRect,
    this.anchor,
    this.isActive = false,
  });

  final Rect? dragRect;
  final Offset? anchor;
  final bool isActive;

  DragSelectState copyWith({
    Rect? dragRect,
    Offset? anchor,
    bool? isActive,
  }) {
    return DragSelectState(
      dragRect: dragRect ?? this.dragRect,
      anchor: anchor ?? this.anchor,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DragSelectState &&
        other.dragRect == dragRect &&
        other.anchor == anchor &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(dragRect, anchor, isActive);
}

class DragSelectNotifier extends StateNotifier<DragSelectState> {
  DragSelectNotifier(this.ref) : super(const DragSelectState());

  final Ref ref;

  void startDragSelect(Offset position) {
    final anchorPosition = ref.read(canvasSettingsProvider(Setting.snapToGrid))
        ? ref.read(canvasBoundsProvider.notifier).snap(position)
        : position;

    state = DragSelectState(
      anchor: anchorPosition,
      dragRect: Rect.fromPoints(anchorPosition, anchorPosition),
      isActive: true,
    );
  }

  void updateDragSelect(Offset position) {
    if (!state.isActive || state.anchor == null) return;

    final newDragRect = Rect.fromPoints(
      state.anchor!,
      ref.read(canvasSettingsProvider(Setting.snapToGrid))
          ? ref.read(canvasBoundsProvider.notifier).snap(position)
          : position,
    );
    state = state.copyWith(dragRect: newDragRect);

    ref.read(canvasObjectsProvider.notifier).selectObjects(ref
        .read(canvasObjectsProvider)
        .objects
        .where((e) => newDragRect.overlaps(Rect.fromPoints(e.topLeft, e.bottomRight)))
        .toList());
  }

  void endDragSelect() {
    state = const DragSelectState();
  }
}

/// Provider for drag selection functionality
final dragSelectProvider = StateNotifierProvider.autoDispose<DragSelectNotifier, DragSelectState>(
  (ref) => DragSelectNotifier(ref),
);

/// Convenience providers for specific state aspects
final dragSelectRectProvider = Provider.autoDispose<Rect?>((ref) {
  return ref.watch(dragSelectProvider).dragRect;
});
