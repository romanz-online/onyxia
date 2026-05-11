import 'package:onyxia/export.dart';

class HistoryDiff {
  final String id;
  final int seq;
  final String title;
  final List<Map<String, dynamic>> operations;
  final bool isMilestone;
  final bool isRestored;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const HistoryDiff({
    this.id = '',
    this.seq = 0,
    this.title = '',
    required this.operations,
    required this.isMilestone,
    required this.isRestored,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  /// Top-level Postgres columns. Repository injects `canvas_artifact_id`;
  /// `seq` is assigned by the Phase B trigger.
  Map<String, dynamic> toMap() => {
        if (id.isNotEmpty) 'id': id,
        'diff': {
          'created_by': createdBy,
          'title': title,
          'operations': operations,
          'is_milestone': isMilestone,
          'is_restored': isRestored,
        },
      };

  factory HistoryDiff.fromMap(Map<String, dynamic> map) {
    final diff =
        (map['diff'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return HistoryDiff(
        id: map['id'] ?? '',
        seq: (map['seq'] as num?)?.toInt() ?? 0,
        title: diff['title'] ?? '',
        operations: List<Map<String, dynamic>>.from(diff['operations'] ?? []),
        isMilestone: diff['is_milestone'] ?? false,
        isRestored: diff['is_restored'] ?? false,
        //
        createdAt: TimestampService.fromMap(map['created_at']),
        createdBy: map['created_by'] ?? '',
        updatedAt: TimestampService.fromMap(map['updated_at']),
        updatedBy: map['updated_by'] ?? '');
  }

  HistoryDiff copyWith({
    String? id,
    int? seq,
    String? title,
    List<Map<String, dynamic>>? operations,
    bool? isMilestone,
    bool? isRestored,
  }) {
    return HistoryDiff(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      title: title ?? this.title,
      operations: operations ?? this.operations,
      isMilestone: isMilestone ?? this.isMilestone,
      isRestored: isRestored ?? this.isRestored,
    );
  }

  @override
  String toString() {
    return 'HistoryDiff(userId: $createdBy, '
        'title: $title, '
        'isMilestone: $isMilestone, '
        'isRestored: $isRestored, '
        //
        'createdAt: $createdAt, '
        'createdBy: $createdBy, '
        'updatedAt: $updatedAt, '
        'updatedBy: $updatedBy, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryDiff &&
        other.title == title &&
        other.isMilestone == isMilestone &&
        other.isRestored == isRestored &&
        //
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        operations.hashCode ^
        isMilestone.hashCode ^
        isRestored.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }
}

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
