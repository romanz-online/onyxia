import 'package:onyxia/export.dart';

class ArtifactsTreeView extends ConsumerStatefulWidget {
  const ArtifactsTreeView({
    super.key,
    this.onClickNode,
    this.onDoubleClickNode,
  });

  final void Function(Artifact item)? onClickNode;
  final void Function(Artifact item)? onDoubleClickNode;

  @override
  ArtifactsTreeViewState createState() => ArtifactsTreeViewState();
}

class ArtifactsTreeViewState extends ConsumerState<ArtifactsTreeView> {
  List<TreeNode<Artifact>> _roots = [];
  late TreeController<Artifact> treeController;
  StreamSubscription<TreeNodeMovedEvent<Artifact>>? _moveSubscription;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<Artifact>(roots: _roots);
    _subscribeToMoveEvents();
  }

  void _subscribeToMoveEvents() {
    _moveSubscription?.cancel();
    _moveSubscription = treeController.addNodeMovedListener(_onNodesMoved);
  }

  void _onNodesMoved(TreeNodeMovedEvent<Artifact> event) {
    for (final node in event.nodes) {
      final newParentId = node.parent?.id ?? '';
      final success = ref.read(artifactsProvider.notifier).updateParent(
            node.data.id,
            newParentId: newParentId,
          );
      if (success && node.parent != null)
        treeController.expandNode(node.parent!);
    }
  }

  void _selectItem(Artifact item) {
    treeController.setSelectedNodeId(item.id);
    ref.read(selectedArtifactProvider.notifier).state = item;
    ref.read(itemPersistenceProvider.notifier).save(item.id);
    context
        .go(item.navigationUrl(ref.read(projectsProvider).selectedProject.id));
  }

  @override
  void dispose() {
    _moveSubscription?.cancel();
    treeController.dispose();
    super.dispose();
  }

  void _syncTree(List<TreeNode<Artifact>> newRoots) {
    if (!mounted) return;
    _applyExpansionState(newRoots, _getExpansionState(_roots));

    final preserved = treeController.selectedNodeIds
        .where((id) => _findNodeById(newRoots, id) != null)
        .toSet();

    final oldController = treeController;
    _moveSubscription?.cancel();
    setState(() {
      _roots = newRoots;
      treeController = TreeController<Artifact>(roots: newRoots);
    });
    oldController.dispose();
    _subscribeToMoveEvents();

    if (preserved.length == 1) {
      treeController.setSelectedNodeId(preserved.first);
    } else {
      for (final id in preserved) {
        treeController.toggleSelection(id);
      }
    }
  }

  TreeNode<Artifact>? _findNodeById(List<TreeNode<Artifact>> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findNodeById(node.children.toList(), id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final itemNodes = ref.watch(artifactsProvider);
    final isDataLoaded = ref.watch(artifactsLoadedProvider);
    final projectId =
        ref.watch(projectsProvider.select((s) => s.selectedProject.id));
    final hasError = ref.watch(artifactsErrorProvider(projectId));

    final selectedItem = ref.read(selectedArtifactProvider);
    if (selectedItem != null &&
        !itemNodes.any((req) => req.id == selectedItem.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedArtifactProvider.notifier).state = null;
      });
    }

    // Detect tree changes and schedule a controller sync after this frame
    final newRoots = populateTree(itemNodes);
    if (_isTreeChanged(_roots, newRoots)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTree(newRoots));
    }

    if (hasError)
      return Center(
        child: Text(
          'Error loading items. Please refresh the page.',
          style: NarwhalTextStyle(),
        ),
      );

    if (!isDataLoaded) return Center(child: NarwhalSpinner());

    if (itemNodes.isEmpty) return const SizedBox.shrink();

    return SuperTreeView<Artifact>(
      controller: treeController,
      expansionSlotSize: 20,
      expansionBuilder: (ctx, node) => node.hasChildren
          ? NarwhalIcon(
              NarwhalIcons.expandArrowCollapsed,
              color: ThemeHelper.neutral900(context),
            )
          : const SizedBox.shrink(),
      prefixBuilder: (ctx, node) => node.data.type == ArtifactType.folder
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: NarwhalIcon(
                node.isExpanded
                    ? NarwhalIcons.folderOpened
                    : NarwhalIcons.folderClosed,
                color: ThemeHelper.neutral900(context),
              ),
            )
          : const SizedBox.shrink(),
      contentBuilder: (context, node, _) => TreeTile(node: node),
      style: TreeViewStyle(
        indentAmount: 16.0,
        padding: EdgeInsets.symmetric(vertical: 0),
        hoverColor: ThemeHelper.neutral200(context),
        selectedColor: ThemeHelper.neutral200(context),
      ),
      logic: TreeViewConfig(
        enableDragAndDrop: true,
        selectionMode: SelectionMode.multiple,
        expansionTrigger: ExpansionTrigger.tap,
        onNodeTap: (id) => _onNodeTapped(id),
        onNodeDoubleTap: (id) => _onNodeDoubleTapped(id),
        dragAndDrop: TreeDragAndDropConfig(
          canAcceptDrop: (draggedNode, targetNode, position) {
            TreeNode<Artifact>? cursor = targetNode;
            while (cursor != null) {
              if (position != NodeDropPosition.inside) return false;
              if (cursor.id == draggedNode.id) return false;
              if (targetNode.data.type != ArtifactType.folder) return false;
              cursor = cursor.parent;
            }
            return true;
          },
        ),
      ),
      contextMenuBuilder: (ctx, node) => _buildContextMenuItems(
        artifactsContextMenuOptions().options,
        node,
      ),
    );
  }

  void _onNodeTapped(String id) {
    if (widget.onClickNode != null) {
      final item = ref.read(artifactsProvider.notifier).getItemById(id);
      if (item != null) widget.onClickNode!.call(item);
      return;
    }

    final hasModifier = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isShiftPressed;
    if (hasModifier) return;

    final item = ref.read(artifactsProvider.notifier).getItemById(id);
    // don't select folders, just let the tree open them
    if (item == null || item.type == ArtifactType.folder) return;
    _selectItem(item);
  }

  void _onNodeDoubleTapped(String id) {
    final item = ref.read(artifactsProvider.notifier).getItemById(id);
    if (item == null) return;
    if (widget.onDoubleClickNode == null) {
      _selectItem(item);
    } else {
      widget.onDoubleClickNode!.call(item);
    }
  }

  bool _isTreeChanged(
      List<TreeNode<Artifact>> oldRoots, List<TreeNode<Artifact>> newRoots) {
    if (oldRoots.length != newRoots.length) return true;
    for (int i = 0; i < oldRoots.length; i++) {
      if (oldRoots[i].data.title != newRoots[i].data.title) return true;
      if (_isTreeChanged(
          oldRoots[i].children.toList(), newRoots[i].children.toList()))
        return true;
    }
    return false;
  }

  Map<String, bool> _getExpansionState(List<TreeNode<Artifact>> roots) {
    final Map<String, bool> state = {};
    void collect(TreeNode<Artifact> node) {
      state[node.id] = node.isExpanded;
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final root in roots) {
      collect(root);
    }
    return state;
  }

  void _applyExpansionState(
      List<TreeNode<Artifact>> roots, Map<String, bool> state) {
    void apply(TreeNode<Artifact> node) {
      node.isExpanded = state[node.id] ?? true;
      for (final child in node.children) {
        apply(child);
      }
    }

    for (final root in roots) {
      apply(root);
    }
  }

  List<ContextMenuItem> _buildContextMenuItems(
    List<TreeContextMenuOption> options,
    TreeNode<Artifact> node,
  ) {
    final List<ContextMenuItem> items = [];
    final selectedIds = treeController.selectedNodeIds;
    for (final opt in options) {
      if (opt.dividerBefore && items.isNotEmpty) {
        items.add(ContextMenuItem(
          child: const Divider(height: 1, thickness: 1),
          onTap: () {},
        ));
      }
      items.add(ContextMenuItem(
        child: Text(opt.label, style: NarwhalTextStyle()),
        onTap: () {
          opt.callback(context, ref, node, selectedIds);
          if (opt.clearSelectionAfter) treeController.deselectAll();
        },
      ));
    }
    return items;
  }
}

List<TreeNode<Artifact>> populateTree(List<Artifact> items) {
  final Map<String, List<Artifact>> childrenMap = {};
  for (final item in items.where((i) => i.parent.isNotEmpty)) {
    childrenMap.putIfAbsent(item.parent, () => []).add(item);
  }

  TreeNode<Artifact> buildNode(Artifact item) {
    final childItems = childrenMap[item.id] ?? [];
    return TreeNode<Artifact>(
      id: item.id,
      data: item,
      isExpanded: true,
      children: childItems.map(buildNode).toList(),
    );
  }

  final rootItems = items.where((i) => i.parent.isEmpty).toList();
  return rootItems.map(buildNode).toList();
}
