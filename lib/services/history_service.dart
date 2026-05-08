import 'package:onyxia/export.dart';
import 'package:json_patch/json_patch.dart';
import 'package:onyxia/presentation/screens/canvas/providers/diff_preview_provider.dart';

class HistoryService {
  static const Symbol _pipeKey = Symbol('pipeActive');
  static bool get pipeActive => Zone.current[_pipeKey] == true;

  static Future<void> initHistory({
    required WidgetRef ref,
    required String projectId,
    required Serializer serializer,
  }) async {
    try {
      final state = await _serializeData(serializer);

      final ops = JsonPatch.diff({}, state);
      if (ops.isEmpty) return; // no changes; nothing to save

      final diff = HistoryDiff(
        userId: ref.read(currentUserProvider).id,
        timestamp: DateTime.now(),
        operations: ops,
        isMilestone: true,
        isRestored: false,
      );

      final params = HistoryDiffsParams(
        projectId: serializer.projectId,
        itemId: serializer.itemId,
        itemType: serializer.itemType,
      );
      ref.read(historyDiffsProvider(params).notifier).addDiff(diff);
    } catch (e) {
      debugPrint('Failed to pipe operation: $e');
      rethrow;
    }
  }

  static Future<void> initHistoryFromProvider({
    required Ref<Object?> ref,
    required String projectId,
    required Serializer serializer,
  }) async {
    try {
      final state = await _serializeData(serializer);

      final ops = JsonPatch.diff({}, state);
      if (ops.isEmpty) return; // no changes; nothing to save

      final diff = HistoryDiff(
        userId: ref.read(currentUserProvider).id,
        timestamp: DateTime.now(),
        operations: ops,
        isMilestone: true,
        isRestored: false,
      );

      final params = HistoryDiffsParams(
        projectId: serializer.projectId,
        itemId: serializer.itemId,
        itemType: serializer.itemType,
      );
      ref.read(historyDiffsProvider(params).notifier).addDiff(diff);
    } catch (e) {
      debugPrint('Failed to pipe operation: $e');
      rethrow;
    }
  }

  /// Performs an operation and creates a diff to store the difference
  ///
  /// [forceMilestone] — marks the **previous** diff as a milestone before
  /// adding the new one. Use for manual save-points where the prior state
  /// should become a top-level header.
  ///
  /// [markCurrentAsMilestone] — marks the **new** diff itself as a milestone
  /// so it becomes its own top-level header in the history list rather than a
  /// child of the previous milestone. Use this for discrete, identifiable
  /// operations (e.g. each repository re-evaluation) that should each appear
  /// as a separate entry in the timeline.
  static Future<void> pipe({
    required WidgetRef ref,
    required String projectId,
    required Future<void> Function() operation,
    required Serializer serializer,
    bool forceMilestone = false,
    bool markCurrentAsMilestone = false,
  }) async {
    try {
      final beforeState = await _serializeData(serializer);

      // run the operation in a zone to make sure nested operations don't call pipe() again
      await runZoned(
        () async => await operation(),
        zoneValues: {_pipeKey: true},
      );

      final afterState = await _serializeData(serializer);

      final ops = JsonPatch.diff(beforeState, afterState);
      if (ops.isEmpty) return;

      final params = HistoryDiffsParams(
        projectId: serializer.projectId,
        itemId: serializer.itemId,
        itemType: serializer.itemType,
      );
      final historyNotifier = ref.read(historyDiffsProvider(params).notifier);

      // Check if 2 hours have passed since the last diff
      final historyDiffs = ref.read(historyDiffsProvider(params));
      final lastDiff = historyDiffs.remoteDiffs.lastOrNull;
      final now = DateTime.now();
      final has2HoursPassed = lastDiff != null && now.difference(lastDiff.timestamp).inHours >= 2;

      if (lastDiff != null) {
        if ((has2HoursPassed || forceMilestone) && !lastDiff.isMilestone) {
          historyNotifier.updateDiff(lastDiff.copyWith(isMilestone: true));
        }
      }

      final diff = HistoryDiff(
        userId: ref.read(currentUserProvider).id,
        timestamp: now,
        operations: ops,
        isMilestone: markCurrentAsMilestone || has2HoursPassed,
        isRestored: false,
      );

      historyNotifier.addDiff(diff);

      // Update canvas metadata if this is a canvas operation
      if (serializer.itemType == ArtifactType.canvas) {
        try {
          final currentCanvas = await ArtifactsRepository(projectId: projectId).get(serializer.itemId);
          if (currentCanvas != null) {
            // The Postgres set_updated_audit trigger sets updated_at / updated_by on this UPDATE.
            await ArtifactsRepository(projectId: projectId).update(currentCanvas);
          }
        } catch (canvasUpdateError) {
          debugPrint('Failed to update canvas metadata: $canvasUpdateError');
          // Don't rethrow canvas update errors - the main operation already succeeded
        }
      }
    } catch (e) {
      debugPrint('Failed to pipe operation: $e');
      rethrow;
    }
  }

