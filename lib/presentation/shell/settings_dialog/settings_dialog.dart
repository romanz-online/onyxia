import 'package:onyxia/export.dart';
import 'vault_members_tab.dart';
import 'theme_tab.dart';

// TODO: add a "vault" or something tab for vault name, deletion, and export -- just a button that gives you a .zip of .md and image files, just the inverse of import as it currently exists

enum _SettingsTab with OnyxiaEnum {
  members('Members'),
  theme('Theme');

  final String label;
  const _SettingsTab(this.label);
}

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  _SettingsTab _selected = .members;

  @override
  Widget build(BuildContext context) {
    final hasVault = ref.watch(selectedVaultProvider) != null;
    // The Members tab is vault-specific; without a vault only show
    // vault-agnostic tabs.
    final List<_SettingsTab> tabs = [
      if (hasVault) .members,
      .theme,
    ]; // TODO: there should be a divider between global tabs like theme and vault-specific tabs like members/vault. global at the top and the rest below
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
              .members => const VaultMembersTab(),
              .theme => const ThemeTab(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(List<_SettingsTab> tabs, _SettingsTab selected) {
    return Container(
      padding: .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          for (final tab in tabs)
            OnyxiaButton(
              label: tab.label,
              isPressed: tab == selected,
              onPressed: () => setState(() => _selected = tab),
            ),
        ],
      ),
    );
  }
}
