import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/common_widget/hoverable_dropdown_item.dart';

/// A dropdown multi-selection widget that uses NarwhalOverlay for its dropdown options
/// and has a similar style to the canvas right-click menu.
/// currently String-only, and NOT a Dropdown for filtering a generic type T
class NarwhalDropdownMultiSelect extends StatefulWidget {
  final List<String> allItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final double? width;
  final double? height;
  final String? searchHint;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hoverColor;
  final Color? hoverBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final double? elevation;
  final bool isExpanded;
  final bool isDense;

  const NarwhalDropdownMultiSelect({
    super.key,
    required this.allItems,
    required this.selectedItems,
    required this.onChanged,
    required this.label,
    this.width,
    this.height,
    this.searchHint,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.hoverColor,
    this.hoverBorderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.elevation,
    this.isExpanded = true,
    this.isDense = true,
  });

  @override
  State<NarwhalDropdownMultiSelect> createState() => _NarwhalDropdownMultiSelectState();
}

class _NarwhalDropdownMultiSelectState extends State<NarwhalDropdownMultiSelect> {
  bool _isOpen = false;
  final GlobalKey _triggerKey = GlobalKey();

  late List<String> selected;
  late List<String> filtered;
  String search = '';
  late final TextEditingController _searchController;
  late final List<Widget> dropdownMenuItems;

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.selectedItems);
//    _searchController = TextEditingController(text: '');
//    _searchController.addListener(() {
//      debugPrint('searchController Listener handling change with setState(), current value of search string is $search');
//      setState(() {
//        search = _searchController.text;
//        filtered = widget.allItems.where((t) => !selected.contains(t) &&
//                            t.toLowerCase().contains(search.toLowerCase())).toList();
//                            // for various reasons, the rebuild of the entire shown Dropdown doesn't happen until a click on the TextField
//                            // triggers a rebuild of the entire thing.
//                            // setState() doesn't do that rebuild, so the shown list of items is not repopulated
//      });
//    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? ThemeHelper.neutral100(context);
    final borderColor = widget.borderColor ?? ThemeHelper.neutral400(context);
    final hoverColor = widget.hoverColor ?? ThemeHelper.blue().withValues(alpha: 0.1);
    final hoverBorderColor = widget.hoverBorderColor ?? ThemeHelper.blue();

    final labelText = selected.isNotEmpty ? '${widget.label}: ${selected.join(', ')}' : widget.label;
    filtered =
        widget.allItems.where((t) => !selected.contains(t) && t.toLowerCase().contains(search.toLowerCase())).toList();

    return NarwhalOverlay(
      isOpen: _isOpen,
      onClose: () => setState(() => _isOpen = false),
      customOffset: _getTriggerPosition(),
      customSize: _getTriggerSize(),
      builder: (context, closeOverlay) => _buildDropdownMenu(closeOverlay),
      child: HoverBuilder(
        builder: (context, isHovered) {
          return GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              key: _triggerKey,
              width: widget.width,
              height: widget.height ?? 40,
              decoration: BoxDecoration(
                color: isHovered ? hoverColor : backgroundColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(6.0),
                border: Border.all(
                  color: isHovered ? hoverBorderColor : borderColor,
                  width: 1,
                ),
              ),
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    labelText,
                    style: const NarwhalTextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  widget.icon ??
                      NarwhalIcon(
                        NarwhalIcons.dropdownArrow,
                        color: ThemeHelper.neutral500(context),
                        size: 16,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  Widget _buildDropdownMenu(VoidCallback closeOverlay) {
    final triggerPosition = _getTriggerPosition();
    final triggerSize = _getTriggerSize();
    final dropdownMenuItems = filtered.map((item) => _buildDropdownItem(item, closeOverlay)).toList();

    if (triggerPosition == null || triggerSize == null) return const SizedBox.shrink();

    return Positioned(
      top: triggerPosition.dy + triggerSize.height - 1, // Subtract 1 to overlap the border
      left: triggerPosition.dx,
      child: Material(
        elevation: widget.elevation ?? 8,
        color: ThemeHelper.neutral600(context),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: widget.width ?? triggerSize.width,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(
              color: ThemeHelper.blue(), // Match the hover border color
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Selected items as Chips
            if (selected.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected
                    .map((item) => Chip(
                          label: Text(
                            item,
                            style: NarwhalTextStyle(fontSize: 12, color: ThemeHelper.neutral700(context)),
                          ),
                          backgroundColor: ThemeHelper.blue400(context).withValues(alpha: 0.5),
                          deleteIcon: const NarwhalIcon(NarwhalIcons.close, size: 14),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          labelPadding: EdgeInsets.zero,
                          onDeleted: () {
                            selected.remove(item);
                            widget.onChanged(selected);
                            setState(() => _isOpen = false);
                          },
                        ))
                    .toList(),
              ),
//              if (selected.isNotEmpty) const SizedBox(height: 8),
//              const Divider(),
            // Search Field
//              TextField(
//                decoration: InputDecoration(
//                  hintText: widget.searchHint,
//                  hintStyle: const NarwhalTextStyle(fontSize: 12),
//                  prefixIcon: const Icon(Icons.search, size: 16),
//                  suffixIcon: search.isNotEmpty
//                    ? IconButton(
//                      icon: const Icon(Icons.clear, size: 14),
//                      padding: EdgeInsets.zero,
//                      constraints: const BoxConstraints(),
//                      onPressed: () {
//                        _searchController.clear();
//                        setState(() => _isOpen = true);
//                      },
//                    ) : null,
//                  isDense: true,
//                  border: OutlineInputBorder(
//                  borderRadius: BorderRadius.circular(4),
//                  borderSide: BorderSide(
//                    color: ThemeHelper.neutral400(context)),
//                  ),
//                  focusedBorder: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(4),
//                    borderSide: BorderSide(
//                      color: ThemeHelper.neutral400(context)),
//                    ),
//                  enabledBorder: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(4),
//                    borderSide: BorderSide(
//                      color: ThemeHelper.neutral400(context)),
//                  ),
//                  filled: true,
//                  fillColor:
//                    ThemeHelper.neutral100(context),
//                  contentPadding: const EdgeInsets.symmetric(
//                    vertical: 0, horizontal: 8.0),
//                ),
//                style: const NarwhalTextStyle(fontSize: 12),
//                controller: _searchController,
//                onChanged: (value) {
//  debugPrint('search text changed to $search, about to call setState()');
//                  setState(() => _isOpen = true);
//                },
//              ),
//              const SizedBox(height: 8),
            const Divider(),
            Visibility(
              visible: search.isNotEmpty && filtered.isEmpty,
              child: Text('No ${widget.label.toLowerCase()} found'),
            ),
            SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: dropdownMenuItems,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String item, VoidCallback closeOverlay) {
    debugPrint('building dropdown item for $item');
    return InkWell(
      onTap: () {
        selected.add(item);
        widget.onChanged(selected);
        closeOverlay();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        //decoration: BoxDecoration(
        //  color: isHovered
        //    ? NarwhalColors.highlight.withValues(alpha: 0.2)
        //    : Colors.transparent,
        //),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
              style: NarwhalTextStyle(
                color: ThemeHelper.neutral700(context),
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              child: DropdownMenuItem<String>(
                value: item,
                child: HoverableDropdownItem(
                  text: item,
                  textStyle: NarwhalTextStyle(fontSize: 12),
                ),
              )),
        ),
      ),
    );
  }
}
