import 'package:onyxia/export.dart';
import 'dart:math' as math;

class ArtifactsSidebarFooter extends ConsumerStatefulWidget {
  const ArtifactsSidebarFooter({super.key});

  @override
  ConsumerState createState() => _ArtifactsSidebarFooterState();
}

class _ArtifactsSidebarFooterState
    extends ConsumerState<ArtifactsSidebarFooter> {
  bool _isMenuOpen = false;

  void _setMenuOpen(bool open) {
    if (_isMenuOpen == open) return;
    setState(() => _isMenuOpen = open);
  }

  // TODO: check the results from this method after sorting out the artifact ops/snapshot/body.content mess
  List<Vault> getMostRelevantVaults(
    List<Vault> vaults,
    Vault? currentVault,
    String currentUserId, {
    int count = 3,
  }) {
    final now = DateTime.now();

    double recencyScore(DateTime? dt, {double halfLifeDays = 7}) {
      if (dt == null) return 0;
      final ageDays = now.difference(dt).inDays.toDouble();
      // Exponential decay: score halves every `halfLifeDays`
      return math.exp(-ageDays * math.log(2) / halfLifeDays);
    }

    double score(Vault vault) {
      double s = 0.0;

      // Strongest signal: user recently modified it
      if (vault.updatedBy == currentUserId) {
        s += 1.0 * recencyScore(vault.updatedAt);
      }

      // Medium signal: user created it
      if (vault.createdBy == currentUserId) {
        s += 0.5 * recencyScore(vault.createdAt);
      }

      return s;
    }

    final scored =
        vaults
            .where((v) => v != currentVault)
            .map((v) => (vault: v, score: score(v)))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    // Only return vaults with some signal — avoid showing random vaults
    // if the user has no history yet
    return scored
        .where((e) => e.score > 0)
        .take(count)
        .map((e) => e.vault)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVault = ref.watch(selectedVaultProvider);
    final vaultName = selectedVault == null || selectedVault.name.isEmpty
        ? 'Onyxia'
        : selectedVault.name;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeHelper.auxiliary(), width: 1),
        ),
      ),
      padding: .symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Flexible(
            child: OnyxiaOverlay(
              isOpen: _isMenuOpen,
              onClose: () => _setMenuOpen(false),
              anchor: const Aligned(
                follower: .bottomLeft,
                target: .topLeft,
                offset: const Offset(0, -4),
              ),
              builder: (context, closeOverlay) =>
                  _buildMenu(closeOverlay, selectedVault),
              child: OnyxiaButton(
                label: vaultName,
                isPressed: _isMenuOpen,
                onPressed: selectedVault == null
                    ? null
                    : () => _setMenuOpen(!_isMenuOpen),
                leftIcon: selectedVault == null
                    ? null
                    : LucideIcons.chevronsUpDown,
              ),
            ),
          ),

          const VaultSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildMenu(VoidCallback closeOverlay, Vault? currentVault) {
    final vaultsAsync = ref.watch(vaultsProvider);
    final vaults = vaultsAsync.isLoading || currentVault == null
        ? const <Vault>[]
        : vaultsAsync.value ?? const <Vault>[];

    final relevantVaults = getMostRelevantVaults(
      vaults,
      currentVault,
      ref.read(currentUserProvider).value?.id ?? '',
      count: 2,
    );

    return OnyxiaMenu(
      width: 150,
      closeOverlay: closeOverlay,
      items: [
        for (final vault in relevantVaults)
          OnyxiaMenuItem(
            child: Row(
              spacing: 8,
              children: [
                const SizedBox(width: 14), // takes up the usual icon space
                // Expanded mimics OnyxiaMenuItem's interior design
                Expanded(
                  child: Text(
                    vault.name,
                    style: TextStyle(
                      color: ThemeHelper.foreground1(),
                      fontSize: 13,
                      overflow: .ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => context.go(Routes.vaultUrl(vault.id)),
          ),
        OnyxiaMenuItem(
          icon: LucideIcons.check600,
          child: Text(
            currentVault?.name ?? '???',
            style: TextStyle(
              color: ThemeHelper.foreground1(),
              fontSize: 13,
              overflow: .ellipsis,
            ),
          ),
          onTap: () => {},
        ),
        OnyxiaMenuItem.divider(),

        OnyxiaMenuItem(
          icon: LucideIcons.logOut600,
          child: Text(
            'Manage Vaults',
            style: TextStyle(
              color: ThemeHelper.foreground1(),
              fontSize: 13,
              overflow: .ellipsis,
            ),
          ),
          onTap: () => context.go(Routes.home),
        ),
      ],
    );
  }
}
