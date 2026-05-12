import 'package:onyxia/export.dart';
import 'objects_provider.dart';
import 'dart:async';

final pinsProvider = NotifierProvider.autoDispose<PinsNotifier, Pins>(
  PinsNotifier.new,
);

class PinsNotifier extends Notifier<Pins> {
  late PinsRepository repository;
  late String canvasId;
  String? projectId;
  StreamSubscription? _subscription;

  @override
  Pins build() {
    canvasId = ref.watch(currentCanvasProvider.select((c) => c?.id ?? ''));
    projectId = ref.watch(selectedProjectProvider)?.id;
    repository = PinsRepository(
      projectId: projectId,
      canvasId: canvasId,
    );

    if (canvasId.isNotEmpty && projectId != null) {
      _subscription = repository.getStream().listen((remotePins) async {
        if (ref.mounted) state = state.copyWith(pins: remotePins);
      });
      ref.onDispose(() => _subscription?.cancel());
    }

    return Pins.initial();
  }

  void updatePinState(Pin pin) {
    final index = state.pins.indexWhere((obj) => obj.id == pin.id);
    if (index == -1) return;

    final updatedPins = List<Pin>.from(state.pins);
    updatedPins[index] = pin;

    state = state.copyWith(pins: updatedPins);
  }

  void updatePin(WidgetRef ref, Pin pin) {
    updatePinState(pin);
    repository.update(pin);
  }

  void updatePins(WidgetRef ref, List<Pin> pins) {
    for (final pin in pins) {
      updatePinState(pin);
    }
    repository.updateMultiple(pins);
  }

  void addPinState(Pin pin) {
    if (!state.pins.contains(pin)) {
      state = state.copyWith(pins: [...state.pins, pin]);
    }
  }

  void addPin(WidgetRef ref, Pin pin) {
    addPinState(pin);
    repository.add([pin]);
  }

  void addPins(WidgetRef ref, List<Pin> pins) {
    for (final pin in pins) {
      addPinState(pin);
    }
    repository.add(pins);
  }

  void deletePin(WidgetRef ref, Pin pin) {
    state = state.copyWith(
      pins: state.pins.where((o) => o.id != pin.id).toList(),
    );
    repository.delete(pin);
  }

  void deletePins(WidgetRef ref, List<Pin> pins) {
    if (pins.isEmpty) return;

    state = state.copyWith(
      pins: state.pins.where((o) => !pins.contains(o)).toList(),
    );
    repository.deleteMultiple(pins);
  }
}
