import 'package:onyxia/export.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class ArtifactsTreeView extends ConsumerStatefulWidget {
  const ArtifactsTreeView({super.key});

  @override
  ArtifactsTreeViewState createState() => ArtifactsTreeViewState();
}

class ArtifactsTreeViewState extends ConsumerState<ArtifactsTreeView> {
  List<TreeNode<Artifact>> _roots = [];
  late TreeController<Artifact> treeController;
  StreamSubscription<TreeNodeMovedEvent<Artifact>>? _moveSubscription;
  StreamSubscription<TreeSelectionChangedEvent<Artifact>>?
  _selectionSubscription;

  // Cursor-anchored context menu state. The stack key lets us convert the
  // global click position from super_tree's callback into a local offset for
  // the `Positioned` trigger.
  final GlobalKey _stackKey = GlobalKey();
  Offset _menuLocalPosition = Offset.zero;
  TreeNode<Artifact>? _menuNode;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<Artifact>(roots: _roots);
    _subscribeToMoveEvents();
    _subscribeToSelectionEvents();
  }

  @override
  void dispose() {
    _moveSubscription?.cancel();
    _selectionSubscription?.cancel();
    treeController.dispose();
    super.dispose();
  }

  void _subscribeToMoveEvents() {
    _moveSubscription?.cancel();
    _moveSubscription = treeController.addNodeMovedListener(_onNodesMoved);
  }

  void _subscribeToSelectionEvents() {
    _selectionSubscription?.cancel();
    _selectionSubscription = treeController.addSelectionChangedListener(
      _onSelectionChanged,
    );
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

  String _getNodeTooltip(Artifact artifact) {
    String ret = '';
    if (artifact.updatedAt != null) {
      final formatted = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(artifact.updatedAt!);
      ret += 'Last modified at $formatted\n';
    }

    if (artifact.createdAt != null) {
      final formatted = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(artifact.createdAt!);
      ret += 'Created at $formatted';
    }

    return ret;
  }

  /// Single source of truth: any tree-selection change routes to the URL,
  /// which in turn updates `selectedArtifactProvider`.
  void _onSelectionChanged(TreeSelectionChangedEvent<Artifact> event) {
    final ids = event.selectedNodeIds;
    final vaultId = ref.read(selectedVaultProvider)?.id;
    if (vaultId == null) return;

    if (ids.isEmpty) {
      if (ref.read(selectedArtifactProvider) != null) {
        context.go(Routes.vaultUrl(vaultId));
      }
      return;
    }

    if (ids.length > 1) return;

    final item = ref.read(artifactsProvider.notifier).getItemById(ids.first);
    if (item == null || item.type == .folder) return;

    if (ref.read(selectedArtifactProvider)?.id == item.id) return;
    context.go(Routes.artifactUrl(vaultId: vaultId, name: item.name));
  }

  void _syncTree(List<TreeNode<Artifact>> newRoots) {
    if (!mounted) return;
    _applyExpansionState(newRoots, _getExpansionState(_roots));

    final preserved = treeController.selectedNodeIds
        .where((id) => _findNodeById(newRoots, id) != null)
        .toSet();

    final renamingId = treeController.renamingNodeId;
    final preservedRenamingId =
        renamingId != null && _findNodeById(newRoots, renamingId) != null
        ? renamingId
        : null;

    final oldController = treeController;
    _moveSubscription?.cancel();
    _selectionSubscription?.cancel();
    setState(() {
      _roots = newRoots;
      treeController = TreeController<Artifact>(roots: newRoots);
    });
    oldController.dispose();
    _subscribeToMoveEvents();
    _subscribeToSelectionEvents();

    if (preserved.length == 1) {
      treeController.setSelectedNodeId(preserved.first);
    } else {
      for (final id in preserved) {
        treeController.toggleSelection(id);
      }
    }

    if (preservedRenamingId != null) {
      treeController.setRenamingNodeId(preservedRenamingId);
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
    // tree highlight in sync. `setSelectedNodeId` and `deselectAll` will
    // each emit a selection-change event back, but `_onSelectionChanged`
    // bails when the URL already matches, so the loop terminates.
    ref.listen<Artifact?>(selectedArtifactProvider, (_, next) {
      if (next != null) {
        final ids = treeController.selectedNodeIds;
        if (ids.length == 1 && ids.first == next.id) return;
        treeController.setSelectedNodeId(next.id);
      } else if (treeController.selectedNodeIds.isNotEmpty) {
        treeController.deselectAll();
      }
    });

    if (async.hasError)
      return Center(
        child: Text(
          'Error loading items. Please refresh the page.',
          style: TextStyle(color: ThemeHelper.error()),
        ),
      );

    if (!async.hasValue) return const Center(child: OnyxiaLoadingIndicator());

    if (itemNodes.isEmpty) return const SizedBox.shrink();

    return Stack(
      key: _stackKey,
      children: [
        SuperTreeView<Artifact>(
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
                    color: ThemeHelper.foreground1(),
                    size: 16,
                  ),
                )
              : const SizedBox.shrink(),
          prefixBuilder: (ctx, node) => node.data.type == .folder
              ? Padding(
                  padding: .only(left: 7),
                  child: Icon(
                    node.isExpanded
                        ? LucideIcons.folderOpen
                        : LucideIcons.folder,
                    color: ThemeHelper.foreground1(),
                    size: 16,
                  ),
                )
              : const SizedBox.shrink(),
          contentBuilder: (context, node, renameField) =>
              TreeTile(node: node, controller: treeController),
          // TODO: track hoveredNode or hoveredNodeId or something. wrap this in MouseRegion and expose the state variable. send it into TreeTile so that the hovered tile can lighten its text
          contentWrapper: (context, node, child) => OnyxiaTooltip(
            message: _getNodeTooltip(node.data),
            direction: .right,
            tooltipOffset: const Offset(24, 0),
            waitDuration: const Duration(milliseconds: 1000),
            child: child,
          ),
          style: TreeViewStyle(
            indentAmount: 16,
            padding: .fromLTRB(8, 0, 16, 0),
            hoverColor: ThemeHelper.background2(),
            selectedColor: ThemeHelper.background2(),
          ),
          padding: .symmetric(vertical: 8),
          logic: TreeViewConfig(
            enableDragAndDrop: true,
            selectionMode: .multiple,
            expansionTrigger: .tap,
            onNodeTap: (id) => _onNodeTapped(id),
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
                if (draggedNodes
                    .map((e) => e.data.id)
                    .contains(targetNode.id)) {
                  return false;
                }
                return true;
              },
            ),
          ),
          onNodeContextMenuRequested: _openContextMenu,
        ),

        if (_menuNode != null)
          Positioned(
            left: _menuLocalPosition.dx,
            top: _menuLocalPosition.dy,
            child: OnyxiaOverlay(
              isOpen: _isMenuOpen,
              anchor: const Aligned(
                follower: .topLeft,
                target: .topLeft,
                offset: .zero,
                backup: Aligned(
                  follower: .bottomRight,
                  target: .topLeft,
                  offset: .zero,
                ),
              ),
              onClose: _closeContextMenu,
              builder: (ctx, close) => OnyxiaMenu(
                width: 170,
                items: buildArtifactContextMenuItems(
                  ref,
                  _menuNode!,
                  treeController.selectedNodeIds,
                  treeController,
                ),
                closeOverlay: close,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  void _openContextMenu(
    BuildContext ctx,
    Offset globalPosition,
    TreeNode<Artifact> node,
  ) {
    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _menuLocalPosition = renderBox.globalToLocal(globalPosition);
      _menuNode = node;
      _isMenuOpen = true;
    });
    treeController.setContextMenuNodeId(node.id);
  }

  void _closeContextMenu() {
    setState(() {
      _isMenuOpen = false;
      _menuNode = null;
    });
    treeController.setContextMenuNodeId(null);
  }

  /// Super_tree's internal tap handler already calls `setSelectedNodeId(id)`,
  /// which fires the selection-change event that drives navigation. This
  /// handler only covers the deselect-on-re-tap case super_tree doesn't
  /// provide: tapping the already-selected artifact deselects it. With no
  /// modifiers, re-tap on the same node leaves the controller's selection
  /// set unchanged, so no event fires — call `deselectAll()` to trigger one.
  void _onNodeTapped(String id) {
    final hasModifier =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isShiftPressed;
    if (hasModifier) return;

    if (ref.read(selectedArtifactProvider)?.id == id) {
      treeController.deselectAll();
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
