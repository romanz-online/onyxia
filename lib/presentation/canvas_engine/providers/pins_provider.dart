import 'package:onyxia/export.dart';
import 'objects_provider.dart';
import 'dart:async';

final pinsProvider =
    StateNotifierProvider.autoDispose<PinsNotifier, Pins>((ref) {
  final canvasId = ref.watch(currentCanvasProvider.select((c) => c?.id ?? ''));
  final projectId = ref.watch(projectsProvider).selectedProject?.id;
  return PinsNotifier(
    Pins.initial(),
    repository: PinsRepository(
      projectId: projectId,
      canvasId: canvasId,
    ),
    canvasId: canvasId,
    projectId: projectId,
  );
});

class PinsNotifier extends StateNotifier<Pins> {
  final PinsRepository repository;
  final String canvasId;
  final String? projectId;
  StreamSubscription? _subscription;

  PinsNotifier(
    super.state, {
    required this.repository,
    required this.canvasId,
    required this.projectId,
  }) {
    _init();
  }

  void _init() {
    if (canvasId.isEmpty || projectId == null) return;

    _subscription = repository.getStream().listen((remotePins) async {
      if (mounted) state = state.copyWith(pins: remotePins);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void updatePinState(Pin pin) {
    final index = state.pins.indexWhere((obj) => obj.id == pin.id);
    if (index == -1) return;

    final updatedPins = List<Pin>.from(state.pins);
    updatedPins[index] = pin;

    state = state.copyWith(pins: updatedPins);
  }

  void updatePin(WidgetRef ref, Pin pin) {
    pipe(ref, () async {
      updatePinState(pin);
      repository.update(pin);
    }).catchError((e, stack) {
      debugPrint('pipe error in updatePin: $e');
    });
  }

  void updatePins(WidgetRef ref, List<Pin> pins) {
    pipe(ref, () async {
      for (final pin in pins) {
        updatePinState(pin);
      }
      repository.updateMultiple(pins);
    }).catchError((e, stack) {
      debugPrint('pipe error in updatePins: $e');
    });
  }

  void addPinState(Pin pin) {
    if (!state.pins.contains(pin)) {
      state = state.copyWith(pins: [...state.pins, pin]);
    }
  }

  void addPin(WidgetRef ref, Pin pin) {
    pipe(ref, () async {
      addPinState(pin);
      repository.add([pin]);
    }).catchError((e, stack) {
      debugPrint('pipe error in addPin: $e');
    });
  }

  void addPins(WidgetRef ref, List<Pin> pins) {
    pipe(ref, () async {
      for (final pin in pins) {
        addPinState(pin);
      }
      repository.add(pins);
    }).catchError((e, stack) {
      debugPrint('pipe error in addPins: $e');
    });
  }

  void deletePin(WidgetRef ref, Pin pin) {
    pipe(ref, () async {
      state = state.copyWith(
        pins: state.pins.where((o) => o.id != pin.id).toList(),
      );
      repository.delete(pin);
    }).catchError((e, stack) {
      debugPrint('pipe error in deletePin: $e');
    });
  }

  void deletePins(WidgetRef ref, List<Pin> pins) {
    if (pins.isEmpty) return;

    pipe(ref, () async {
      state = state.copyWith(
        pins: state.pins.where((o) => !pins.contains(o)).toList(),
      );
      repository.deleteMultiple(pins);
    }).catchError((e, stack) {
      debugPrint('pipe error in deletePins: $e');
    });
  }

  Future<void> pipe(WidgetRef ref, Future<void> Function() operation) async {
    if (HistoryService.pipeActive) {
      await operation.call();
    } else {
      final projectId = ref.read(projectsProvider).selectedProject?.id;
      if (projectId == null) return;

      await HistoryService.pipe(
        ref: ref,
        projectId: projectId,
        operation: operation,
        serializer: CanvasSerializerService(
          canvasId: canvasId,
          projectId: projectId,
          repository: ArtifactsRepository(projectId: projectId),
        ),
      );
    }
  }
}
