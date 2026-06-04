import 'package:onyxia/export.dart';
import 'vault_members_tab.dart';
import 'vault_tab.dart';
import 'theme_tab.dart';

enum _SettingsTab with OnyxiaEnum {
  theme('Theme', isGlobal: true),
  members('Members', isGlobal: false),
  vault('Vault', isGlobal: false);

  final String label;

  /// Global tabs (e.g. Theme) apply app-wide; the rest are vault-specific and
  /// only shown when a vault is selected. They're visually separated in the
  /// tab list, with global tabs on top.
  final bool isGlobal;

  const _SettingsTab(this.label, {required this.isGlobal});
}

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  _SettingsTab _selected = .theme;

  @override
  Widget build(BuildContext context) {
    final hasVault = ref.watch(selectedVaultProvider) != null;
    // Global tabs always show; vault-specific tabs only when a vault is
    // selected. Globals come first so they sit above the divider.
    final List<_SettingsTab> tabs = [
      .theme,
      if (hasVault) ...[.members, .vault],
    ];
    // The previously selected tab may no longer be visible (e.g. the vault
    // was deselected) — fall back to the first available tab.
    final selected = tabs.contains(_selected) ? _selected : tabs.first;

    return OnyxiaDialog(
      width: 640,
      height: 480,
      content: Expanded(child: _buildContent(tabs, selected)),
    );
  }

  Widget _buildContent(List<_SettingsTab> tabs, _SettingsTab selected) {
    return Row(
      crossAxisAlignment: .stretch,
      children: [
        // Tabs
        SizedBox(width: 120, child: _buildTabs(tabs, selected)),
        VerticalDivider(thickness: 1, color: ThemeHelper.auxiliary()),
        // Tab content
        Expanded(
          child: Padding(
            padding: .all(12),
            child: switch (selected) {
              .theme => const ThemeTab(),
              .members => const VaultMembersTab(),
              .vault => const VaultTab(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(List<_SettingsTab> tabs, _SettingsTab selected) {
    final globalTabs = tabs.where((t) => t.isGlobal);
    final vaultTabs = tabs.where((t) => !t.isGlobal);

    return Container(
      padding: .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          for (final tab in globalTabs) _tabButton(tab, selected),
          // Separate global tabs (above) from vault-specific tabs (below).
          if (globalTabs.isNotEmpty && vaultTabs.isNotEmpty)
            Divider(height: 1, color: ThemeHelper.auxiliary()),
          for (final tab in vaultTabs) _tabButton(tab, selected),
        ],
      ),
    );
  }

  Widget _tabButton(_SettingsTab tab, _SettingsTab selected) {
    return OnyxiaButton(
      label: tab.label,
      isPressed: tab == selected,
      onPressed: () => setState(() => _selected = tab),
    );
  }
}
