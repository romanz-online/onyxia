import 'package:onyxia/export.dart';

class VaultSettingsButton extends ConsumerStatefulWidget {
  const VaultSettingsButton({super.key});

  @override
  ConsumerState createState() => _VaultSettingsButtonState();
}

class _VaultSettingsButtonState extends ConsumerState<VaultSettingsButton> {
  bool _isMenuOpen = false;

  void _setMenuOpen(bool open) {
    if (_isMenuOpen == open) return;
    setState(() => _isMenuOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final vaultId = ref.read(selectedVaultProvider)?.id;
    if (vaultId == null) return const SizedBox.shrink();
    // TODO: let this button appear when no vault is selected but adjust the settings to be vault-inspecific

    return OnyxiaIconButton(
      icon: LucideIcons.settings,
      iconColor: ThemeHelper.foreground2(),
      isPressed: _isMenuOpen,
      onPressed: () {
        _setMenuOpen(true);
        showDialog(
          context: context,
          builder: (_) => const SettingsDialog(),
        ).then((_) => _setMenuOpen(false));
      },
    );
  }
}
