import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/rename_vault_dialog.dart';

List<OnyxiaMenuItem> buildVaultContextMenuItems(
  BuildContext context,
  Vault vault,
) {
  return [
    OnyxiaMenuItem(
      icon: LucideIcons.externalLink,
      child: Text('Open in New Tab', style: NarwhalTextStyle()),
      onTap: () => NavigationContextMenu.openInNewTab(
        NavigationUrlBuilder.buildGraphUrl(vault.id),
      ),
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.link,
      child: Text('Copy Link', style: NarwhalTextStyle()),
      onTap: () => NavigationContextMenu.copyLinkToClipboard(
        NavigationUrlBuilder.buildGraphUrl(vault.id),
      ),
    ),
    const OnyxiaMenuItem.divider(),
    OnyxiaMenuItem(
      icon: LucideIcons.pencil,
      child: Text('Rename Vault', style: NarwhalTextStyle()),
      onTap: () {
        showDialog(
          context: context,
          barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
          builder: (_) => RenameVaultDialog(
            vaultName: vault.name,
            vaultId: vault.id,
          ),
        );
      },
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.trash2,
      child: Text('Delete Vault', style: NarwhalTextStyle()),
      onTap: () => _confirmRemove(context, vault),
    ),
  ];
}

void _confirmRemove(BuildContext context, Vault vault) async {
  String vaultName = vault.name;
  if (vaultName.length > 25) vaultName = '${vaultName.substring(0, 25)}... ';

  final confirm = await showDialog<bool>(
    context: context,
    barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
    builder: (_) => NarwhalModalDialog(
      width: 600,
      height: 200,
      title: 'Delete $vaultName?',
      hasLargeTitle: true,
      content: Text(
        'This is permanent.',
        style: NarwhalTextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      onCancelPressed: () => Navigator.of(context).pop(false),
      actionButtonText: 'Delete Vault',
      onActionPressed: () => Navigator.of(context).pop(true),
    ),
  );

  if (confirm == true) {
    VaultsRepository().delete(vault.id);
  }
}
