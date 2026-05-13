import 'package:onyxia/export.dart';
import 'canvas_interaction_context.dart';
import '../providers/providers.dart';
import '../services/services.dart';

/// Represents the current state of canvas gesture interactions
class CanvasGestureState {
  final CanvasObject? activeObject;
  final Offset accumulatedDelta;
  final int? arrowSegmentIndex;
  final ArrowMoveType arrowMoveType;
  final CanvasInteractionContext? interactionContext;

  const CanvasGestureState({
    this.activeObject,
    this.accumulatedDelta = Offset.zero,
    this.arrowSegmentIndex,
    this.arrowMoveType = ArrowMoveType.none,
    this.interactionContext,
  });

  CanvasGestureState copyWith({
    CanvasObject? activeObject,
    Offset? accumulatedDelta,
    int? arrowSegmentIndex,
    ArrowMoveType? arrowMoveType,
    CanvasInteractionContext? interactionContext,
  }) {
    return CanvasGestureState(
      activeObject: activeObject ?? this.activeObject,
      accumulatedDelta: accumulatedDelta ?? this.accumulatedDelta,
      arrowSegmentIndex: arrowSegmentIndex ?? this.arrowSegmentIndex,
      arrowMoveType: arrowMoveType ?? this.arrowMoveType,
      interactionContext: interactionContext ?? this.interactionContext,
    );
  }

  CanvasGestureState resetInteraction() => const CanvasGestureState();
}

/// State notifier for canvas gesture state
class CanvasGestureStateNotifier extends Notifier<CanvasGestureState> {
  @override
  CanvasGestureState build() => const CanvasGestureState();

  void setActiveObject(CanvasObject? object) {
    state = state.copyWith(activeObject: object);
  }

  void setArrowSegmentIndex(int index) {
    state = state.copyWith(arrowSegmentIndex: index);
  }

  void setArrowMoveType(ArrowMoveType moveType) {
    state = state.copyWith(arrowMoveType: moveType);
  }

  void storeContext(CanvasInteractionContext context) {
    state = state.copyWith(interactionContext: context);
  }

  void clearContext() {
    state = state.copyWith(interactionContext: null);
  }

  void updateAccumulatedDelta(Offset delta) {
    state = state.copyWith(accumulatedDelta: state.accumulatedDelta + delta);
  }

  void resetAccumulatedDelta() {
    state = state.copyWith(accumulatedDelta: Offset.zero);
  }

  /// IMPORTANT: for the sake of clarity, future safety, ease of programming, and efficiency,
  /// only call this method once a gesture ENDS (i.e. at the end of onPanEnd)
  /// and not at the start of gesture (i.e. onPanStart)
  void resetInteraction(WidgetRef ref) {
    CanvasInteractionService.closeTextEditor(ref: ref);
    CanvasInteractionService.clearTemporaryComment(ref: ref);
    CanvasInteractionService.closeHeadlessPalette(ref: ref);
    ref.read(arrowPrimedObjectsProvider.notifier).clear();
    state = state.resetInteraction();
  }
}

final canvasGestureStateProvider =
    NotifierProvider.autoDispose<CanvasGestureStateNotifier, CanvasGestureState>(
  CanvasGestureStateNotifier.new,
);
