import 'package:onyxia/export.dart';

/// A unified filter selector widget that uses plain text for single selection.
/// This widget provides a simple dropdown with text-based selection,
/// similar to NarwhalCheckboxFilterSelect but for single-select scenarios without search.
class NarwhalTextFilterSelect extends StatefulWidget {
  final List<String> availableItems;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;
  final String label;
  final double width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hoverColor;
  final Color? hoverBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final double? elevation;
  final double? maxDropdownHeight;
  final bool showHighlightWhenSelected;
  final bool showBackgroundWhenSelected;

  const NarwhalTextFilterSelect({
    super.key,
    required this.availableItems,
    required this.selectedItem,
    required this.onChanged,
    required this.label,
    this.width = 200,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.hoverColor,
    this.hoverBorderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.elevation,
    this.maxDropdownHeight = 300.0,
    this.showHighlightWhenSelected = false,
    this.showBackgroundWhenSelected = true,
  });

  @override
  State<NarwhalTextFilterSelect> createState() => _NarwhalTextFilterSelectState();
}

class _NarwhalTextFilterSelectState extends State<NarwhalTextFilterSelect> {
  bool _isOpen = false;
  final GlobalKey _triggerKey = GlobalKey();

  Offset? _getTriggerPosition() {
    final RenderBox? renderBox = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return renderBox.localToGlobal(Offset.zero);
  }

  Size? _getTriggerSize() {
    final RenderBox? renderBox = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return renderBox.size;
  }

  void _selectItem(String item, StateSetter overlaySetState) {
    if (!mounted) return;

    widget.onChanged(item);
    setState(() => _isOpen = false);
  }

  Widget _buildDropdownMenu() {
    final triggerPosition = _getTriggerPosition();
    final triggerSize = _getTriggerSize();

    if (triggerPosition == null || triggerSize == null) return const SizedBox.shrink();

    // Calculate available screen space below the trigger
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - (triggerPosition.dy + triggerSize.height + 4);

    // Estimate item height (ListTile with dense: true is approximately 48-52px)
    const estimatedItemHeight = 50.0;
    final estimatedTotalHeight = widget.availableItems.length * estimatedItemHeight;

    // Determine if we need scrolling and calculate max height
    final needsScrolling = estimatedTotalHeight > spaceBelow - 20; // Leave 20px margin
    final maxHeight = needsScrolling ? spaceBelow - 20 : double.infinity;

    return Positioned(
      top: triggerPosition.dy + triggerSize.height + 4,
      left: triggerPosition.dx,
      child: Material(
        elevation: widget.elevation ?? 8,
        borderRadius: BorderRadius.circular(6),
        child: StatefulBuilder(
          builder: (context, overlaySetState) {
            return Container(
              width: triggerSize.width < 200 ? 200 : triggerSize.width,
              decoration: BoxDecoration(
                color: ThemeHelper.neutral100(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ThemeHelper.neutral400(context)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Items list
                    widget.availableItems.isEmpty
                        ? SizedBox(
                            height: 49.0,
                            child: Center(
                              child: Text(
                                'No ${widget.label.toLowerCase()} found',
                                style: NarwhalTextStyle(),
                              ),
                            ),
                          )
                        : needsScrolling
                            ? ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: maxHeight,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: widget.availableItems.length,
                                  itemBuilder: (context, index) {
                                    final item = widget.availableItems[index];
                                    final isSelected = widget.selectedItem == item;
                                    final isLastItem = index == widget.availableItems.length - 1;

                                    return Column(
                                      children: [
                                        HoverBuilder(
                                          builder: (context, isHovered) {
                                            return Container(
                                              color: isHovered
                                                  ? ThemeHelper.neutral300(context)
                                                  : (isSelected
                                                      ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
                                                      : Colors.transparent),
                                              child: ListTile(
                                                title: Text(
                                                  item,
                                                  style: NarwhalStyles.dropdownListTextStyle(context),
                                                ),
                                                onTap: () {
                                                  _selectItem(item, overlaySetState);
                                                },
                                                dense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                              ),
                                            );
                                          },
                                        ),
                                        if (!isLastItem) const Divider(height: 1, indent: 0, endIndent: 0),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.availableItems.length,
                                itemBuilder: (context, index) {
                                  final item = widget.availableItems[index];
                                  final isSelected = widget.selectedItem == item;
                                  final isLastItem = index == widget.availableItems.length - 1;

                                  return Column(
                                    children: [
                                      HoverBuilder(
                                        builder: (context, isHovered) {
                                          return Container(
                                            color: isHovered
                                                ? ThemeHelper.neutral300(context)
                                                : (isSelected
                                                    ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
                                                    : Colors.transparent),
                                            child: ListTile(
                                              title: Text(
                                                item,
                                                style: NarwhalStyles.dropdownListTextStyle(context),
                                              ),
                                              onTap: () {
                                                _selectItem(item, overlaySetState);
                                              },
                                              dense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                            ),
                                          );
                                        },
                                      ),
                                      if (!isLastItem) const Divider(height: 1, indent: 0, endIndent: 0),
                                    ],
                                  );
                                },
                              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? ThemeHelper.neutral100(context);
    final borderColor = widget.borderColor ?? ThemeHelper.neutral400(context);
    final hoverBorderColor = widget.hoverBorderColor ?? ThemeHelper.neutral600(context).withValues(alpha: 0.5);

    return NarwhalOverlay(
      isOpen: _isOpen,
      onClose: () => setState(() => _isOpen = false),
      customOffset: _getTriggerPosition(),
      customSize: _getTriggerSize(),
      builder: (context, closeOverlay) {
        return _buildDropdownMenu();
      },
      child: HoverBuilder(
        builder: (context, isHovered) {
          final hasSelectedItem = widget.selectedItem != null &&
              widget.selectedItem != widget.label &&
              !widget.selectedItem!.contains('Any ') &&
              !widget.selectedItem!.contains('All ');
          return GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              key: _triggerKey,
              height: widget.height ?? 30,
              width: widget.width,
              decoration: BoxDecoration(
                border: Border.all(color: isHovered ? hoverBorderColor : borderColor),
                color: (widget.showBackgroundWhenSelected && hasSelectedItem)
                    ? ThemeHelper.blue100(context)
                    : backgroundColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedItem ?? widget.label,
                      style: (widget.selectedItem != null &&
                              widget.selectedItem != widget.label &&
                              !widget.selectedItem!.contains('Any ') &&
                              !widget.selectedItem!.contains('All '))
                          ? (widget.textStyle ?? NarwhalStyles.dropdownListTextStyle(context)).copyWith(
                              color: ThemeHelper.neutral800(context),
                            )
                          : (widget.textStyle ?? NarwhalStyles.dropdownListTextStyle(context)).copyWith(
                              color: ThemeHelper.neutral500(context),
                            ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NarwhalIcon(
                    _isOpen ? NarwhalIcons.dropdownArrowUp : NarwhalIcons.dropdownArrow,
                    size: 18,
                    color: ThemeHelper.neutral800(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
