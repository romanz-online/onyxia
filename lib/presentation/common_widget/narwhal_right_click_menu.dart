import 'package:onyxia/export.dart';
import '../../helpers/safe_right_click_menu_position.dart';

class NarwhalRightClickMenuItem {
  final VoidCallback optionHandler;
  final String optionLabel;
  final int optionIndex;
  final bool dividerBefore;
  final IconData? optionIcon;

  NarwhalRightClickMenuItem({
    required this.optionHandler,
    required this.optionLabel,
    required this.optionIndex,
    this.dividerBefore = false,
    this.optionIcon,
  });
}

class NarwhalRightClickMenu extends StatefulWidget {
  // static function, to avoid scenario where we declare a global-visible
  // function that exists outside of any particular Class
  static handleRightClickMenuRequest(
    BuildContext context,
    Offset globalPosition,
    List<NarwhalRightClickMenuItem> options,
    WidgetRef ref,
  ) {
    _NarwhalRightClickMenuState.closeAllMenus();
    _NarwhalRightClickMenuState.createRightClickMenu(context, globalPosition, options, ref);
  }

  final BuildContext context;
  final Offset globalPosition;
  final List<NarwhalRightClickMenuItem> options;
  final WidgetRef ref;
  final VoidCallback onClose;

  const NarwhalRightClickMenu({
    super.key,
    required this.context,
    required this.globalPosition,
    required this.options,
    required this.ref,
    required this.onClose,
  });

  @override
  State<NarwhalRightClickMenu> createState() => _NarwhalRightClickMenuState();
}

class _NarwhalRightClickMenuState extends State<NarwhalRightClickMenu> {
  // static objects and functions, for implementing the interface
  // that allows the Menu to be shown as an Overlay
  static OverlayEntry? _activeRightClickMenuOverlay;

  static void createRightClickMenu(
    BuildContext context,
    Offset globalPosition,
    List<NarwhalRightClickMenuItem> options,
    WidgetRef ref,
  ) {
    closeAllMenus();

    _activeRightClickMenuOverlay = OverlayEntry(
        builder: (context) => NarwhalRightClickMenu(
              context: context,
              globalPosition: globalPosition,
              options: options,
              ref: ref,
              onClose: closeAllMenus,
            ));
    Overlay.of(context).insert(_activeRightClickMenuOverlay!);
  }

  static void closeAllMenus() {
    if (_activeRightClickMenuOverlay != null) {
      _activeRightClickMenuOverlay!.remove();
      _activeRightClickMenuOverlay!.dispose();
      _activeRightClickMenuOverlay = null;
    }
  }

  int _hoveredItemIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate actual menu height including dividers and padding
    final screenSize = MediaQuery.of(context).size;
    int dividerCount = 0;
    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (option.dividerBefore) {
        dividerCount++;
      }
    }

    final estimatedMenuHeight = (widget.options.length * 42.0) + // Menu items (40px + 2px margin)
        (dividerCount * 9.0) + // Dividers (1px + 4px margin each)
        16.0; // Top/bottom padding

    final safePosition = SafeMenuPosition.calculateSafePosition(
      preferredPosition: widget.globalPosition,
      menuSize: Size(220, estimatedMenuHeight), // Updated width and height
      screenSize: screenSize,
      padding: 16.0, // Increased padding for better visibility
    );

    return Stack(
      children: [
        // Simple background for left click detection only
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Only handle left clicks to close menu
              widget.onClose();
            },
            // NO onSecondaryTap - let right clicks pass through completely
            child: Container(),
          ),
        ),
        // Main menu
        Positioned(
          left: safePosition.dx,
          top: safePosition.dy,
          child: _buildMenuContent(),
        ),
      ],
    );
  }

  Widget _buildMenuContent() {
    return Material(
      elevation: 12,
      shadowColor: ThemeHelper.black(context).withValues(alpha: 0.15),
      //color: ThemeHelper.white(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildMenuItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];

    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      final itemIndex = option.optionIndex;

      final Widget optionText = Text(option.optionLabel,
          style: NarwhalTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ThemeHelper.neutral700(context)));
      final Widget optionWidget = (option.optionIcon != null)
          ? Row(children: [
              Icon(option.optionIcon, size: 16, color: ThemeHelper.neutral700(context)),
              const SizedBox(width: 8),
              Expanded(child: optionText)
            ])
          : optionText;

      if (option.dividerBefore) {
        items.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
          ),
        ));
      }

      items.add(MouseRegion(
        onEnter: (_) {
          if (mounted) {
            setState(() {
              _hoveredItemIndex = itemIndex;
            });
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() {
              _hoveredItemIndex = -1;
            });
          }
        },
        child: GestureDetector(
          onTap: () {
            option.optionHandler();
            widget.onClose();
          },
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: (_hoveredItemIndex == itemIndex) ? ThemeHelper.neutral300(context) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.0),
              child: optionWidget,
            ),
          ),
        ),
      ));
    }
    return items;
  }
}
