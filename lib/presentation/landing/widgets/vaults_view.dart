import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/import_vault_dialog.dart';
import 'package:onyxia/presentation/landing/widgets/new_vault_dialog.dart';
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
        VerticalDivider(width: 2, color: ThemeHelper.auxiliary()),
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
      color: ThemeHelper.background2(),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeHelper.foreground2(),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: vaults.length,
                    itemBuilder: (context, index) => Padding(
                      padding: .only(bottom: 6),
                      child: VaultRow(vault: vaults[index]),
                    ),
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
    showDialog(context: context, builder: (_) => NewVaultDialog());
  }

  Future<void> _showImportVaultDialog(BuildContext context) async {
    final files = await PortingService.pickFolder();
    if (files.isEmpty || !context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => ImportVaultDialog(
        files: files,
        onComplete: (vault) => context.go(Routes.graphUrl(vault.id)),
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: .bold,
              color: ThemeHelper.foreground1(),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeHelper.foreground2(),
                  ),
                ),
              ),
              OnyxiaButton(
                label: 'Sign out',
                onPressed: ref.read(currentUserProvider.notifier).signOut,
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
                    onPressed: () => _showNewVaultDialog(context),
                  ),
                  OnyxiaButton(
                    label: 'Import Vault',
                    onPressed: () => _showImportVaultDialog(context),
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
