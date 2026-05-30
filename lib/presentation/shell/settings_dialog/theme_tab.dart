import 'package:onyxia/export.dart';

class ThemeTab extends ConsumerStatefulWidget {
  const ThemeTab({super.key});

  @override
  ConsumerState<ThemeTab> createState() => _ThemeTabState();
}

class _ThemeTabState extends ConsumerState<ThemeTab> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    return ListView(
      shrinkWrap: true,
      children: ThemeVariant.values
          .map(
            (e) =>
                Column(children: [_buildItem(e, currentTheme), const Gap(8)]),
          )
          .toList(),
    );
  }

  Widget _buildItem(ThemeVariant theme, ThemeVariant currentTheme) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return GestureDetector(
          onTap: () => ref.read(themeProvider.notifier).set(theme),

          child: Container(
            width: .infinity,
            alignment: .centerLeft,
            padding: .symmetric(vertical: 7.5, horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: .all(.circular(4)),
              color: isHovered ? ThemeHelper.background2() : Colors.transparent,
            ),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  theme == currentTheme
                      ? LucideIcons.squareCheck
                      : LucideIcons.square,
                  size: 18,
                  color: ThemeHelper.foreground1(),
                ),
                Expanded(
                  child: Text(
                    theme.label,
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeHelper.foreground1(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
