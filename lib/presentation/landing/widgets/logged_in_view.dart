import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/import_vault_dialog.dart';
import 'package:onyxia/presentation/landing/widgets/new_vault_dialog.dart';
import 'package:onyxia/presentation/landing/widgets/vault_row.dart';
import 'dart:async';

class LoggedInView extends StatelessWidget {
  static const double leftColumnWidth = 180;

  const LoggedInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: leftColumnWidth, child: const _VaultListColumn()),
        VerticalDivider(width: 2, color: ThemeHelper.auxiliary()),
        Expanded(child: const _RightColumn()),
      ],
    );
  }
}

class _VaultListColumn extends ConsumerStatefulWidget {
  const _VaultListColumn();

  @override
  ConsumerState<_VaultListColumn> createState() => _VaultListColumnState();
}

class _VaultListColumnState extends ConsumerState<_VaultListColumn> {
  @override
  Widget build(BuildContext context) {
    final vaultsAsync = ref.watch(vaultsProvider);
    final vaults = vaultsAsync.isLoading
        ? const <Vault>[]
        : vaultsAsync.value ?? const <Vault>[];
    // TODO: needs to scroll vertically on overflow
    return Container(
      color: ThemeHelper.background2(),
      padding: .fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 6,
        children: [
          for (final vault in vaults)
            Padding(
              padding: .only(bottom: 6),
              child: VaultRow(vault: vault),
            ),
          if (vaults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No vaults',
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeHelper.foreground2(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RightColumn extends ConsumerStatefulWidget {
  const _RightColumn();

  @override
  ConsumerState<_RightColumn> createState() => _RightColumnState();
}

class _RightColumnState extends ConsumerState<_RightColumn> {
  void _showNewVaultDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const NewVaultDialog());
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
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: OnyxiaLoadingIndicator()),
      error: (e, _) => Center(
        child: Text(
          'An unexpected error occurred while logging in.',
          style: TextStyle(color: ThemeHelper.error()),
        ),
      ),
      data: (user) => Padding(
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
      ),
    );
  }
}
