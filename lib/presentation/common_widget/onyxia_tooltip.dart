import 'dart:async';

import 'package:onyxia/export.dart';
import 'package:speech_balloon/speech_balloon.dart' as sb;

enum OnyxiaTooltipDirection { top, bottom, left, right }

class OnyxiaTooltip extends StatefulWidget {
  final String message;

  /// Side of the trigger the balloon appears on. When null, picks the side
  /// with the most viewport room (preferring bottom, then top, then the
  /// larger of left/right).
  final OnyxiaTooltipDirection? direction;
  final Duration waitDuration;
  final Widget child;

  const OnyxiaTooltip({
    super.key,
    required this.message,
    this.direction,
    this.waitDuration = const Duration(milliseconds: 500),
    required this.child,
  });

  @override
  State<OnyxiaTooltip> createState() => _OnyxiaTooltipState();
}

class _OnyxiaTooltipState extends State<OnyxiaTooltip>
    with SingleTickerProviderStateMixin {
  // Global cooldown: once any tooltip has been shown and dismissed, the next
  // tooltip to be triggered within this window skips its wait and shows
  // immediately. Mimics Windows/Material "subsequent tooltips show without
  // delay" behavior for users sweeping across a row of buttons.
  static DateTime? _lastShownTooltipHiddenAt;
  static const _cooldownWindow = Duration(milliseconds: 1000);

  bool _open = false;
  Timer? _showTimer;
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  OnyxiaTooltipDirection _resolvedDirection = .bottom;
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scale, curve: Curves.easeInExpo));
    _opacityAnim = CurvedAnimation(parent: _scale, curve: Curves.easeInExpo);
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _scale.dispose();
    super.dispose();
  }

  void _scheduleShow() {
    _showTimer?.cancel();
    final last = _lastShownTooltipHiddenAt;
    final inCooldown =
        last != null && DateTime.now().difference(last) < _cooldownWindow;
    if (inCooldown) {
      _show();
    } else {
      _showTimer = Timer(widget.waitDuration, _show);
    }
  }

  void _show() {
    if (!mounted) return;
    setState(() {
      _resolvedDirection = widget.direction ?? _autoDirection();
      _open = true;
    });
    _scale.forward(from: 0);
  }

  void _hide() {
    _showTimer?.cancel();
    if (!_open) return;
    _lastShownTooltipHiddenAt = DateTime.now();
    setState(() => _open = false);
    _scale.reset();
  }

  OnyxiaTooltipDirection _autoDirection() {
    final ro = _childKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return .bottom;

    final viewport = MediaQuery.sizeOf(context);
    final pos = ro.localToGlobal(Offset.zero);
    final bottomRoom = viewport.height - (pos.dy + ro.size.height);
    final topRoom = pos.dy;
    final leftRoom = pos.dx;
    final rightRoom = viewport.width - (pos.dx + ro.size.width);

    // Crude clearance estimate — most tooltips are a single line, ~32px tall.
    const needed = 50.0;
    if (bottomRoom > needed) return .bottom;
    if (topRoom > needed) return .top;
    return rightRoom > leftRoom ? .right : .left;
  }

  // Nip points TOWARD the trigger. When the balloon sits below the trigger,
  // the nip is on the balloon's top edge.
  sb.NipLocation _nipFor(OnyxiaTooltipDirection d) => switch (d) {
    .bottom => .top,
    .top => .bottom,
    .right => .left,
    .left => .right,
  };

  Anchor _anchorFor(OnyxiaTooltipDirection d) => switch (d) {
    .bottom => const Aligned(
      follower: .topCenter,
      target: .bottomCenter,
      offset: Offset(0, 6),
    ),
    .top => const Aligned(
      follower: .bottomCenter,
      target: .topCenter,
      offset: Offset(0, -6),
    ),
    .right => const Aligned(
      follower: .centerLeft,
      target: .centerRight,
      offset: Offset(6, 0),
    ),
    .left => const Aligned(
      follower: .centerRight,
      target: .centerLeft,
      offset: Offset(-6, 0),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final balloon = FadeTransition(
      opacity: _opacityAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: .center,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: sb.SpeechBalloon(
              nipLocation: _nipFor(_resolvedDirection),
              color: ThemeHelper.auxiliary(),
              borderRadius: 6,
              nipHeight: 6,
              width: double.infinity,
              height: double.infinity,
              child: Padding(
                padding: .symmetric(horizontal: 10, vertical: 6),
                child: Center(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: .w500,
                      color: ThemeHelper.foreground1(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => _scheduleShow(),
      onExit: (_) => _hide(),
      child: PortalTarget(
        visible: _open,
        anchor: _anchorFor(_resolvedDirection),
        portalFollower: IgnorePointer(child: balloon),
        child: KeyedSubtree(key: _childKey, child: widget.child),
      ),
    );
  }
}
