import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/import_vault_dialog.dart';
import 'package:onyxia/presentation/landing/widgets/vault_row.dart';

class VaultsView extends ConsumerWidget {
  static const double leftColumnWidth = 180;

  const VaultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value ?? User.initial();
    final vaults = ref.watch(vaultsProvider).value ?? const <Vault>[];

    return Row(
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: _VaultListColumn(vaults: vaults),
        ),
        VerticalDivider(width: 2, color: ThemeHelper.neutral300(context)),
        Expanded(child: _RightColumn(user: user)),
      ],
    );
  }
}

class _VaultListColumn extends StatelessWidget {
  final List<Vault> vaults;

  const _VaultListColumn({required this.vaults});

  void _open(BuildContext context, Vault vault) {
    context.go('/vault/${vault.id}/graph');
  }

  void _openInNewTab(Vault vault) {
    NavigationContextMenu.openInNewTab(
      NavigationUrlBuilder.buildGraphUrl(vault.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Expanded(
            child: vaults.isEmpty
                ? Center(
                    child: Text(
                      'No vaults',
                      style: NarwhalTextStyle(
                        fontSize: 13,
                        color: ThemeHelper.neutral500(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: vaults.length,
                    itemBuilder: (context, index) {
                      final vault = vaults[index];
                      return VaultRow(
                        vault: vault,
                        onOpen: () => _open(context, vault),
                        onOpenInNewTab: () => _openInNewTab(vault),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RightColumn extends ConsumerWidget {
  final User user;

  const _RightColumn({required this.user});

  Future<void> _showNewVaultDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (dialogContext) {
        return NarwhalModalDialog(
          width: 600,
          height: 260,
          title: 'New Vault',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                'Vault Name',
                style: NarwhalStyles.modalTextFieldTitleStyle(dialogContext),
              ),
              TextFormField(
                maxLength: 50,
                controller: controller,
                autofocus: true,
                decoration: NarwhalModalInputDecoration.create(
                  dialogContext,
                  hintText: 'Enter vault name',
                ),
                style: NarwhalTextStyle(),
              ),
            ],
          ),
          onCancelPressed: () => Navigator.of(dialogContext).pop(),
          actionButtonText: 'Create',
          onActionPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            final currentUserId =
                ref.read(currentUserProvider).value?.id ?? '';
            final now = DateTime.now();
            final newVault = Vault(
              id: const Uuid().v4(),
              createdBy: currentUserId,
              createdAt: now,
              updatedAt: now,
              name: name,
            );
            VaultsRepository().add([newVault]);
            Navigator.of(dialogContext).pop();
            context.go('/vault/${newVault.id}/graph');
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showImportVaultDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final files = await PortingService.pickFolder();
    if (files.isEmpty || !context.mounted) return;

    showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (_) => ImportVaultDialog(
        files: files,
        onComplete: (vault) => context.go('/vault/${vault.id}/graph'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onyxia',
            style: NarwhalTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.neutral700(context),
            ),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'You are logged in as ${user.email}',
                  style: NarwhalTextStyle(
                    fontSize: 13,
                    color: ThemeHelper.neutral500(context),
                  ),
                ),
              ),
              OnyxiaButton(
                label: 'Sign out',
                onTap: ref.read(currentUserProvider.notifier).signOut,
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OnyxiaButton(
                    label: 'New Vault',
                    onTap: () => _showNewVaultDialog(context, ref),
                  ),
                  OnyxiaButton(
                    label: 'Import Vault',
                    onTap: () => _showImportVaultDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
