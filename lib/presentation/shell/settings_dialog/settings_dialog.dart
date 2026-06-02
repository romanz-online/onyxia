import 'package:onyxia/export.dart';
import 'vault_members_tab.dart';
import 'theme_tab.dart';

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
  _SettingsTab _selected = _SettingsTab.members;

  @override
  Widget build(BuildContext context) {
    return OnyxiaDialog(
      width: 640,
      height: 480,
      content: Expanded(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: .stretch,
      children: [
        // Tabs
        SizedBox(width: 120, child: _buildTabs()),
        VerticalDivider(thickness: 1, color: ThemeHelper.auxiliary()),
        // Tab content
        Expanded(
          child: Padding(
            padding: .all(12),
            child: switch (_selected) {
              .members => const VaultMembersTab(),
              .theme => const ThemeTab(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: .all(12),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          for (final tab in _SettingsTab.values)
            OnyxiaButton(
              label: tab.label,
              isPressed: tab == _selected,
              onPressed: () => setState(() => _selected = tab),
            ),
        ],
      ),
    );
  }
}
