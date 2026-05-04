import 'dart:math';
import 'package:onyxia/presentation/common_widget/hoverable_list_tile.dart';
import 'package:onyxia/export.dart';

/// @ponder ponder/NarwhalFilterSelect.gif
class NarwhalFilterSelect extends StatefulWidget {
  final List<String> allItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
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

  const NarwhalFilterSelect({
    super.key,
    required this.allItems,
    required this.selectedItems,
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
  });

  @override
  State<NarwhalFilterSelect> createState() => _NarwhalFilterSelectState();
}

class _NarwhalFilterSelectState extends State<NarwhalFilterSelect> {
  late List<String> selected;
  String search = '';
  bool _isOpen = false;
  final GlobalKey _triggerKey = GlobalKey();
  late final TextEditingController _searchController;
  final minDropdownWidth = 150.0;

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.selectedItems);
    _searchController = TextEditingController(text: '');
    _searchController.addListener(() {
      setState(() {
        search = _searchController.text;
      });
    });
  }

  @override
  void didUpdateWidget(covariant NarwhalFilterSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.selectedItems, selected)) {
      setState(() {
        selected = List<String>.from(widget.selectedItems);
      });
    }
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

  Widget _buildDropdownMenu(VoidCallback closeOverlay) {
    final triggerPosition = _getTriggerPosition();
    final triggerSize = _getTriggerSize();

    if (triggerPosition == null || triggerSize == null) return const SizedBox.shrink();

    return Positioned(
      top: triggerPosition.dy + triggerSize.height + 4,
      left: triggerPosition.dx,
      child: Material(
        elevation: widget.elevation ?? 8,
        borderRadius: BorderRadius.circular(8),
        child: StatefulBuilder(
          builder: (context, overlaySetState) {
            return Container(
              width: max(triggerSize.width, minDropdownWidth),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeHelper.neutral100(context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ThemeHelper.blue()),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selected
                          .map((item) => Chip(
                                label: Text(
                                  item,
                                  style: NarwhalStyles.dropdownChipTextStyle(context),
                                ),
                                backgroundColor: ThemeHelper.blue400(context).withValues(alpha: 0.5),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                labelPadding: EdgeInsets.zero,
                                onDeleted: () {
                                  selected.remove(item);
                                  widget.onChanged(selected);
                                  overlaySetState(() {});
                                },
                              ))
                          .toList(),
                    ),
                  if (selected.isNotEmpty) const SizedBox(height: 8),
                  const Divider(),
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: NarwhalStyles.modalTextFieldInputHintStyle(context),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                overlaySetState(() {});
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
                      ),
                      filled: true,
                      fillColor: ThemeHelper.neutral100(context),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
                    ),
                    style: const NarwhalTextStyle(fontSize: 12),
                    controller: _searchController,
                    onChanged: (value) {
                      search = value;
                      overlaySetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  // Scrollable list of available items
                  SizedBox(
                    height: 200,
                    child: Builder(builder: (context) {
                      final filtered = search.isEmpty
                          ? widget.allItems.where((t) => !selected.contains(t)).toList()
                          : widget.allItems
                              .where((t) => !selected.contains(t) && t.toLowerCase().contains(search.toLowerCase()))
                              .toList();
                      return search.isNotEmpty && filtered.isEmpty
                          ? Center(child: Text('No ${widget.label.toLowerCase()} found'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final item = filtered[idx];
                                return HoverableListTile(
                                  title: Text(item, style: NarwhalStyles.dropdownListTextStyle(context)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  onTap: () {
                                    selected.add(item);
                                    widget.onChanged(selected);
                                    overlaySetState(() {});
                                  },
                                );
                              },
                            );
                    }),
                  ),
                ],
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
    final hoverColor = widget.hoverColor ?? ThemeHelper.blue().withValues(alpha: 0.1);
    final hoverBorderColor = widget.hoverBorderColor ?? ThemeHelper.blue();

    return NarwhalOverlay(
      isOpen: _isOpen,
      onClose: () => setState(() => _isOpen = false),
      customOffset: _getTriggerPosition(),
      customSize: _getTriggerSize(),
      builder: (context, closeOverlay) {
        return _buildDropdownMenu(closeOverlay);
      },
      child: HoverBuilder(
        builder: (context, isHovered) {
          return GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              key: _triggerKey,
              height: widget.height ?? 30,
              width: widget.width,
              decoration: BoxDecoration(
                border: Border.all(color: isHovered ? hoverBorderColor : borderColor),
                color: isHovered ? hoverColor : backgroundColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minWidthForIcon = 60.0;
                  final showIcon = constraints.maxWidth > minWidthForIcon;

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected.isNotEmpty ? '${widget.label}: ${selected.join(', ')}' : widget.label,
                          style: widget.textStyle ?? const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (showIcon) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          size: 18,
                          color: ThemeHelper.neutral500(context),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/*
================================================================================
                           HOW TO USE NARWHALFILTERSELECT
================================================================================

NarwhalFilterSelect is a multi-select dropdown widget that allows users to type
into a text box to filter through options. It uses NarwhalOverlay for consistent
dropdown behavior and provides the same functionality as OverlayMultiSelectDropdown
but with better styling and integration with other Narwhal components.

BASIC USAGE:
-----------
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<String> selectedTags = [];
  final List<String> allTags = ['Tag1', 'Tag2', 'Tag3', 'Tag4'];

  @override
  Widget build(BuildContext context) {
    return NarwhalFilterSelect(
      allItems: allTags,
      selectedItems: selectedTags,
      onChanged: (newSelected) {
        setState(() {
          selectedTags = newSelected;
        });
      },
      label: 'Tags',
      searchHint: 'Search tags',
      width: 200,
    );
  }
}

ADVANCED USAGE:
--------------
NarwhalFilterSelect(
  allItems: availableReleases,
  selectedItems: selectedReleases,
  onChanged: (newSelected) {
    // Handle selection change
    ref.read(archiveItemQueryProvider.notifier).state = 
        archiveItemQuery.copyWith(releases: newSelected);
  },
  label: 'Releases',
  searchHint: 'Search releases',
  width: 250,
  height: 35,
  backgroundColor: ThemeHelper.neutral100(context),
  borderColor: ThemeHelper.neutral400(context),
  hoverColor: Colors.blue.withValues(alpha: 0.1),
  hoverBorderColor: Colors.blue,
  borderRadius: BorderRadius.circular(6.0),
  elevation: 8,
  textStyle: NarwhalTextStyle(fontSize: 13, fontWeight: FontWeight.normal),
)

PARAMETERS:
-----------
- allItems: List of all available items to select from (required)
- selectedItems: List of currently selected items (required)
- onChanged: Callback when selection changes (required)
- label: Display label for the dropdown (required)
- searchHint: Placeholder text for the search field (required)
- width: Width of the dropdown trigger (optional, default: 200)
- height: Height of the dropdown trigger (optional, default: 30)
- backgroundColor: Background color of the trigger (optional)
- borderColor: Border color of the trigger (optional)
- hoverColor: Background color when hovering (optional)
- hoverBorderColor: Border color when hovering (optional)
- borderRadius: Border radius of the trigger (optional)
- padding: Padding inside the trigger (optional)
- textStyle: Text style for the trigger text (optional)
- elevation: Elevation of the dropdown menu (optional, default: 8)

KEY FEATURES:
------------
- Type-to-filter functionality: Shows all items initially, filters as user types
- Multi-selection with chips: Selected items appear as removable chips
- Uses NarwhalOverlay for consistent dropdown behavior
- Hover effects on both trigger and menu items
- Auto-close on outside clicks
- Responsive layout that adapts to available width
- Search field with clear button
- Empty state when no filtered results found
- Customizable appearance to match application theme

FILTERING BEHAVIOR:
------------------
- When no text is entered: Shows all unselected items
- When text is entered: Shows only items that contain the search text (case-insensitive)
- Selected items are excluded from the dropdown list
- Selected items appear as chips above the search field
- Users can remove selections by clicking the X on chips

STYLING NOTES:
--------------
- Uses ThemeHelper colors for consistent theming
- Dropdown menu matches NarwhalDropdownSelect styling
- Selected chips use NarwhalColors.blue50 background
- Hover effects provide visual feedback
- Responsive icon display based on available width

WHEN TO USE:
-----------
✅ Multi-select dropdowns with many options
✅ Tag selection interfaces
✅ Filter controls that need search functionality
✅ Any multi-select where users benefit from typing to narrow options
✅ Replacing OverlayMultiSelectDropdown for better consistency

WHEN NOT TO USE:
---------------
❌ Single-select dropdowns (use NarwhalDropdownSelect)
❌ Very small option lists where filtering isn't beneficial
❌ When platform-specific multi-select behavior is required
❌ Simple checkbox lists where all options should always be visible

================================================================================
*/
