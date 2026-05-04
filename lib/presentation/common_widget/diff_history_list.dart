import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/screens/canvas/providers/providers.dart';

class MilestoneGroup {
  final HistoryDiff milestone;
  final List<HistoryDiff> diffs;
  // true if milestone is a regular diff acting as a milestone
  final bool isPseudoMilestone;

  const MilestoneGroup({
    required this.milestone,
    required this.diffs,
    this.isPseudoMilestone = false,
  });

  MilestoneGroup copyWith({
    HistoryDiff? milestone,
    List<HistoryDiff>? diffs,
    bool? isPseudoMilestone,
  }) {
    return MilestoneGroup(
      milestone: milestone ?? this.milestone,
      diffs: diffs ?? this.diffs,
      isPseudoMilestone: isPseudoMilestone ?? this.isPseudoMilestone,
    );
  }
}

class DiffHistoryList extends ConsumerStatefulWidget {
  final String projectId;
  final String itemId;
  final ArtifactType itemType;
  final VoidCallback? onCanvasReload;

  const DiffHistoryList({
    super.key,
    required this.projectId,
    required this.itemId,
    required this.itemType,
    this.onCanvasReload,
  });

  @override
  ConsumerState<DiffHistoryList> createState() => _DiffHistoryListState();
}

class _DiffHistoryListState extends ConsumerState<DiffHistoryList> {
  final Map<String, UserDefinition> _userCache = {};
  final Set<String> _expandedGroups = {};
  late List<MilestoneGroup> _groups;
  bool _hasReceivedInitialDiffs = false;
  ProviderSubscription? _historyListener;

