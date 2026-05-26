import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/import_vault_dialog.dart';
import 'package:onyxia/presentation/landing/widgets/vault_row.dart';
import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.neutral200(context),
      padding: .fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: .start,
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
                    itemBuilder: (context, index) =>
                        VaultRow(vault: vaults[index]),
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

  void _showNewVaultDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (_) => _NewVaultDialog(),
    );
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
      padding: .symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Onyxia',
            style: NarwhalTextStyle(
              fontSize: 32,
              fontWeight: .bold,
              color: ThemeHelper.neutral700(context),
            ),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              Padding(
                padding: .only(left: 4),
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
            mainAxisAlignment: .end,
            children: [
              Column(
                spacing: 6,
                crossAxisAlignment: .end,
                children: [
                  OnyxiaButton(
                    label: 'New Vault',
                    onTap: () => _showNewVaultDialog(context),
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

class _NewVaultDialog extends ConsumerStatefulWidget {
  const _NewVaultDialog();

  @override
  ConsumerState<_NewVaultDialog> createState() => _NewVaultDialogState();
}

class _NewVaultDialogState extends ConsumerState<_NewVaultDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // TODO: when redesigning NarwhalModalDialog, use it here and add a loading state here while the async methods run
  void _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final newVault = Vault(name: name);
    await VaultsRepository().add([newVault]).then((_) async {
      await _waitForVaultInProvider(newVault.id).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
          navigatorKey.currentContext?.go('/vault/${newVault.id}/graph');
        }
      });
    });
  }

  Future<void> _waitForVaultInProvider(String id) {
    final completer = Completer<void>();
    late ProviderSubscription sub;
    sub = ref.listenManual<AsyncValue<List<Vault>>>(vaultsProvider, (_, next) {
      if ((next.value?.any((v) => v.id == id) ?? false) &&
          !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .whenComplete(sub.close);
  }

  @override
  Widget build(BuildContext context) {
    return NarwhalModalDialog(
      width: 600,
      height: 260,
      title: 'New Vault',
      content: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .start,
        spacing: 10,
        children: [
          Text(
            'Vault Name',
            style: NarwhalStyles.modalTextFieldTitleStyle(context),
          ),
          TextFormField(
            maxLength: 50,
            controller: _nameController,
            autofocus: true,
            decoration: NarwhalModalInputDecoration.create(
              context,
              hintText: 'Enter vault name',
            ),
            style: NarwhalTextStyle(),
          ),
        ],
      ),
      onCancelPressed: Navigator.of(context).pop,
      actionButtonText: 'Create',
      onActionPressed: _create,
    );
  }
}
