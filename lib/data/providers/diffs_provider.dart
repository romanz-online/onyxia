import 'package:onyxia/export.dart';

final historyDiffsProvider =
    StateNotifierProvider.autoDispose.family<HistoryDiffsNotifier, HistoryDiffs, HistoryDiffsParams>((ref, params) {
  return HistoryDiffsNotifier(
    projectId: params.projectId,
    itemId: params.itemId,
    itemType: params.itemType,
    repository: HistoryDiffsRepository(
      projectId: params.projectId,
      itemId: params.itemId,
      itemType: params.itemType,
    ),
  );
});

class HistoryDiffsParams {
  final String projectId;
  final String itemId;
  final ArtifactType itemType;

  const HistoryDiffsParams({
    required this.projectId,
    required this.itemId,
    required this.itemType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryDiffsParams &&
        other.projectId == projectId &&
        other.itemId == itemId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(projectId, itemId, itemType);
}

class HistoryDiffsNotifier extends StateNotifier<HistoryDiffs> {
  final String projectId;
  final String itemId;
  final ArtifactType itemType;
  final HistoryDiffsRepository repository;
  StreamSubscription<List<HistoryDiff>>? _subscription;

  HistoryDiffsNotifier({
    required this.projectId,
    required this.itemId,
    required this.itemType,
    required this.repository,
  }) : super(HistoryDiffs.initial()) {
    _init();
  }

  void _init() {
    _subscription = repository.getHistoryDiffsStream().listen((remoteDiffs) {
      if (!mounted) return;
      List<HistoryDiff> newLocalDiffs = state.localDiffs;
      final anyNew = state.currentDiff != null &&
          remoteDiffs.any((e) => e.timestamp.isAfter(state.currentDiff!.timestamp) && !state.localDiffs.contains(e));
      // TODO: undo can't go past the first local diff because then the list will be empty
      if (anyNew) {
        // renew localDiffs with all diffs that come after our creation time
        // only if a new diff was added
        newLocalDiffs = remoteDiffs
            .where((diff) => diff.timestamp.isAfter(state.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)))
            .toList();
      }

      final newCurrentDiff = remoteDiffs.isEmpty ? null : remoteDiffs.last;
      final newSelectedDiff =
          state.selectedDiff == state.currentDiff || state.selectedDiff == null ? newCurrentDiff : state.selectedDiff;

      state = state.copyWith(
        remoteDiffs: remoteDiffs,
        localDiffs: newLocalDiffs,
        currentDiff: newCurrentDiff,
        selectedDiff: newSelectedDiff,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get canUndo =>
      state.currentDiff != null &&
      state.localDiffs.length > 1 &&
      state.localDiffs.contains(state.currentDiff) &&
      state.currentDiff != state.localDiffs.first;

  bool get canRedo =>
      state.currentDiff != null &&
      state.localDiffs.length > 1 &&
      state.localDiffs.contains(state.currentDiff) &&
      state.currentDiff != state.localDiffs.last;

  void selectDiff(HistoryDiff diff) {
    state = state.copyWith(selectedDiff: diff);
  }

  void resetSelection() {
    final currentDiff = state.currentDiff;
    if (currentDiff == null) {
      throw Exception('currentDiff is null');
    }
    selectDiff(currentDiff);
  }

  void addDiff(HistoryDiff diff) {
    repository.addHistoryDiff(diff);
  }

  Future<bool> undo() async {
    if (!canUndo) return false;

    final currentIndex = state.localDiffs.indexOf(state.currentDiff!);
    final previousDiff = state.localDiffs[currentIndex - 1];
    final diffToDelete = state.currentDiff!;
    final newSelectedDiff =
        state.selectedDiff == state.currentDiff || state.selectedDiff == null ? previousDiff : state.selectedDiff;

    await repository.deleteHistoryDiff(diffToDelete);

    state = state.copyWith(
      currentDiff: previousDiff,
      selectedDiff: newSelectedDiff,
    );

    return true;
  }

  Future<bool> redo() async {
    if (!canRedo) return false;

    final currentIndex = state.localDiffs.indexOf(state.currentDiff!);
    final nextDiff = state.localDiffs[currentIndex + 1];
    final newSelectedDiff =
        state.selectedDiff == state.currentDiff || state.selectedDiff == null ? nextDiff : state.selectedDiff;

    await repository.restoreHistoryDiff(nextDiff);

    state = state.copyWith(
      currentDiff: nextDiff,
      selectedDiff: newSelectedDiff,
    );

    return true;
  }

  void updateDiff(HistoryDiff diff) {
    repository.updateHistoryDiff(diff);
  }
}
