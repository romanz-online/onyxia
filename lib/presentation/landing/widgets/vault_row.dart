import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/vaults_tree_context_menu.dart';

class VaultRow extends ConsumerStatefulWidget {
  final Vault vault;

  const VaultRow({super.key, required this.vault});

  @override
  ConsumerState<VaultRow> createState() => _VaultRowState();
}

class _VaultRowState extends ConsumerState<VaultRow> {
  Offset? _cursorOffset;
  bool _isButtonMenuOpen = false;

  void _openCursorMenu(Offset localPosition) {
    setState(() {
      _isButtonMenuOpen = false;
      _cursorOffset = localPosition;
    });
  }

  void _toggleButtonMenu() {
    setState(() {
      _cursorOffset = null;
      _isButtonMenuOpen = !_isButtonMenuOpen;
    });
  }

  void _closeCursorMenu() {
    if (_cursorOffset == null) return;
    setState(() => _cursorOffset = null);
  }

  void _closeButtonMenu() {
    if (!_isButtonMenuOpen) return;
    setState(() => _isButtonMenuOpen = false);
  }

  Widget buildOnyxiaMenu(BuildContext context, void Function() closeOverlay) =>
      OnyxiaMenu(
        width: 170,
        items: buildVaultContextMenuItems(context, widget.vault),
        closeOverlay: closeOverlay,
      );

  @override
  Widget build(BuildContext context) {
    return OnyxiaOverlay(
      isOpen: _cursorOffset != null,
      onClose: _closeCursorMenu,
      anchor: Aligned(
        follower: .topLeft,
        target: .topLeft,
        offset: _cursorOffset ?? .zero,
      ),
      builder: buildOnyxiaMenu,
      child: GestureDetector(
        behavior: .opaque,
        onSecondaryTapDown: (details) => _openCursorMenu(details.localPosition),
        child: HoverBuilder(
          builder: (context, isHovered) {
            return Container(
              padding: .symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHovered
                    ? ThemeHelper.auxiliary().withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: .circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: .opaque,
                      onTap: () => context.go(Routes.vaultUrl(widget.vault.id)),
                      child: Padding(
                        padding: .symmetric(horizontal: 1.5, vertical: 7),
                        child: Text(
                          widget.vault.name,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: .w600,
                            color: ThemeHelper.foreground1(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // TODO: need a way to check if the current user is an owner in each vault and tailor the context menu options here accordingly. they shouldn't be able to rename or delete vaults that don't belong to them.
                  OnyxiaOverlay(
                    isOpen: _isButtonMenuOpen,
                    onClose: _closeButtonMenu,
                    anchor: const Aligned(
                      follower: .topLeft,
                      target: .topRight,
                      offset: const Offset(4, 0),
                    ),
                    builder: buildOnyxiaMenu,
                    child: OnyxiaIconButton(
                      icon: LucideIcons.ellipsisVertical,
                      size: 24,
                      isPressed: _isButtonMenuOpen,
                      onPressed: _toggleButtonMenu,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
