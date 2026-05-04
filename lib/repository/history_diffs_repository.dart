import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

class HistoryDiffsRepository extends BaseFirestoreRepository<HistoryDiff> {
  final String? itemId;
  final ArtifactType? itemType;

  /// Constructor for item-specific operations (canvas/note history)
  HistoryDiffsRepository({
    required super.projectId,
    required this.itemId,
    required this.itemType,
  });

  /// Constructor for project-wide operations
  HistoryDiffsRepository.forProject({
    required super.projectId,
  })  : itemId = null,
        itemType = null;

  @override
  String get collectionPath {
    if (itemId != null && itemType != null) {
      // Item-specific path: projects/{projectId}/{collectionType}/{itemId}/history
      return 'projects/$projectId/artifacts/$itemId/history';
    }
    // For project-wide operations, this won't be used as we'll build paths dynamically
    throw UnsupportedError('Collection path not available for project-wide repository');
  }

  @override
  HistoryDiff fromMap(Map<String, dynamic> map) => HistoryDiff.fromJson(map);

  @override
  Map<String, dynamic> toMap(HistoryDiff item) => item.toJson();

  @override
  String getIdFromItem(HistoryDiff item) => item.timestamp.millisecondsSinceEpoch.toString();

  @override
  bool get updateProjectMetadata => true;

  /// Add a single history diff
  Future<void> addHistoryDiff(HistoryDiff diff) async {
    if (itemId == null || itemType == null) {
      throw ArgumentError('addHistoryDiff() requires itemId and collectionType. Use the item-specific constructor.');
    }

    return execute(() async {
      final timestamp = diff.timestamp.millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('artifacts')
          .doc(itemId!)
          .collection('history')
          .doc(timestamp.toString())
          .set(diff.toJson());
    });
  }

  /// Delete a single history diff by timestamp
  Future<void> deleteHistoryDiff(HistoryDiff diff) async {
    if (itemId == null || itemType == null) {
      throw ArgumentError('deleteHistoryDiff() requires itemId and collectionType. Use the item-specific constructor.');
    }

    return execute(() async {
      final timestamp = diff.timestamp.millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('artifacts')
          .doc(itemId!)
          .collection('history')
          .doc(timestamp.toString())
          .delete();
    });
  }

  /// Restore/add a single history diff back to Firebase
  Future<void> restoreHistoryDiff(HistoryDiff diff) async {
    if (itemId == null || itemType == null) {
      throw ArgumentError(
          'restoreHistoryDiff() requires itemId and collectionType. Use the item-specific constructor.');
    }

    return execute(() async {
      final timestamp = diff.timestamp.millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('artifacts')
          .doc(itemId!)
          .collection('history')
          .doc(timestamp.toString())
          .set(diff.toJson());
    });
  }

  /// Update a single history diff
  Future<void> updateHistoryDiff(HistoryDiff diff) async {
    if (itemId == null || itemType == null) {
      throw ArgumentError('updateHistoryDiff() requires itemId and collectionType. Use the item-specific constructor.');
    }

    return execute(() async {
      final timestamp = diff.timestamp.millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('artifacts')
          .doc(itemId!)
          .collection('history')
          .doc(timestamp.toString())
          .update(diff.toJson());
    });
  }

  /// Get real-time stream of history diffs ordered by timestamp
  Stream<List<HistoryDiff>> getHistoryDiffsStream() {
    if (itemId == null || itemType == null) {
      throw ArgumentError(
          'getHistoryDiffsStream() requires itemId and collectionType. Use the item-specific constructor.');
    }

    return executeStream(() {
      return FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('artifacts')
          .doc(itemId!)
          .collection('history')
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) {
        try {
          final results = <HistoryDiff>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final diff = HistoryDiff.fromJson(data);
              results.add(diff);
            } catch (e) {
              debugPrint('Error parsing diff document ${doc.id}: $e');
              continue;
            }
          }

          return results;
        } catch (e) {
          debugPrint('Error processing diffs snapshot: $e');
          return <HistoryDiff>[];
        }
      }).handleError((error) {
        debugPrint('Fatal error in diffs stream: $error');
        return <HistoryDiff>[];
      });
    }, <HistoryDiff>[]);
  }
}
