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

    return OnyxiaOverlay(
      isOpen: _isMenuOpen,
      onClose: () => _setMenuOpen(false),
      anchor: const Aligned(
        follower: Alignment.bottomLeft,
        target: Alignment.bottomRight,
        offset: Offset(4, 0),
        backup: Aligned(
          follower: Alignment.bottomRight,
          target: Alignment.topRight,
          offset: Offset(0, -6),
        ),
      ),
      builder: (context, closeOverlay) => _buildMenu(closeOverlay),
      child: OnyxiaIconButton(
        icon: LucideIcons.settings,
        isPressed: _isMenuOpen,
        onPressed: () => _setMenuOpen(!_isMenuOpen),
      ),
    );
  }

  Widget _buildMenu(VoidCallback closeOverlay) {
    return OnyxiaMenu(
      width: 160,
      closeOverlay: closeOverlay,
      items: [
        OnyxiaMenuItem(
          child: Text('Members', style: NarwhalTextStyle()),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const VaultMembersDialog(),
          ),
        ),
      ],
    );
  }
}
