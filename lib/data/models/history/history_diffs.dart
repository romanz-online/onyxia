import 'package:onyxia/export.dart';

class HistoryDiffs {
  final HistoryDiff? selectedDiff;
  final HistoryDiff? currentDiff;
  final List<HistoryDiff> remoteDiffs;
  final List<HistoryDiff> localDiffs;
  final DateTime? createdAt;

  HistoryDiffs({
    this.selectedDiff,
    this.currentDiff,
    required this.remoteDiffs,
    required this.localDiffs,
    this.createdAt,
  });

  factory HistoryDiffs.initial() => HistoryDiffs(
        remoteDiffs: [],
        localDiffs: [],
      );

  HistoryDiffs copyWith({
    HistoryDiff? selectedDiff,
    HistoryDiff? currentDiff,
    List<HistoryDiff>? remoteDiffs,
    List<HistoryDiff>? localDiffs,
    DateTime? createdAt,
  }) {
    return HistoryDiffs(
      selectedDiff: selectedDiff ?? this.selectedDiff,
      currentDiff: currentDiff ?? this.currentDiff,
      remoteDiffs: remoteDiffs ?? this.remoteDiffs,
      localDiffs: localDiffs ?? this.localDiffs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryDiffs &&
        listEquals(other.remoteDiffs, remoteDiffs) &&
        listEquals(other.localDiffs, localDiffs) &&
        other.currentDiff == currentDiff &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      remoteDiffs.hashCode ^
      localDiffs.hashCode ^
      currentDiff.hashCode ^
      createdAt.hashCode;
}