  HistoryDiffsParams get _providerParams => HistoryDiffsParams(
        projectId: widget.projectId,
        itemId: widget.itemId,
        itemType: widget.itemType,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final diffs = ref.read(historyDiffsProvider(_providerParams)).remoteDiffs;
      if (diffs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _hasReceivedInitialDiffs = true;
          });
        }
        return;
      }

      if (mounted) {
        _historyListener = ref.listenManual(historyDiffsProvider(_providerParams), (previous, next) {
          if (!_hasReceivedInitialDiffs && mounted) {
            setState(() {
              _hasReceivedInitialDiffs = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _historyListener?.close();
    super.dispose();
  }

  void toggleGroup(String groupId) {
    if (!mounted) return;
    final selectedDiff = ref.read(historyDiffsProvider(_providerParams)).selectedDiff;

    // Check if this group or any of its diffs are selected
    final group = _groups.firstWhere((g) => _getGroupId(g.milestone) == groupId);
    final isGroupSelected = group.milestone == selectedDiff || group.diffs.contains(selectedDiff);

    // If selected, don't allow toggling closed
    if (isGroupSelected && _expandedGroups.contains(groupId)) {
      return;
    }

    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  void expandGroup(String groupId) {
    if (mounted) {
      setState(() {
        _expandedGroups.add(groupId);
      });
    }
  }

  void collapseGroup(String groupId) {
    if (mounted) {
      setState(() {
        _expandedGroups.remove(groupId);
      });
    }
  }

  String _getGroupId(HistoryDiff milestone) => milestone.timestamp.millisecondsSinceEpoch.toString();

  Future<UserDefinition> _getUser(String userId) async {
    if (userId.isEmpty) return UserDefinition.initial();

    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    try {
      if (!mounted) return UserDefinition.initial();
      final user = await ref.read(userLookupProvider).getUserById(userId);
      if (!mounted) return UserDefinition.initial();
      _userCache[userId] = user;
      return user;
    } catch (e) {
      if (!mounted) return UserDefinition.initial();
      final fallbackUser = UserDefinition.initial().copyWith(name: userId, id: userId);
      _userCache[userId] = fallbackUser;
      return fallbackUser;
    }
  }

  void restoreDiff(HistoryDiff diff) async {
    if (!mounted) return;

    // Check restoration state based on feature type
    if (!mounted) return;
    if (widget.itemType == ArtifactType.canvas) {
      final preview = ref.read(canvasDiffPreviewProvider);
      if (preview != null && preview.isRestoring) return;
    } else {
      final preview = ref.read(artifactsDiffPreviewProvider);
      if (preview != null && preview.isRestoring) return;
    }

    if (!mounted) return;
    final projectId = ref.read(projectsProvider).selectedProject.id;

    try {
      if (!mounted) return;
      dynamic serializer;
      if (widget.itemType == ArtifactType.canvas) {
        serializer = CanvasSerializerService(
          canvasId: ref.read(currentCanvasProvider)?.id ?? '',
          projectId: projectId,
          repository: ArtifactsRepository(projectId: ref.read(projectsProvider).selectedProject.id),
        );
      } else {
        // For notes, use NoteSerializerService
        serializer = NoteSerializerService(
          itemId: widget.itemId,
          projectId: projectId,
          repository: ArtifactsRepository(projectId: ref.read(projectsProvider).selectedProject.id),
        );
      }

      if (!mounted) return;
      await HistoryService.restore(
        ref: ref,
        projectId: projectId,
        targetDiff: diff,
        serializer: serializer,
      );

      // After restore completes, refresh the editor to show restored content
      if (widget.itemType == ArtifactType.note) {
        try {
          final selectedItem = ref.read(selectedArtifactProvider);
          if (selectedItem != null && selectedItem.id == widget.itemId) {
            // Use refresh to force immediate rebuild
            final refreshedState = ref.refresh(selectedNoteStateProvider);
            debugPrint(
                'DiffHistoryList: Editor refreshed with state: ${refreshedState.hasValue ? "loaded" : "loading"}');
          }
        } catch (e) {
          debugPrint('DiffHistoryList: Editor refresh failed: $e');
          // Non-critical, continue
        }
      }

      // Only reload canvas if it's a markup canvas and callback is provided
      final selectedItem = ref.read(selectedArtifactProvider);
      final currentCanvas = selectedItem is CanvasModel ? selectedItem : null;
      if (currentCanvas?.canvasType == CanvasType.markup && widget.onCanvasReload != null) {
        widget.onCanvasReload!();
      }
    } catch (e) {
      debugPrint('Failed to restore ${widget.itemType.name} state: $e');
    }
  }

  void renameDiff(HistoryDiff diff, String newTitle) async {
    if (!mounted) return;
    try {
      ref.read(historyDiffsProvider(_providerParams).notifier).updateDiff(
            diff.copyWith(title: newTitle),
          );
    } catch (e) {
      debugPrint('Error renaming diff: $e');
    }
  }

  List<MilestoneGroup> _generateGroups(List<HistoryDiff> diffs) {
    final List<MilestoneGroup> groups = [];
    MilestoneGroup? currentGroup;

    // print('${diff.timestamp} ${diff.isMilestone}');
    final orderedDiffs = diffs.reversed.toList();
    for (final diff in orderedDiffs) {
      if (currentGroup == null) {
        currentGroup = MilestoneGroup(
          milestone: diff,
          diffs: [],
          isPseudoMilestone: !diff.isMilestone,
        );
      } else {
        if (diff.isMilestone) {
          groups.add(currentGroup.copyWith());
          currentGroup = MilestoneGroup(
            milestone: diff,
            diffs: [],
            isPseudoMilestone: !diff.isMilestone,
          );
        } else {
          currentGroup.diffs.add(diff);
        }
      }
    }

    if (currentGroup != null && !groups.contains(currentGroup)) {
      groups.add(currentGroup);
    }

    return groups;
  }

  void showDiff(HistoryDiff diff) async {
    if (!mounted) return;

    try {
      ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    } catch (e) {
      debugPrint('Error clearing selected objects: $e');
      if (!mounted) return;
    }

    // Find which group this diff belongs to and ensure it's expanded
    for (final group in _groups) {
      if (group.milestone == diff || group.diffs.contains(diff)) {
        // Always expand the group that contains the selected diff
        expandGroup(_getGroupId(group.milestone));
        break;
      }
    }

    if (!mounted) return;

    try {
      ref.read(historyDiffsProvider(_providerParams).notifier).selectDiff(diff);
    } catch (e) {
      debugPrint('Error selecting diff: $e');
      if (!mounted) return;
    }

    // if clicking on the current diff, cancel preview
    if (!mounted) return;

    try {
      if (diff == ref.read(historyDiffsProvider(_providerParams)).currentDiff) {
        if (widget.itemType == ArtifactType.canvas) {
          ref.read(canvasDiffPreviewProvider.notifier).clearPreview();
        } else {
          ref.read(artifactsDiffPreviewProvider.notifier).clearPreview();
        }
        return;
      }
    } catch (e) {
      debugPrint('Error checking current diff: $e');
      if (!mounted) return;
    }

    try {
      dynamic serializer;
      if (widget.itemType == ArtifactType.canvas) {
        serializer = CanvasSerializerService(
          canvasId: widget.itemId,
          projectId: widget.projectId,
          repository: ArtifactsRepository(projectId: ref.read(projectsProvider).selectedProject.id),
        );
      } else {
        // For notes, use NoteSerializerService
        serializer = NoteSerializerService(
          itemId: widget.itemId,
          projectId: widget.projectId,
          repository: ArtifactsRepository(projectId: ref.read(projectsProvider).selectedProject.id),
        );
      }

      await HistoryService.travel(
        ref: ref,
        projectId: widget.projectId,
        targetDiff: diff,
        serializer: serializer,
      );
    } catch (e) {
      debugPrint('showDiff error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return Container();
    final diffs = ref.watch(historyDiffsProvider(_providerParams));

    // Wait for initial Firebase stream callback before rendering
    if (!_hasReceivedInitialDiffs) {
      return Center(
        child: NarwhalSpinner(),
      );
    } else if (diffs.remoteDiffs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: ThemeHelper.neutral400(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No history available yet',
              style: NarwhalTextStyle(
                fontSize: 16,
                color: ThemeHelper.neutral600(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make some changes to see the history',
              style: NarwhalTextStyle(
                fontSize: 14,
                color: ThemeHelper.neutral500(context),
              ),
            ),
          ],
        ),
      );
    }

    _groups = _generateGroups(diffs.remoteDiffs);

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 8,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final groupId = _getGroupId(group.milestone);

        final isExpanded = _expandedGroups.contains(groupId);
        final hasChildDiffs = group.diffs.isNotEmpty;

        return MilestoneGroupWidget(
          group: group,
          isExpanded: isExpanded,
          hasChildDiffs: hasChildDiffs,
          onToggle: () => toggleGroup(groupId),
          onDiffTap: showDiff,
          onRestore: (diff) => restoreDiff(diff),
          onRename: renameDiff,
          selectedDiff: diffs.selectedDiff,
          isCurrent: index == 0,
          getUser: _getUser,
        );
      },
    );
  }
}

class MilestoneGroupWidget extends ConsumerWidget {
  final MilestoneGroup group;
  final bool isExpanded;
  final bool hasChildDiffs;
  final VoidCallback onToggle;
  final Function(HistoryDiff) onDiffTap;
  final Function(HistoryDiff) onRestore;
  final Function(HistoryDiff, String) onRename;
  final HistoryDiff? selectedDiff;
  final bool isCurrent;
  final Future<UserDefinition> Function(String) getUser;

  const MilestoneGroupWidget({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.hasChildDiffs,
    required this.onToggle,
    required this.onDiffTap,
    required this.onRestore,
    required this.onRename,
    required this.selectedDiff,
    required this.isCurrent,
    required this.getUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Milestone header
        FutureBuilder<UserDefinition>(
          future: getUser(group.milestone.userId),
          builder: (context, snapshot) {
            final user = snapshot.data ?? UserDefinition.initial().copyWith(name: group.milestone.userId);

            return Padding(
              padding: EdgeInsets.only(top: 8),
              child: DiffTile(
                diff: group.milestone,
                isSelected: group.milestone == selectedDiff,
                isCurrent: isCurrent,
                user: user,
                isPseudoMilestone: group.isPseudoMilestone,
                hasChildDiffs: hasChildDiffs,
                isExpanded: isExpanded,
                onTap: () => onDiffTap(group.milestone),
                onRestore: () => onRestore(group.milestone),
                onRename: (newName) => onRename(group.milestone, newName),
                onCaretTap: hasChildDiffs ? onToggle : null,
              ),
            );
          },
        ),

        isExpanded
            ? Column(
                children: group.diffs.map((diff) {
                  return FutureBuilder<UserDefinition>(
                      future: getUser(diff.userId),
                      builder: (context, snapshot) => DiffTile(
                            diff: diff,
                            isSelected: diff == selectedDiff,
                            isCurrent: false,
                            user: snapshot.data ?? UserDefinition.initial().copyWith(name: diff.userId),
                            onTap: () => onDiffTap(diff),
                            onRestore: () => onRestore(diff),
                            onRename: (newName) => onRename(diff, newName),
                            isChildDiff: true,
                          ));
                }).toList(),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
