import 'package:onyxia/export.dart';
import 'dart:async';

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

  @override
  void dispose() {
    _moveSubscription?.cancel();
    treeController.dispose();
    super.dispose();
  }

  void _subscribeToMoveEvents() {
    _moveSubscription?.cancel();
    _moveSubscription = treeController.addNodeMovedListener(_onNodesMoved);
  }

  void _onNodesMoved(TreeNodeMovedEvent<Artifact> event) {
    for (final node in event.nodes) {
      final success = ref
          .read(artifactsProvider.notifier)
          .updateParent(node.data.id, newParentId: node.parent?.data.id ?? '');
      if (success && node.parent != null)
        treeController.expandNode(node.parent!);
    }
  }

  void _selectItem(Artifact item) {
    treeController.setSelectedNodeId(item.id);
    context.go(item.navigationUrl(ref.read(selectedVaultProvider)?.id));
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
    final async = ref.watch(artifactsProvider);
    final itemNodes = async.value ?? const <Artifact>[];

    // Detect tree changes and schedule a controller sync after this frame
    final newRoots = populateTree(itemNodes);
    if (_isTreeChanged(_roots, newRoots)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTree(newRoots));
    }

    // Push URL → tree: when the selected artifact changes from anywhere
    // (direct URL paste, browser back/forward, rename redirect), keep the
    // tree highlight in sync.
    ref.listen<Artifact?>(selectedArtifactProvider, (_, next) {
      if (next != null) {
        final ids = treeController.selectedNodeIds;
        if (ids.length == 1 && ids.first == next.id) return;
        treeController.deselectAll();
        treeController.setSelectedNodeId(next.id);
      } else if (treeController.selectedNodeIds.isNotEmpty) {
        treeController.deselectAll();
      }
    });

    if (async.hasError)
      return Center(
        child: Text('Error loading items. Please refresh the page.'),
      );

    if (!async.hasValue) return Center(child: OnyxiaLoadingIndicator());

    if (itemNodes.isEmpty) return const SizedBox.shrink();

    // TODO: it's also possible to deselect all nodes through the tree widget but that won't deselect the currently-selected artifact. Wiring this requires an on-selection-change callback in vendored super_tree, which CLAUDE.md keeps out of scope. but a workaround would be that if the user clicks the sidebar background (missing a node) then it deselects; this is the tree's behavior anyway, it's just being mimicked this way cont. but more realistically i probably need to dig into the vendor code and expose several signals to properly sync things up

    // TODO: clicking a selected artifact should deselect it

    // TODO: theme brightness or something is messing up the tree context menu and making it white

    return SuperTreeView<Artifact>(
      controller: treeController,
      expansionSlotSize: 20,
      expansionBuilder: (ctx, node) => node.hasChildren
          ? Padding(
              padding: .fromLTRB(
                node.isExpanded ? 2 : 3,
                0,
                0,
                node.isExpanded ? 4 : 2,
              ),
              child: Icon(
                LucideIcons.chevronRight,
                color: ThemeHelper.neutral900(context),
                size: 16,
              ),
            )
          : const SizedBox.shrink(),
      prefixBuilder: (ctx, node) => node.data.type == .folder
          ? Padding(
              padding: .only(left: 7),
              child: Icon(
                node.isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
                color: ThemeHelper.neutral900(context),
                size: 18,
              ),
            )
          : const SizedBox.shrink(),
      contentBuilder: (context, node, _) => TreeTile(node: node),
      style: TreeViewStyle(
        indentAmount: 16.0,
        padding: .symmetric(vertical: 0),
        hoverColor: ThemeHelper.neutral200(context),
        selectedColor: ThemeHelper.neutral200(context),
      ),
      logic: TreeViewConfig(
        enableDragAndDrop: true,
        selectionMode: .multiple,
        expansionTrigger: .tap,
        onNodeTap: (id) => _onNodeTapped(id),
        onNodeDoubleTap: (id) => _onNodeDoubleTapped(id),
        dragAndDrop: TreeDragAndDropConfig(
          canAcceptDrop: (draggedNode, targetNode, position) {
            if (position != .inside) return false;
            if (targetNode.data.type != .folder) return false;
            if (targetNode.id == draggedNode.id) return false;
            return true;
          },
          canAcceptDropMany: (draggedNodes, targetNode, position) {
            if (position != .inside) return false;
            if (targetNode.data.type != .folder) return false;
            if (draggedNodes.map((e) => e.data.id).contains(targetNode.id)) {
              return false;
            }
            return true;
          },
        ),
      ),
      contextMenuBuilder: (ctx, node) =>
          _buildContextMenuItems(artifactsContextMenuOptions().options, node),
    );
  }

  void _onNodeTapped(String id) {
    if (widget.onClickNode != null) {
      final item = ref.read(artifactsProvider.notifier).getItemById(id);
      if (item != null) widget.onClickNode!.call(item);
      return;
    }

    final hasModifier =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isShiftPressed;
    if (hasModifier) return;

    final item = ref.read(artifactsProvider.notifier).getItemById(id);
    // don't select folders, just let the tree open them
    if (item == null || item.type == .folder) return;
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
    List<TreeNode<Artifact>> oldRoots,
    List<TreeNode<Artifact>> newRoots,
  ) {
    if (oldRoots.length != newRoots.length) return true;
    for (int i = 0; i < oldRoots.length; i++) {
      if (oldRoots[i].data.name != newRoots[i].data.name) return true;
      if (_isTreeChanged(
        oldRoots[i].children.toList(),
        newRoots[i].children.toList(),
      ))
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
    List<TreeNode<Artifact>> roots,
    Map<String, bool> state,
  ) {
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
        items.add(
          ContextMenuItem(
            child: const Divider(height: 1, thickness: 1),
            onTap: () {},
          ),
        );
      }
      items.add(
        ContextMenuItem(
          child: Text(opt.label),
          onTap: () {
            opt.callback(ref, node, selectedIds);
            if (opt.clearSelectionAfter) treeController.deselectAll();
          },
        ),
      );
    }
    return items;
  }
}

List<TreeNode<Artifact>> populateTree(List<Artifact> items) {
  final Map<String, List<Artifact>> childrenMap = {};
  for (final item in items.where((i) => i.parentFolderId.isNotEmpty)) {
    childrenMap.putIfAbsent(item.parentFolderId, () => []).add(item);
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

  final rootItems = items.where((i) => i.parentFolderId.isEmpty).toList();
  return rootItems.map(buildNode).toList();
}
