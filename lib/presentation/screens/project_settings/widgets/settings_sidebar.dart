import 'package:onyxia/export.dart';

class SettingsSidebar extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabSelected;
  final String projectName; 

  const SettingsSidebar({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.projectName, 
  });

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required int index,
    bool disabled = false,
  }) {
    final isSelected = selectedTabIndex == index;

    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled ? null : () => onTabSelected(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.transparent
                    : (isSelected || isHovered)
                        ? ThemeHelper.neutral200(context)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: NarwhalTextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: disabled
                      ? ThemeHelper.neutral400(context)
                      : isSelected
                          ? ThemeHelper.black(context)
                          : ThemeHelper.neutral600(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral300(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabButton(
              context: context,
              label: 'Project Name',
              index: 0,
            ),
            _buildTabButton(
              context: context,
              label: 'Team',
              index: 1,
            ),
            _buildTabButton(
              context: context,
              label: 'Notifications',
              index: 2,
              disabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
