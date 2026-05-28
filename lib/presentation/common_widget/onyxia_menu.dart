import 'package:onyxia/export.dart';

class OnyxiaMenuItem {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final bool isDivider;

  const OnyxiaMenuItem({
    this.icon,
    required Widget this.child,
    required VoidCallback this.onTap,
  }) : isDivider = false;

  const OnyxiaMenuItem.divider()
    : icon = null,
      child = null,
      onTap = null,
      isDivider = true;
}

class OnyxiaMenu extends StatelessWidget {
  final List<OnyxiaMenuItem> items;
  final VoidCallback closeOverlay;
  final double width;

  const OnyxiaMenu({
    super.key,
    required this.items,
    required this.closeOverlay,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: .circular(6.0),
      color: ThemeHelper.background1(),
      clipBehavior: .antiAlias,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: .circular(6.0),
          border: .all(color: ThemeHelper.auxiliary().withAlpha(25)),
        ),
        child: ListView(
          padding: .symmetric(vertical: 4.0),
          shrinkWrap: true,
          children: items.map((item) => _buildItem(context, item)).toList(),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, OnyxiaMenuItem item) {
    if (item.isDivider) {
      return Padding(
        padding: .symmetric(vertical: 4, horizontal: 4),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: ThemeHelper.foreground1(),
        ),
      );
    }

    return InkWell(
      mouseCursor: SystemMouseCursors.basic,
      onTap: () {
        closeOverlay();
        item.onTap!();
      },
      child: Container(
        width: .infinity,
        alignment: .centerLeft,
        padding: .symmetric(vertical: 7.5, horizontal: 16.0),
        child: Row(
          spacing: 8,
          children: [
            if (item.icon != null)
              Icon(item.icon, size: 14, color: ThemeHelper.foreground1()),
            Expanded(child: item.child!),
          ],
        ),
      ),
    );
  }
}
