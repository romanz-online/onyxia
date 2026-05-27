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
  bool _open = false;
  Timer? _showTimer;
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;
  OnyxiaTooltipDirection _resolvedDirection = OnyxiaTooltipDirection.bottom;
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scale, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _scale.dispose();
    super.dispose();
  }

  void _scheduleShow() {
    _showTimer?.cancel();
    _showTimer = Timer(widget.waitDuration, _show);
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
    setState(() => _open = false);
    _scale.reset();
  }

  OnyxiaTooltipDirection _autoDirection() {
    final ro = _childKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) {
      return OnyxiaTooltipDirection.bottom;
    }
    final viewport = MediaQuery.sizeOf(context);
    final pos = ro.localToGlobal(Offset.zero);
    final bottomRoom = viewport.height - (pos.dy + ro.size.height);
    final topRoom = pos.dy;
    final leftRoom = pos.dx;
    final rightRoom = viewport.width - (pos.dx + ro.size.width);

    // Crude clearance estimate — most tooltips are a single line, ~32px tall.
    const needed = 50.0;
    if (bottomRoom > needed) return OnyxiaTooltipDirection.bottom;
    if (topRoom > needed) return OnyxiaTooltipDirection.top;
    return rightRoom > leftRoom
        ? OnyxiaTooltipDirection.right
        : OnyxiaTooltipDirection.left;
  }

  // Nip points TOWARD the trigger. When the balloon sits below the trigger,
  // the nip is on the balloon's top edge.
  sb.NipLocation _nipFor(OnyxiaTooltipDirection d) => switch (d) {
    OnyxiaTooltipDirection.bottom => sb.NipLocation.top,
    OnyxiaTooltipDirection.top => sb.NipLocation.bottom,
    OnyxiaTooltipDirection.right => sb.NipLocation.left,
    OnyxiaTooltipDirection.left => sb.NipLocation.right,
  };

  Anchor _anchorFor(OnyxiaTooltipDirection d) => switch (d) {
    OnyxiaTooltipDirection.bottom => const Aligned(
      follower: Alignment.topCenter,
      target: Alignment.bottomCenter,
      offset: Offset(0, 6),
    ),
    OnyxiaTooltipDirection.top => const Aligned(
      follower: Alignment.bottomCenter,
      target: Alignment.topCenter,
      offset: Offset(0, -6),
    ),
    OnyxiaTooltipDirection.right => const Aligned(
      follower: Alignment.centerLeft,
      target: Alignment.centerRight,
      offset: Offset(6, 0),
    ),
    OnyxiaTooltipDirection.left => const Aligned(
      follower: Alignment.centerRight,
      target: Alignment.centerLeft,
      offset: Offset(-6, 0),
    ),
  };

  // Scale origin matches the nip so the balloon grows out of the trigger.
  Alignment _scaleOriginFor(OnyxiaTooltipDirection d) => switch (d) {
    OnyxiaTooltipDirection.bottom => Alignment.topCenter,
    OnyxiaTooltipDirection.top => Alignment.bottomCenter,
    OnyxiaTooltipDirection.right => Alignment.centerLeft,
    OnyxiaTooltipDirection.left => Alignment.centerRight,
  };

  // Single-axis scale: scale only the axis perpendicular to the trigger-
  // adjacent edge (the axis along which the balloon spawns). The orthogonal
  // axis stays at 1.0 — uniform 2D scale around an off-axis pivot makes the
  // text glyphs pulse perpendicular to the spawn direction, which is the
  // jiggle. Vertical pulse of glyphs is especially perceptible (sharp
  // baselines moving up/down); horizontal pulse of a centered short line
  // is invisible. Single-axis scale eliminates the orthogonal motion
  // entirely.
  Matrix4 _scaleMatrix(OnyxiaTooltipDirection d, double s) {
    final vertical =
        d == OnyxiaTooltipDirection.top || d == OnyxiaTooltipDirection.bottom;
    return vertical
        ? Matrix4.diagonal3Values(1.0, s, 1.0)
        : Matrix4.diagonal3Values(s, 1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final balloon = AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform(
        transform: _scaleMatrix(_resolvedDirection, _scaleAnim.value),
        alignment: _scaleOriginFor(_resolvedDirection),
        child: child,
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: sb.SpeechBalloon(
            nipLocation: _nipFor(_resolvedDirection),
            color: ThemeHelper.neutral300(context),
            borderRadius: 6,
            nipHeight: 6,
            width: double.infinity,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Center(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.neutral800(context),
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
