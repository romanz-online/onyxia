import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/vaults_tree_context_menu.dart';

// TODO: make widget bigger and different background color

// TODO: three-dot menu isn't visually responsive

class VaultRow extends ConsumerWidget {
  final Vault vault;

  const VaultRow({super.key, required this.vault});

  void _showMenu(BuildContext context, Offset position) {
    ContextMenuOverlay.show(
      context: context,
      position: position,
      items: buildVaultContextMenuItems(context, vault),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          _showMenu(context, details.globalPosition),
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
                    onTap: () => context.go('/vault/${vault.id}/graph'),
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
                  // TODO: this should use flutter_portal, not supertree's context menu. menu's topLeft should align with button's topRight

                  // TODO: build flutter_portal into OnyxiaButton. specifically: copy the format that vaultsettingsbutton already establishes with onyxiaoverlay (which uses flutter_portal) and then also homogenize vaultsettingsbutton to use the new layout

                  // TODO: add flutter_portal usage to CLAUDE.md so that claude uses flutter_portal instead of doing this builder/renderbox stuff
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
                      _showMenu(context, position);
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
