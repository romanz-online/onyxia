import 'package:onyxia/export.dart';

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
        children: [
          // TODO: this onyxiabutton should open a menu above it (anchored topleft/bottomleft) that displays "manage vaults" at the bottom and above it other vaults that the user can access, readily available. will need to only show the three most recently-modified vaults to prevent overflow
          OnyxiaOverlay(
            isOpen: _isMenuOpen,
            onClose: () => _setMenuOpen(false),
            anchor: const Aligned(
              follower: .bottomLeft,
              target: .topLeft,
              offset: const Offset(0, -4),
            ),
            builder: (context, closeOverlay) => _buildMenu(closeOverlay),
            child: OnyxiaButton(
              label: vaultName,
              isPressed: _isMenuOpen,
              onPressed: () => _setMenuOpen(!_isMenuOpen),
              leftIcon: selectedVault == null
                  ? null
                  : LucideIcons.chevronsUpDown,
            ),
          ),

          const Spacer(),
          if (selectedVault != null) const VaultSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildMenu(VoidCallback closeOverlay) {
    return OnyxiaMenu(
      width: 150,
      closeOverlay: closeOverlay,
      items: [
        // TODO: replace with a list of other most recently accessed or modified vaults
        OnyxiaMenuItem(
          child: Text(
            'Dummy Vault 1',
            style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
          ),
          onTap: () => {},
        ),
        OnyxiaMenuItem(
          child: Text(
            'Dummy Vault 2',
            style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
          ),
          onTap: () => {},
        ),
        OnyxiaMenuItem.divider(),
        OnyxiaMenuItem(
          icon: LucideIcons.logOut,
          child: Text(
            'Manage Vaults',
            style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
          ),
          onTap: () => context.go(Routes.home),
        ),
      ],
    );
  }
}
