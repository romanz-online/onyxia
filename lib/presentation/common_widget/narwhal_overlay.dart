import 'package:onyxia/export.dart';

/// @ponder ponder/NarwhalOverlay.gif
class NarwhalOverlay extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback closeOverlay) builder;
  final Widget child;
  final bool isOpen;
  final VoidCallback? onToggle;
  final VoidCallback? onClose;
  final Offset? customOffset;
  final Size? customSize;
  final bool autoClose;
  final Duration? closingDelay;

  const NarwhalOverlay({
    super.key,
    required this.builder,
    required this.child,
    required this.isOpen,
    this.onToggle,
    this.onClose,
    this.customOffset,
    this.customSize,
    this.autoClose = true,
    this.closingDelay,
  });

  @override
  State<NarwhalOverlay> createState() => _NarwhalOverlayState();
}

class _NarwhalOverlayState extends State<NarwhalOverlay> {
  OverlayEntry? _overlayEntry;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOverlay();
      });
    }
  }

  @override
  void didUpdateWidget(NarwhalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOverlay();
      });
    } else if (!widget.isOpen && oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _removeOverlay();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _router?.routeInformationProvider.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = widget.customSize ?? renderBox.size;
    final offset = widget.customOffset ?? renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _NarwhalOverlayContent(
        offset: offset,
        size: size,
        onClose: _closeOverlay,
        autoClose: widget.autoClose,
        closingDelay: widget.closingDelay,
        child: widget.builder(context, _closeOverlay),
      ),
    );

    overlay.insert(_overlayEntry!);

    // Add route listener to auto-close on navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addRouteListener();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _router?.routeInformationProvider.removeListener(_handleRouteChange);
  }

  void _closeOverlay() {
    _removeOverlay();
    widget.onClose?.call();
  }

  void _addRouteListener() {
    _router = GoRouter.of(context);
    _router?.routeInformationProvider.addListener(_handleRouteChange);
  }

  void _handleRouteChange() {
    _closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NarwhalOverlayContent extends StatefulWidget {
  final Offset offset;
  final Size size;
  final VoidCallback onClose;
  final Widget child;
  final bool autoClose;
  final Duration? closingDelay;

  const _NarwhalOverlayContent({
    required this.offset,
    required this.size,
    required this.onClose,
    required this.child,
    required this.autoClose,
    this.closingDelay,
  });

  @override
  State<_NarwhalOverlayContent> createState() => _NarwhalOverlayContentState();
}

class _NarwhalOverlayContentState extends State<_NarwhalOverlayContent> {
  final GlobalKey _overlayKey = GlobalKey();

  bool _isPointInOverlay(Offset globalPosition) {
    final RenderBox? renderBox = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    return Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height)
        .contains(renderBox.globalToLocal(globalPosition));
  }

  bool _isPointInTrigger(Offset globalPosition) => Rect.fromLTWH(
        widget.offset.dx,
        widget.offset.dy,
        widget.size.width,
        widget.size.height,
      ).contains(globalPosition);

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.autoClose) return;

    final isInOverlay = _isPointInOverlay(event.position);
    final isInTrigger = _isPointInTrigger(event.position);

    if (!isInOverlay && !isInTrigger) {
      if (widget.closingDelay != null) {
        Future.delayed(widget.closingDelay!, () {
          if (mounted) widget.onClose();
        });
      } else {
        widget.onClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus && widget.autoClose) {
          // Small delay to allow for focus changes within the overlay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) widget.onClose();
          });
        }
      },
      child: Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Container(key: _overlayKey, child: widget.child),
          ],
        ),
      ),
    );
  }
}

/*
================================================================================
                              HOW TO USE NARWHALOVERLAY
================================================================================

NarwhalOverlay is a reusable widget that provides non-consuming overlay behavior.
Unlike Flutter's default overlays, it doesn't consume clicks outside the overlay,
allowing users to interact with underlying UI elements immediately.

BASIC USAGE:
-----------
class MyDropdownWidget extends StatefulWidget {
  @override
  State<MyDropdownWidget> createState() => _MyDropdownWidgetState();
}

class _MyDropdownWidgetState extends State<MyDropdownWidget> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return NarwhalOverlay(
      isOpen: _isOpen,
      onToggle: () => setState(() => _isOpen = !_isOpen),
      builder: (context, closeOverlay) {
        return Positioned(
          top: 50, // Position relative to trigger
          left: 0,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Overlay Content'),
                  ElevatedButton(
                    onPressed: closeOverlay,
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: ElevatedButton(
        onPressed: () => setState(() => _isOpen = !_isOpen),
        child: Text('Toggle Overlay'),
      ),
    );
  }
}

ADVANCED USAGE:
--------------
NarwhalOverlay(
  isOpen: _isDropdownOpen,
  onToggle: _toggleDropdown,
  onClose: _onDropdownClose,
  autoClose: true,
  closingDelay: Duration(milliseconds: 100),
  customOffset: Offset(100, 50),
  customSize: Size(200, 40),
  builder: (context, closeOverlay) {
    return Positioned(
      top: 50,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  closeOverlay();
                  _handleSettings();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  closeOverlay();
                  _handleLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  },
  child: IconButton(
    icon: Icon(Icons.more_vert),
    onPressed: _toggleDropdown,
  ),
);

PARAMETERS:
-----------
- builder: Function that builds the overlay content. Receives context and closeOverlay callback.
- child: The widget that triggers the overlay (e.g., button, avatar).
- isOpen: Boolean controlling whether the overlay is visible.
- onToggle: Called when the overlay should be toggled (optional).
- onClose: Called when the overlay is closed (optional).
- customOffset: Custom position for the overlay trigger area (optional).
- customSize: Custom size for the overlay trigger area (optional).
- autoClose: Whether to automatically close when clicking outside (default: true).
- closingDelay: Delay before closing the overlay (optional).

KEY FEATURES:
------------
- Non-consuming click detection: Clicks outside the overlay don't get consumed
- Automatic route change detection: Closes overlay when navigating
- Focus management: Handles keyboard navigation properly
- Customizable positioning: Use Positioned widget in builder for precise placement
- Auto-close behavior: Configurable automatic closing
- Lightweight: Minimal overhead, only active when overlay is open

POSITIONING OVERLAY CONTENT:
---------------------------
Use Positioned widget in the builder to control where the overlay appears:

// Dropdown below trigger:
Positioned(
  top: widget.offset.dy + widget.size.height + 8,
  left: widget.offset.dx,
  child: Material(...),
)

// Dropdown above trigger:
Positioned(
  bottom: MediaQuery.of(context).size.height - widget.offset.dy,
  left: widget.offset.dx,
  child: Material(...),
)

// Dropdown to the right:
Positioned(
  top: widget.offset.dy + widget.size.height + 8,
  right: 16,
  child: Material(...),
)

WHEN TO USE:
-----------
✅ Dropdown menus and context menus
✅ Search suggestion overlays
✅ User profile menus
✅ Settings panels
✅ Any overlay that shouldn't consume outside clicks

WHEN NOT TO USE:
---------------
❌ Modal dialogs that should block interaction
❌ Full-screen overlays
❌ Tooltips (use Tooltip widget instead)
❌ Notifications (use SnackBar or similar)

================================================================================
*/
