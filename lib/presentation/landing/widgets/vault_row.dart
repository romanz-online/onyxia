import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/vaults_tree_context_menu.dart';

// TODO: make widget bigger and different background color

// TODO: three-dot menu isn't visually responsive

class VaultRow extends ConsumerWidget {
  final Vault vault;
  final VoidCallback onOpen;
  final VoidCallback onOpenInNewTab;

  const VaultRow({
    super.key,
    required this.vault,
    required this.onOpen,
    required this.onOpenInNewTab,
  });

  void _showMenu(BuildContext context, WidgetRef ref, Offset position) {
    ContextMenuOverlay.show(
      context: context,
      position: position,
      items: buildVaultContextMenuItems(context, ref, vault),
    );
  }

  bool _isCtrlOrCmdPressed() {
    return HardwareKeyboard.instance.logicalKeysPressed.intersection({
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    }).isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        _showMenu(context, ref, details.globalPosition);
      },
      child: HoverBuilder(
        builder: (context, isHovered) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isHovered
                  ? ThemeHelper.neutral200(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_isCtrlOrCmdPressed()) {
                        onOpenInNewTab();
                      } else {
                        onOpen();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(1.5, 4, 1.5, 6),
                      child: Text(
                        vault.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NarwhalTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.neutral700(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (buttonContext) => OnyxiaIconButton(
                    icon: LucideIcons.ellipsisVertical,
                    size: 20,
                    onPressed: () {
                      final renderBox =
                          buttonContext.findRenderObject() as RenderBox?;
                      final position = renderBox != null
                          ? renderBox
                              .localToGlobal(Offset(0, renderBox.size.height))
                          : Offset.zero;
                      _showMenu(context, ref, position);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
