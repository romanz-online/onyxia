import 'package:onyxia/export.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

// TODO: turn vault members into a separate widget

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return OnyxiaDialog(
      title: 'Settings',
      width: 480,
      height: 480,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return const SizedBox.expand();
  }
}
