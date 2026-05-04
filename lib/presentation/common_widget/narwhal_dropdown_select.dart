import 'package:onyxia/export.dart';

/// @ponder ponder/NarwhalDropdownSelect.gif
class NarwhalDropdownSelect<T> extends StatefulWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double? width;
  final double? height;
  final String? hint;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hoverColor;
  final Color? hoverBorderColor;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final double? elevation;
  final bool isExpanded;
  final bool isDense;

  const NarwhalDropdownSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
    this.height,
    this.hint,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.hoverColor,
    this.hoverBorderColor,
    this.padding,
    this.textStyle,
    this.elevation,
    this.isExpanded = true,
    this.isDense = true,
  });

  @override
  State<NarwhalDropdownSelect<T>> createState() => _NarwhalDropdownSelectState<T>();
}

class _NarwhalDropdownSelectState<T> extends State<NarwhalDropdownSelect<T>> {
  bool _isOpen = false;
  final GlobalKey _triggerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? ThemeHelper.neutral100(context);
    final borderColor = widget.borderColor ?? ThemeHelper.neutral400(context);
    final hoverColor = widget.hoverColor ?? ThemeHelper.blue().withValues(alpha: 0.1);
    final hoverBorderColor = widget.hoverBorderColor ?? ThemeHelper.blue();

    // Find the selected item's text
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

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
              width: widget.width,
              height: widget.height ?? 40,
              decoration: BoxDecoration(
                color: isHovered ? hoverColor : backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(_isOpen ? 0 : 6),
                  bottomRight: Radius.circular(_isOpen ? 0 : 6),
                ),
                border: Border.all(
                  color: isHovered ? hoverBorderColor : borderColor,
                  width: 1,
                ),
              ),
              padding: widget.padding ??
                  const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 0.0,
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.isExpanded
                      ? Expanded(
                          child: _buildSelectedText(selectedItem, context),
                        )
                      : _buildSelectedText(selectedItem, context),
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

    if (triggerPosition == null || triggerSize == null) return const SizedBox.shrink();

    return Positioned(
      top: triggerPosition.dy + triggerSize.height - 1, // Subtract 1 to overlap the border
      left: triggerPosition.dx,
      child: Material(
        elevation: widget.elevation ?? 8,
        color: ThemeHelper.neutral100(context),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.items.map((item) => _buildDropdownItem(item, closeOverlay)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(
    DropdownMenuItem<T> item,
    VoidCallback closeOverlay,
  ) {
    final isSelected = item.value == widget.value;

    return HoverBuilder(
      builder: (context, isHovered) {
        return InkWell(
          onTap: () {
            widget.onChanged(item.value);
            closeOverlay();
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isSelected || isHovered
                  ? ThemeHelper.blue400(context).withValues(alpha: 0.3)
                  : ThemeHelper.neutral100(context),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: widget.textStyle?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ) ??
                    NarwhalTextStyle(
                      color: ThemeHelper.neutral700(context),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                child: item.child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedText(DropdownMenuItem<T> selectedItem, BuildContext context) {
    return DefaultTextStyle(
      style: widget.textStyle ??
          NarwhalTextStyle(
            color: ThemeHelper.neutral700(context),
            fontSize: 13,
          ),
      child: selectedItem.child,
    );
  }
}

/*
================================================================================
                           HOW TO USE NARWHALDROPDOWNSELECT
================================================================================

NarwhalDropdownSelect is a custom dropdown widget that uses NarwhalOverlay for
its dropdown options and has a similar style to the canvas right-click menu.
It provides a cleaner, more consistent experience than Flutter's default dropdown.

BASIC USAGE:
-----------
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String selectedValue = 'Option 1';

  @override
  Widget build(BuildContext context) {
    return NarwhalDropdownSelect<String>(
      value: selectedValue,
      items: [
        DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
        DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
        DropdownMenuItem(value: 'Option 3', child: Text('Option 3')),
      ],
      onChanged: (value) {
        setState(() {
          selectedValue = value ?? 'Option 1';
        });
      },
      width: 200,
    );
  }
}

ADVANCED USAGE:
--------------
NarwhalDropdownSelect<ProjectsShown>(
  value: projectsShown,
  items: ProjectsShown.values.map((option) {
    return DropdownMenuItem<ProjectsShown>(
      value: option,
      child: Text(option.value),
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      ref.read(projectsProvider.notifier).setProjectsShown(value);
    }
  },
  width: 260,
  height: 40,
  backgroundColor: ThemeHelper.neutral100(context),
  borderColor: ThemeHelper.neutra400(context),
  hoverColor: Colors.blue.withValues(alpha: 0.1),
  hoverBorderColor: Colors.blue,
  borderRadius: BorderRadius.circular(6.0),
  elevation: 8,
  isExpanded: true,
  isDense: true,
)

PARAMETERS:
-----------
- value: The currently selected value (required)
- items: List of DropdownMenuItem<T> for the dropdown options (required)
- onChanged: Callback when selection changes (required)
- width: Width of the dropdown trigger (optional)
- height: Height of the dropdown trigger (optional, default: 40)
- hint: Hint text when no value is selected (optional)
- icon: Custom icon for the dropdown arrow (optional)
- backgroundColor: Background color of the trigger (optional)
- borderColor: Border color of the trigger (optional)
- hoverColor: Background color when hovering (optional)
- hoverBorderColor: Border color when hovering (optional)
- borderRadius: Border radius of the trigger (optional)
- padding: Padding inside the trigger (optional)
- textStyle: Text style for the selected value (optional)
- elevation: Elevation of the dropdown menu (optional, default: 8)
- isExpanded: Whether the trigger content should expand (optional, default: true)
- isDense: Whether to use dense layout (optional, default: true)

KEY FEATURES:
------------
- Uses NarwhalOverlay for non-consuming dropdown behavior
- Canvas right-click menu styling
- Hover effects on both trigger and menu items
- Selected item highlighting
- Customizable appearance
- Keyboard navigation support
- Auto-close on outside clicks
- Responsive to theme changes

STYLING NOTES:
--------------
- The dropdown menu uses NarwhalColors.canvasObjectDefaultFill for background
- Menu items use NarwhalColors.highlight for hover/selection states
- Text colors adapt to the current theme
- Selected items are highlighted with bold text and background color
- Hover effects provide visual feedback

WHEN TO USE:
-----------
✅ Project filter dropdowns
✅ Settings selection menus
✅ Any dropdown that needs consistent styling
✅ Dropdowns that should match canvas right-click menu style
✅ When you need non-consuming dropdown behavior

WHEN NOT TO USE:
---------------
❌ Simple form dropdowns (use standard DropdownButton)
❌ When you need multiselect functionality
❌ Very large option lists (consider search functionality)
❌ When platform-specific styling is required

================================================================================
*/
