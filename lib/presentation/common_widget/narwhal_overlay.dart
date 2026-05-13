import 'package:onyxia/export.dart';

/// @ponder ponder/NarwhalOverlay.gif
///
/// Anchors a follower widget to [child] using flutter_portal, and runs a
/// non-consuming full-screen pointer listener so clicks outside both the
/// trigger and the follower can close the overlay while still hitting their
/// underlying targets (e.g. clicking another button outside the overlay both
/// closes it AND fires that button's onPressed).
class NarwhalOverlay extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback closeOverlay) builder;
  final Widget child;
  final bool isOpen;
  final VoidCallback? onClose;
  final Anchor anchor;
  final bool autoClose;
  final Duration? closingDelay;

  const NarwhalOverlay({
    super.key,
    required this.builder,
    required this.child,
    required this.isOpen,
    this.onClose,
    this.anchor = const Aligned(
      follower: Alignment.topLeft,
      target: Alignment.bottomLeft,
      offset: Offset(0, 4),
      backup: Aligned(
        follower: Alignment.topRight,
        target: Alignment.bottomRight,
        offset: Offset(0, 4),
      ),
    ),
    this.autoClose = true,
    this.closingDelay,
  });

  @override
  State<NarwhalOverlay> createState() => _NarwhalOverlayState();
}

class _NarwhalOverlayState extends State<NarwhalOverlay> {
  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey _followerKey = GlobalKey();
  OverlayEntry? _outsideListenerEntry;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _installOutsideListener();
      });
    }
  }

  @override
  void didUpdateWidget(NarwhalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _installOutsideListener();
      });
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _removeOutsideListener();
    }
  }

  @override
  void dispose() {
    _removeOutsideListener();
    super.dispose();
  }

  void _installOutsideListener() {
    if (_outsideListenerEntry != null) return;
    final overlay = Overlay.of(context);
    _outsideListenerEntry = OverlayEntry(
      builder: (_) => _OutsideClickListener(
        triggerKey: _triggerKey,
        followerKey: _followerKey,
        autoClose: widget.autoClose,
        closingDelay: widget.closingDelay,
        onClose: _close,
      ),
    );
    overlay.insert(_outsideListenerEntry!);
    _router = GoRouter.of(context);
    _router?.routeInformationProvider.addListener(_handleRouteChange);
  }

  void _removeOutsideListener() {
    _outsideListenerEntry?.remove();
    _outsideListenerEntry = null;
    _router?.routeInformationProvider.removeListener(_handleRouteChange);
    _router = null;
  }

  void _close() {
    _removeOutsideListener();
    widget.onClose?.call();
  }

  void _handleRouteChange() => _close();

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: widget.isOpen,
      anchor: widget.anchor,
      portalFollower: Focus(
        autofocus: true,
        onFocusChange: (hasFocus) {
          if (!hasFocus && widget.autoClose) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _close();
            });
          }
        },
        child: KeyedSubtree(
          key: _followerKey,
          child: widget.builder(context, _close),
        ),
      ),
      child: KeyedSubtree(key: _triggerKey, child: widget.child),
    );
  }
}

/// Full-screen translucent listener inserted into Flutter's native [Overlay]
/// while the menu is open. It detects pointer-down events outside the
/// trigger and follower and triggers a close, without consuming the gesture
/// (so the underlying widget still receives the same tap).
class _OutsideClickListener extends StatefulWidget {
  final GlobalKey triggerKey;
  final GlobalKey followerKey;
  final bool autoClose;
  final Duration? closingDelay;
  final VoidCallback onClose;

  const _OutsideClickListener({
    required this.triggerKey,
    required this.followerKey,
    required this.autoClose,
    required this.closingDelay,
    required this.onClose,
  });

  @override
  State<_OutsideClickListener> createState() => _OutsideClickListenerState();
}

class _OutsideClickListenerState extends State<_OutsideClickListener> {
  bool _containsGlobalPoint(GlobalKey key, Offset globalPosition) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;
    final local = renderObject.globalToLocal(globalPosition);
    return Rect.fromLTWH(
      0,
      0,
      renderObject.size.width,
      renderObject.size.height,
    ).contains(local);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.autoClose) return;
    if (_containsGlobalPoint(widget.triggerKey, event.position)) return;
    if (_containsGlobalPoint(widget.followerKey, event.position)) return;

    if (widget.closingDelay != null) {
      Future.delayed(widget.closingDelay!, () {
        if (mounted) widget.onClose();
      });
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/*
================================================================================
                              HOW TO USE NARWHALOVERLAY
================================================================================

NarwhalOverlay anchors a follower widget to a trigger using flutter_portal, and
runs a non-consuming full-screen pointer listener so taps outside both close
the overlay without swallowing the gesture.

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
      onClose: () => setState(() => _isOpen = false),
      builder: (context, closeOverlay) {
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Overlay Content'),
                ElevatedButton(
                  onPressed: closeOverlay,
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
      child: ElevatedButton(
        onPressed: () => setState(() => _isOpen = !_isOpen),
        child: const Text('Toggle Overlay'),
      ),
    );
  }
}

CUSTOM ANCHORING:
-----------------
By default the follower's top-left aligns to the trigger's bottom-left with a
+4px vertical gap, and falls back to right-aligned (top-right to bottom-right)
when the default would overflow the viewport. To override:

NarwhalOverlay(
  anchor: const Aligned(
    follower: Alignment.bottomLeft,
    target: Alignment.topLeft,
    offset: Offset(0, -4), // open upward instead
  ),
  // ...
)

PARAMETERS:
-----------
- builder: Function that builds the overlay content. Receives context and
  closeOverlay callback. Return the menu content directly (no Positioned).
- child: The trigger widget (button, icon, etc.).
- isOpen: Whether the overlay is visible.
- onClose: Called when the overlay closes.
- anchor: flutter_portal Anchor (default: bottom-left with right-aligned backup).
- autoClose: Whether to close on tap outside or focus loss (default: true).
- closingDelay: Optional delay before closing.

KEY FEATURES:
------------
- Non-consuming outside-tap detection (clicks outside still hit their target).
- Declarative anchoring via flutter_portal (re-anchors on scroll/resize).
- Auto-close on GoRouter navigation.
- Focus management for keyboard navigation.

WHEN TO USE:
-----------
- Dropdown menus and context menus
- User profile menus, settings panels
- Any anchored overlay that shouldn't block outside interaction

WHEN NOT TO USE:
---------------
- Modal dialogs (use NarwhalModalDialog + showDialog)
- Tooltips (use Tooltip)
- Notifications (use NarwhalToast)
================================================================================
*/
