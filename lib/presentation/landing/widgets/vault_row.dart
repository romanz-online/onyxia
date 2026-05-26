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

  @override
  Widget build(BuildContext context) {
    final vault = widget.vault;

    return OnyxiaOverlay(
      isOpen: _cursorOffset != null,
      onClose: _closeCursorMenu,
      anchor: Aligned(
        follower: .topLeft,
        target: .topLeft,
        offset: _cursorOffset ?? .zero,
      ),
      builder: (context, closeOverlay) => OnyxiaMenu(
        items: buildVaultContextMenuItems(context, vault),
        closeOverlay: closeOverlay,
      ),
      child: GestureDetector(
        behavior: .opaque,
        onSecondaryTapDown: (details) => _openCursorMenu(details.localPosition),
        child: HoverBuilder(
          builder: (context, isHovered) {
            return Container(
              padding: .symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHovered
                    ? ThemeHelper.neutral300(context).withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: .circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: .opaque,
                      onTap: () => context.go('/vault/${vault.id}/graph'),
                      child: Padding(
                        padding: .fromLTRB(1.5, 6, 1.5, 8),
                        child: Text(
                          vault.name,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: NarwhalTextStyle(
                            fontSize: 13,
                            fontWeight: .w600,
                            color: ThemeHelper.neutral900(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  OnyxiaOverlay(
                    isOpen: _isButtonMenuOpen,
                    onClose: _closeButtonMenu,
                    anchor: const Aligned(
                      follower: .topLeft,
                      target: .topRight,
                      offset: const Offset(4, 0),
                    ),
                    builder: (context, closeOverlay) => OnyxiaMenu(
                      items: buildVaultContextMenuItems(context, vault),
                      closeOverlay: closeOverlay,
                    ),
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
