import 'package:onyxia/export.dart';

class OnyxiaCheckboxMenuItem {
  final String label;
  final bool checked;
  final VoidCallback onToggle;

  const OnyxiaCheckboxMenuItem({
    required this.label,
    required this.checked,
    required this.onToggle,
  });
}

class OnyxiaCheckboxMenu extends StatelessWidget {
  final List<OnyxiaCheckboxMenuItem> items;
  final double width;

  const OnyxiaCheckboxMenu({super.key, required this.items, this.width = 180});

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
          children: items.map(_buildItem).toList(),
        ),
      ),
    );
  }

  Widget _buildItem(OnyxiaCheckboxMenuItem item) {
    return InkWell(
      mouseCursor: SystemMouseCursors.basic,
      onTap: item.onToggle,
      hoverColor: ThemeHelper.background2(),
      child: Container(
        width: .infinity,
        alignment: .centerLeft,
        padding: .symmetric(vertical: 7.5, horizontal: 16.0),
        child: Row(
          spacing: 8,
          children: [
            Icon(
              item.checked ? LucideIcons.squareCheck : LucideIcons.square,
              size: 14,
              color: ThemeHelper.foreground1(),
            ),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeHelper.foreground1(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
