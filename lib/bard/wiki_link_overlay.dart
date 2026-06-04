import 'package:onyxia/export.dart';

// TODO: this widget's visibility behavior isn't correct. it should not be popping up when the user passively moves their selection over an existing link

// TODO: not here but clicking a link when not selecting any of its text (so the brackets are hidden) should actually direct the user to the linked item

// TODO: not here but clicking a link's brackets shouldn't redirect. only clicking the span's content, not its markers, should redirect

class WikiLinkOverlay extends StatelessWidget {
  const WikiLinkOverlay({
    super.key,
    required this.query,
    required this.filteredTargets,
    required this.selectedIndex,
    required this.onSelected,
    required this.onDismiss,
  });

  final String query;
  final List<String> filteredTargets;
  final int selectedIndex;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (filteredTargets.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: .circular(6),
      color: ThemeHelper.background2(),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 200,
          minWidth: 200,
          maxWidth: 320,
        ),
        decoration: BoxDecoration(
          border: .all(color: ThemeHelper.auxiliary()),
          borderRadius: .circular(6),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: .symmetric(vertical: 4),
          itemCount: filteredTargets.length,
          itemBuilder: (context, index) {
            final target = filteredTargets[index];
            final isSelected = index == selectedIndex;

            return InkWell(
              onTap: () => onSelected(target),
              child: Container(
                padding: .symmetric(horizontal: 12, vertical: 8),
                color: isSelected
                    ? ThemeHelper.accent().withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Text(
                  target,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? .w600 : .w400,
                    color: isSelected
                        ? ThemeHelper.accent()
                        : ThemeHelper.foreground1(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
