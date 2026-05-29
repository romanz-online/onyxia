import 'package:onyxia/export.dart';

class ArtifactsSidebarFooter extends ConsumerWidget {
  const ArtifactsSidebarFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVault = ref.watch(selectedVaultProvider);
    final vaultName = selectedVault == null || selectedVault.name.isEmpty
        ? 'Onyxia'
        : selectedVault.name;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeHelper.auxiliary(), width: 1),
        ),
      ),
      padding: .symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // TODO: this onyxiabutton should open a menu above it (anchored topleft/bottomleft) that displays "manage vaults" at the bottom and above it other vaults that the user can access, readily available. will need to only show the three most recently-modified vaults to prevent overflow
          OnyxiaButton(label: vaultName, onTap: () => context.go(Routes.home)),
          const Spacer(),
          if (selectedVault != null) const VaultSettingsButton(),
        ],
      ),
    );
  }
}