  /// Time travels to a specific diff by applying diffs chronologically
  /// Returns the state at the target diff point
  static Future<void> travel({
    required WidgetRef ref,
    required String projectId,
    required HistoryDiff targetDiff,
    required Serializer serializer,
  }) async {
    try {
      final reconstructedState = reconstructState(
        ref: ref,
        targetDiff: targetDiff,
        serializer: serializer,
      );

      // Handle different data structures based on feature type
      if (serializer.itemType == ArtifactType.note) {
        // Parse note data directly from reconstructed state
        try {
          final note = Note.fromMap(reconstructedState);
          ref.read(artifactsDiffPreviewProvider.notifier).showHistoricalState(
                note: note,
                targetDiff: targetDiff,
              );
        } catch (e) {
          debugPrint('Error parsing historical note: $e');
          debugPrint('Problematic note data: $reconstructedState');
        }
      } else {
        // Canvas data structure parsing
        final List<CanvasObject> historicalObjects = [];
        final List<Comment> historicalComments = [];
        final List<Pin> historicalPins = [];

        if (reconstructedState.containsKey('objects')) {
          final objectsData = List<Map<String, dynamic>>.from(reconstructedState['objects']);

          for (int i = 0; i < objectsData.length; i++) {
            final objData = objectsData[i];
            try {
              historicalObjects.add(CanvasObject.fromMap(objData));
            } catch (e) {
              debugPrint('Error parsing historical object $i: $e');
              debugPrint('Problematic object data: $objData');
            }
          }
        }

        // Parse historical comments
        if (reconstructedState.containsKey('comments')) {
          final commentsData = List<Map<String, dynamic>>.from(reconstructedState['comments']);

          for (int i = 0; i < commentsData.length; i++) {
            final commentData = commentsData[i];
            try {
              final comment = Comment.fromMap(commentData);
              historicalComments.add(comment);
            } catch (e) {
              debugPrint('Error parsing historical comment $i: $e');
              debugPrint('Problematic comment data: $commentData');
            }
          }
        }

        // Parse historical note pins
        if (reconstructedState.containsKey('pins')) {
          final pinsData = List<Map<String, dynamic>>.from(reconstructedState['pins']);

          for (int i = 0; i < pinsData.length; i++) {
            final pinData = pinsData[i];
            try {
              final pin = Pin.fromMap(pinData);
              historicalPins.add(pin);
            } catch (e) {
              debugPrint('Error parsing historical note pin $i: $e');
              debugPrint('Problematic pin data: $pinData');
            }
          }
        }

        // Extract historical canvas imageUrl
        String? historicalImageUrl;
        if (reconstructedState.containsKey('canvas')) {
          final canvasData = Map<String, dynamic>.from(reconstructedState['canvas']);
          historicalImageUrl = canvasData['imageUrl'] as String?;
        }

        ref.read(canvasDiffPreviewProvider.notifier).showHistoricalState(
              objects: historicalObjects,
              comments: historicalComments,
              pins: historicalPins,
              imageUrl: historicalImageUrl,
            );
      }
    } catch (e) {
      debugPrint('Failed to travel to diff: $e');
      rethrow;
    }
  }

