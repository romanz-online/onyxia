import 'package:onyxia/export.dart';

/// A unified filter selector widget that uses checkboxes for multi-selection.
/// This widget combines the functionality of NarwhalFilterSelect and TagCheckboxSelector
/// to provide a consistent checkbox-based filtering interface.
class NarwhalCheckboxFilterSelect<T> extends StatefulWidget {
  final List<T> availableItems;
  final List<T> selectedItems;
  final String Function(T) labelOf;
  final ValueChanged<List<T>> onChanged;
  final String label;
  final String searchHint;
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
  final bool showSelectedChips;
  final double? maxDropdownHeight;

  const NarwhalCheckboxFilterSelect({
    super.key,
    required this.availableItems,
    required this.selectedItems,
    required this.labelOf,
    required this.onChanged,
    required this.label,
    required this.searchHint,
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
    this.showSelectedChips = true,
    this.maxDropdownHeight = 300.0,
  });

  @override
  State<NarwhalCheckboxFilterSelect<T>> createState() => _NarwhalCheckboxFilterSelectState<T>();
}

class _NarwhalCheckboxFilterSelectState<T> extends State<NarwhalCheckboxFilterSelect<T>> {
  bool _isOpen = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _triggerKey = GlobalKey();
  late List<T> _localSelectedItems;
  StateSetter? _overlaySetState;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List<T>.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(NarwhalCheckboxFilterSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localSelectedItems = List<T>.from(widget.selectedItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<T> get filteredItems {
    if (_searchText.isEmpty) {
      return widget.availableItems;
    }
    return widget.availableItems
        .where((item) => widget.labelOf(item).toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  void _toggleItem(T item, StateSetter overlaySetState) {
    if (!mounted) return;

    if (_localSelectedItems.contains(item)) {
      _localSelectedItems.remove(item);
    } else {
      _localSelectedItems.add(item);
    }
    widget.onChanged(_localSelectedItems);

    if (mounted) {
      overlaySetState(() {});
    }
  }

  Widget _buildDropdownMenu() {
    final triggerPosition = _getTriggerPosition();
    final triggerSize = _getTriggerSize();

    if (triggerPosition == null || triggerSize == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: triggerPosition.dy + triggerSize.height + 4,
      left: triggerPosition.dx,
      child: Material(
        elevation: widget.elevation ?? 8,
        borderRadius: BorderRadius.circular(8),
        child: StatefulBuilder(
          builder: (context, overlaySetState) {
            _overlaySetState = overlaySetState;
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
                    // Selected items as chips (optional)
                    if (widget.showSelectedChips && _localSelectedItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Wrap(
                          spacing: 4.0,
                          runSpacing: 4.0,
                          children: _localSelectedItems.reversed.map((item) {
                            return HoverBuilder(
                              builder: (context, isHovered) {
                                return InputChip(
                                  label: Text(
                                    widget.labelOf(item),
                                    style: NarwhalTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeHelper.blue800(context),
                                    ),
                                  ),
                                  color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) =>
                                      states.contains(WidgetState.hovered)
                                          ? ThemeHelper.blue200(context)
                                          : ThemeHelper.neutral100(context)),
                                  deleteIcon: isHovered ? const Icon(Icons.close_outlined, size: 12) : null,
                                  onDeleted: isHovered
                                      ? () {
                                          _localSelectedItems.remove(item);
                                          widget.onChanged(_localSelectedItems);
                                          overlaySetState(() {});
                                        }
                                      : null,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  side: BorderSide(
                                    color: ThemeHelper.neutral500(context).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    if (widget.showSelectedChips && _localSelectedItems.isNotEmpty) const SizedBox(height: 8),
                    // Search field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          hintStyle: NarwhalStyles.modalTextFieldInputHintStyle(context),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(11.0),
                            child: const NarwhalIcon(NarwhalIcons.search, size: 10),
                          ),
                          suffixIcon: _searchText.isNotEmpty
                              ? IconButton(
                                  icon: const NarwhalIcon(NarwhalIcons.close, size: 14),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _searchController.clear();
                                    overlaySetState(() {
                                      _searchText = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: ThemeHelper.blue500(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
                          ),
                          filled: true,
                          fillColor: ThemeHelper.neutral100(context),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          overlaySetState(() {
                            _searchText = value;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Items list with checkboxes
                    filteredItems.isEmpty
                        ? SizedBox(height: 49.0, child: Center(child: Text('No ${widget.label.toLowerCase()} found')))
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: widget.maxDropdownHeight!,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = _localSelectedItems.contains(item);
                                final isLastItem = index == filteredItems.length - 1;

                                return Column(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        checkboxTheme: CheckboxThemeData(
                                          side: WidgetStateBorderSide.resolveWith(
                                            (states) => BorderSide(
                                              color: ThemeHelper.neutral500(context),
                                              width: 1.5,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          fillColor: WidgetStateProperty.resolveWith((states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.transparent;
                                            }
                                            return Colors.transparent;
                                          }),
                                          checkColor: WidgetStateProperty.all(ThemeHelper.blue700(context)),
                                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                                        ),
                                      ),
                                      child: HoverBuilder(
                                        builder: (context, isHovered) {
                                          return Container(
                                            color: isHovered
                                                ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
                                                : Colors.transparent,
                                            child: CheckboxListTile(
                                              title: Text(
                                                widget.labelOf(item),
                                                style: NarwhalStyles.dropdownListTextStyle(context),
                                              ),
                                              value: isSelected,
                                              onChanged: (value) {
                                                _toggleItem(item, overlaySetState);
                                              },
                                              dense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                                              controlAffinity: ListTileControlAffinity.leading,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (!isLastItem) const Divider(height: 1, indent: 0, endIndent: 0),
                                  ],
                                );
                              },
                            ),
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
    final hoverColor = widget.hoverColor ?? backgroundColor;
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
          final hasSelectedItems = widget.selectedItems.isNotEmpty;
          return GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              key: _triggerKey,
              height: widget.height ?? 30,
              width: widget.width,
              decoration: BoxDecoration(
                border: Border.all(color: isHovered ? hoverBorderColor : borderColor),
                color: isHovered ? hoverColor : (hasSelectedItems ? hoverColor : backgroundColor),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: widget.selectedItems.isNotEmpty
                        ? Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: widget.selectedItems.reversed.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 4.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ThemeHelper.neutral100(context),
                                            borderRadius: BorderRadius.circular(40),
                                            border: Border.all(
                                              color: ThemeHelper.neutral500(context).withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                widget.labelOf(item),
                                                style: NarwhalTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: ThemeHelper.blue800(context),
                                                  height: 1.0,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _localSelectedItems.remove(item);
                                                    widget.onChanged(_localSelectedItems);
                                                  });
                                                  _overlaySetState?.call(() {});
                                                },
                                                child: NarwhalIcon(
                                                  NarwhalIcons.close,
                                                  size: 14,
                                                  color: ThemeHelper.blue800(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.label,
                            style: (widget.textStyle ?? NarwhalStyles.dropdownListTextStyle(context)).copyWith(
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
