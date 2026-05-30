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
          OnyxiaOverlay(
            isOpen: _isMenuOpen,
            onClose: () => _setMenuOpen(false),
            anchor: const Aligned(
              follower: .bottomLeft,
              target: .topLeft,
              offset: const Offset(0, -4),
            ),
            builder: (context, closeOverlay) =>
                _buildMenu(closeOverlay, vaultName),
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

  Widget _buildMenu(VoidCallback closeOverlay, String currentVaultName) {
    return OnyxiaMenu(
      width: 150,
      closeOverlay: closeOverlay,
      items: [
        // TODO: replace with a list of other most recently accessed or modified vaults
        OnyxiaMenuItem(
          child: Row(
            spacing: 8,
            children: [
              const SizedBox(width: 14), // takes up the usual icon space
              Text(
                'Dummy Vault 1',
                style: TextStyle(
                  color: ThemeHelper.foreground1(),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          onTap: () => {},
        ),
        OnyxiaMenuItem(
          icon: LucideIcons.check600,
          child: Text(
            currentVaultName,
            style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 13),
          ),
          onTap: () => {},
        ),
        OnyxiaMenuItem.divider(),
        OnyxiaMenuItem(
          icon: LucideIcons.logOut600,
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
