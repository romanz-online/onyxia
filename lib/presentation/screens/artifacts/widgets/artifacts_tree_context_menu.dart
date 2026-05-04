import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/screens/artifacts/provider/rename_artifact_id_provider.dart';

typedef TreeContextMenuCallback = void Function(
  BuildContext context,
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

ArtifactsTreeContextMenuOptions artifactsContextMenuOptions() {
  return ArtifactsTreeContextMenuOptions(
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
        callback: (context, ref, node, selectedIds) => _handleRemove(context, ref, selectedIds),
      ),
      TreeContextMenuOption(
        label: 'Rename',
        index: 3,
        callback: _handleRename,
      ),
    ],
  );
}

void _handleOpenInNewTab(BuildContext context, WidgetRef ref, TreeNode<Artifact> node, Set<String> _) {
  final projectId = ref.read(projectsProvider).selectedProject.id;
  final url = NavigationUrlBuilder.buildArtifactUrl(projectId, node.data.id);
  NavigationContextMenu.openInNewTab(url);
}

void _handleCopyLink(BuildContext context, WidgetRef ref, TreeNode<Artifact> node, Set<String> _) {
  final projectId = ref.read(projectsProvider).selectedProject.id;
  final url = NavigationUrlBuilder.buildArtifactUrl(projectId, node.data.id);
  NavigationContextMenu.copyLinkToClipboard(url);
}

void _handleRemove(
  BuildContext context,
  WidgetRef ref,
  Set<String> selectedIds,
) async {
  for (final id in selectedIds) {
    ref.read(artifactsProvider.notifier).deleteItem(id, context);
  }
}

void _handleRename(
  BuildContext context,
  WidgetRef ref,
  TreeNode<Artifact> node,
  Set<String> _,
) {
  ref.read(renameArtifactIdProvider.notifier).state = node.data.id;
}