  /// Restores state to the state up to the targetDiff
  static Future<void> restore({
    required WidgetRef ref,
    required String projectId,
    required HistoryDiff targetDiff,
    required Serializer serializer,
  }) async {
    // Use the appropriate preview provider based on feature type
    if (serializer.itemType == ArtifactType.canvas) {
      final previewNotifier = ref.read(canvasDiffPreviewProvider.notifier);
      if (previewNotifier.isRestoring) return;
      previewNotifier.setRestoring(true);
    } else {
      final previewNotifier = ref.read(artifactsDiffPreviewProvider.notifier);
      if (previewNotifier.isRestoring) return;
      previewNotifier.setRestoring(true);
    }

    try {
      final currentState = await _serializeData(serializer);

      final reconstructedState = reconstructState(
        ref: ref,
        targetDiff: targetDiff,
        serializer: serializer,
      );

      final ops = JsonPatch.diff(currentState, reconstructedState);
      if (ops.isEmpty) return;

      // update the previous diff to a milestone if it isn't one
      final params = HistoryDiffsParams(
        projectId: projectId,
        itemId: serializer.itemId,
        itemType: serializer.itemType,
      );
      final lastDiff = ref.read(historyDiffsProvider(params)).remoteDiffs.lastOrNull;
      if (!lastDiff!.isMilestone) {
        ref.read(historyDiffsProvider(params).notifier).updateDiff(
              lastDiff.copyWith(isMilestone: true),
            );
      }

      final diff = HistoryDiff(
        userId: ref.read(currentUserProvider).id,
        timestamp: DateTime.now(),
        operations: ops,
        isMilestone: false,
        isRestored: true,
        title: targetDiff.title,
      );
      ref.read(historyDiffsProvider(params).notifier).addDiff(diff);

      await serializer.deserialize(reconstructedState);
    } catch (e) {
      debugPrint('Failed to restore diff: $e');
      rethrow;
    } finally {
      // Clear restoration state based on feature type
      if (serializer.itemType == ArtifactType.canvas) {
        final previewNotifier = ref.read(canvasDiffPreviewProvider.notifier);
        previewNotifier.setRestoring(false);
        previewNotifier.clearPreview();
      } else {
        final previewNotifier = ref.read(artifactsDiffPreviewProvider.notifier);
        previewNotifier.setRestoring(false);
        previewNotifier.clearPreview();
      }
      final params = HistoryDiffsParams(
        projectId: projectId,
        itemId: serializer.itemId,
        itemType: serializer.itemType,
      );
      ref.read(historyDiffsProvider(params).notifier).resetSelection();
    }
  }

  static Map<String, dynamic> reconstructState({
    required WidgetRef ref,
    required HistoryDiff targetDiff,
    required Serializer serializer,
  }) {
    final params = HistoryDiffsParams(
      projectId: serializer.projectId,
      itemId: serializer.itemId,
      itemType: serializer.itemType,
    );
    final diffs = ref.read(historyDiffsProvider(params));

    if (!diffs.remoteDiffs.contains(targetDiff)) {
      throw Exception('targetDiff not found in remoteDiffs');
    }

    final ops = diffs.remoteDiffs
        .sublist(
          0,
          diffs.remoteDiffs.indexOf(targetDiff) + 1,
        )
        .map((e) => e.operations)
        .flattened
        .toList();
    if (ops.isEmpty) throw Exception('diffsToApply is empty');

    Map<String, dynamic> reconstructedState = JsonPatch.apply(
      {},
      ops,
      strict: true,
    );

    if (reconstructedState.isEmpty) {
      throw Exception('reconstructed state is empty');
    }

    return reconstructedState;
  }

  static Future<Map<String, dynamic>> _serializeData(Serializer serializer) async {
    try {
      return await serializer.serialize();
    } catch (e) {
      debugPrint('Failed to serialize state: $e');
      rethrow;
    }
  }
}
