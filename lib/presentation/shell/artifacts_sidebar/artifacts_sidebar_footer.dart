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
          top: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          OnyxiaButton(
            label: vaultName,
            onTap: () => context.go(Routes.home),
          ),
          const Spacer(),
          if (selectedVault != null) const VaultSettingsButton(),
        ],
      ),
    );
  }
}
