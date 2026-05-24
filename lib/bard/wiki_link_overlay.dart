import 'package:flutter/material.dart';
import 'package:onyxia/presentation/common_widget/narwhal_text_style.dart';

// TODO: there's an exception that pops up with this widget

// TODO: this widget's visibility behavior isn't correct. it should not be popping up when the user passively moves their selection over an existing link

// TODO: not here but clicking a link when not selecting any of its text (so the brackets are hidden) should actually direct the user to the linked item

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
      borderRadius: BorderRadius.circular(6),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200, minWidth: 200, maxWidth: 320),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filteredTargets.length,
          itemBuilder: (context, index) {
            final target = filteredTargets[index];
            final isSelected = index == selectedIndex;

            return InkWell(
              onTap: () => onSelected(target),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                child: Text(
                  target,
                  style: NarwhalTextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
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
