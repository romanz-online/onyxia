import 'package:onyxia/export.dart';

List<OnyxiaMenuItem> buildArtifactContextMenuItems(
  WidgetRef ref,
  TreeNode<Artifact> node,
  Set<String> selectedIds,
) {
  return [
    OnyxiaMenuItem(
      icon: LucideIcons.externalLink,
      child: Text(
        'Open in New Tab',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () => UrlHelper.openInNewTab(
        Routes.artifactUrl(
          vaultId: ref.read(selectedVaultProvider)?.id,
          name: node.data.name,
        ),
      ),
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.link,
      child: Text(
        'Copy Link',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () => UrlHelper.copyLinkToClipboard(
        UrlHelper.artifactPath(
          vaultId: ref.read(selectedVaultProvider)?.id,
          name: node.data.name,
        ),
      ),
    ),
    const OnyxiaMenuItem.divider(),
    OnyxiaMenuItem(
      icon: LucideIcons.pencil,
      child: Text(
        'Rename Item',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () =>
          ref.read(renameArtifactIdProvider.notifier).set(node.data.id),
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.trash2,
      child: Text(
        'Remove Item',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () {
        if (selectedIds.contains(node.data.id)) {
          for (final id in selectedIds) {
            ref.read(artifactsProvider.notifier).deleteItem(id);
          }
        } else {
          ref.read(artifactsProvider.notifier).deleteItem(node.data.id);
        }
      },
    ),
  ];
}
