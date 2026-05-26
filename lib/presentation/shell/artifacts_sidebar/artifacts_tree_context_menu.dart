import 'package:onyxia/export.dart';

typedef TreeContextMenuCallback =
    void Function(
      WidgetRef ref,
      TreeNode<Artifact> node,
      Set<String> selectedIds,
    );

class TreeContextMenuOption {
  final String label;
  final int index;
  final TreeContextMenuCallback callback;
  final bool dividerBefore;
  final bool clearSelectionAfter;

  const TreeContextMenuOption({
    required this.label,
    required this.index,
    required this.callback,
    this.dividerBefore = false,
    this.clearSelectionAfter = false,
  });
}

class ArtifactsTreeContextMenuOptions {
  final List<TreeContextMenuOption> options;

  const ArtifactsTreeContextMenuOptions({required this.options});
}

ArtifactsTreeContextMenuOptions artifactsContextMenuOptions() =>
    ArtifactsTreeContextMenuOptions(
      options: [
        TreeContextMenuOption(
          label: 'Open in New Tab',
          index: 0,
          callback: _handleOpenInNewTab,
        ),
        TreeContextMenuOption(
          label: 'Copy Link',
          index: 1,
          callback: _handleCopyLink,
        ),
        TreeContextMenuOption(
          label: 'Remove',
          index: 2,
          callback: _handleRemove,
        ),
        TreeContextMenuOption(
          label: 'Rename',
          index: 3,
          callback: _handleRename,
        ),
      ],
    );

void _handleOpenInNewTab(
  WidgetRef ref,
  TreeNode<Artifact> node,
  Set<String> _,
) => NavigationContextMenu.openInNewTab(
  node.data.navigationUrl(ref.read(selectedVaultProvider)?.id),
);

void _handleCopyLink(WidgetRef ref, TreeNode<Artifact> node, Set<String> _) =>
    NavigationContextMenu.copyLinkToClipboard(
      node.data.navigationUrl(ref.read(selectedVaultProvider)?.id),
    );

void _handleRemove(
  WidgetRef ref,
  TreeNode<Artifact> node,
  Set<String> selectedIds,
) async {
  if (selectedIds.contains(node.data.id)) {
    for (final id in selectedIds) {
      ref.read(artifactsProvider.notifier).deleteItem(id);
    }
  } else {
    ref.read(artifactsProvider.notifier).deleteItem(node.data.id);
  }
}

void _handleRename(WidgetRef ref, TreeNode<Artifact> node, Set<String> _) {
  ref.read(renameArtifactIdProvider.notifier).set(node.data.id);
}
