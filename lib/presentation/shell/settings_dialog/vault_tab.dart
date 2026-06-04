import 'package:onyxia/export.dart';

/// Vault-specific settings: rename, export, and delete. Rename and delete are
/// restricted to vault owners; export is available to any member.
class VaultTab extends ConsumerStatefulWidget {
  const VaultTab({super.key});

  @override
  ConsumerState<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends ConsumerState<VaultTab> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(selectedVaultProvider)?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save(Vault vault) {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == vault.name) return;
    ref.read(vaultsProvider.notifier).renameVault(vault.id, name);
    OnyxiaToast.show(text: 'Vault renamed');
  }

  Future<void> _confirmDelete(Vault vault) async {
    String displayName = vault.name;
    if (displayName.length > 25) {
      displayName = '${displayName.substring(0, 25)}... ';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => OnyxiaDialog(
        width: 600,
        height: 200,
        title: 'Delete $displayName?',
        content: Expanded(
          child: Padding(
            padding: .all(20),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'This is permanent.',
                  style: TextStyle(
                    fontSize: 20,
                    color: ThemeHelper.foreground1(),
                  ),
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
      ),
    );

    if (confirm != true) return;
    await VaultsRepository().delete(vault.id);
    if (!mounted) return;
    // Close the settings dialog and leave the now-deleted vault.
    Navigator.of(context).pop();
    navigatorKey.currentContext?.go(Routes.home);
  }

  void _export() {
    // TODO: produce a .zip of .md and image files — the inverse of PortingService.importFiles. Stubbed for now.
    OnyxiaToast.show(text: 'Export coming soon');
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(selectedVaultProvider);
    if (vault == null) return const SizedBox.shrink();
    final isOwner = ref.watch(currentUserRoleProvider) == .owner;

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Vault name
        Text(
          'Vault Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: .w600,
            color: ThemeHelper.foreground1(),
          ),
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: .center,
          spacing: 8,
          children: [
            Expanded(
              child: OnyxiaTextFormField(
                controller: _nameController,
                maxLength: 50,
                enabled: isOwner,
                hintText: vault.name,
                onSubmitted: (_) => _save(vault),
              ),
            ),
            if (isOwner)
              OnyxiaButton(label: 'Save', onPressed: () => _save(vault)),
          ],
        ),
        const Gap(20),
        Divider(height: 1, color: ThemeHelper.auxiliary()),
        const Gap(20),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            OnyxiaButton(
              label: 'Export Vault',
              leftIcon: LucideIcons.download400,
              onPressed: _export,
            ),
            if (isOwner)
              OnyxiaButton(
                label: 'Delete Vault',
                leftIcon: LucideIcons.trash2,
                onPressed: () => _confirmDelete(vault),
                isDangerous: true,
              ),
          ],
        ),
      ],
    );
  }
}
