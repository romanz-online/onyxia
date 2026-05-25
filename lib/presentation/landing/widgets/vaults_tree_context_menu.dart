import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/rename_vault_dialog.dart';

// TODO: fix dimensions/overflow issue

// TODO: icons are dark and need to be light

// TODO: for some reason deletes might happen eventually but it's extremely unresponsive

// TODO: give all options an icon to keep it uniform

List<ContextMenuItem> buildVaultContextMenuItems(
  BuildContext context,
  WidgetRef ref,
  Vault vault,
) {
  final items = <ContextMenuItem>[];

  items.add(ContextMenuItem(
    child: Row(
      spacing: 8,
      children: [
        const Icon(LucideIcons.externalLink, size: 14),
        Text('Open in New Tab', style: NarwhalTextStyle()),
      ],
    ),
    onTap: () {
      final url = NavigationUrlBuilder.buildGraphUrl(vault.id);
      NavigationContextMenu.openInNewTab(url);
    },
  ));

  items.add(ContextMenuItem(
    child: Row(
      spacing: 8,
      children: [
        const Icon(LucideIcons.link, size: 14),
        Text('Copy Link', style: NarwhalTextStyle()),
      ],
    ),
    onTap: () {
      final url = NavigationUrlBuilder.buildGraphUrl(vault.id);
      NavigationContextMenu.copyLinkToClipboard(url);
    },
  ));

  items.add(ContextMenuItem(
    child: Divider(
      height: 1,
      thickness: 1,
      color: ThemeHelper.neutral400(context),
    ),
    onTap: () {},
  ));

  items.add(ContextMenuItem(
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
  ));

  items.add(ContextMenuItem(
    child: Text('Delete Vault', style: NarwhalTextStyle()),
    onTap: () => _confirmRemove(context, ref, vault),
  ));

  return items;
}

void _confirmRemove(BuildContext context, WidgetRef ref, Vault vault) async {
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
