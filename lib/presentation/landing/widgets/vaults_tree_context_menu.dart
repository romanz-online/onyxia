import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/rename_vault_dialog.dart';

List<OnyxiaMenuItem> buildVaultContextMenuItems(
  BuildContext context,
  Vault vault,
) {
  return [
    OnyxiaMenuItem(
      icon: LucideIcons.externalLink,
      child: Text(
        'Open in New Tab',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () => UrlHelper.openInNewTab(UrlHelper.vaultGraphPath(vault.id)),
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.link,
      child: Text(
        'Copy Link',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () =>
          UrlHelper.copyLinkToClipboard(UrlHelper.vaultGraphPath(vault.id)),
    ),
    const OnyxiaMenuItem.divider(),
    OnyxiaMenuItem(
      icon: LucideIcons.pencil,
      child: Text(
        'Rename Vault',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) =>
              RenameVaultDialog(vaultName: vault.name, vaultId: vault.id),
        );
      },
    ),
    OnyxiaMenuItem(
      icon: LucideIcons.trash2,
      child: Text(
        'Delete Vault',
        style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
      ),
      onTap: () => _confirmRemove(context, vault),
    ),
  ];
}

void _confirmRemove(BuildContext context, Vault vault) async {
  String vaultName = vault.name;
  if (vaultName.length > 25) vaultName = '${vaultName.substring(0, 25)}... ';

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => OnyxiaDialog(
      width: 600,
      height: 200,
      title: 'Delete $vaultName?',
      content: Expanded(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              'This is permanent.',
              style: TextStyle(fontSize: 20, color: ThemeHelper.foreground1()),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: .end,
              children: [
                OnyxiaButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                const Gap(20),
                OnyxiaButton(
                  label: 'Delete Vault',
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirm == true) VaultsRepository().delete(vault.id);
}
