import 'package:onyxia/export.dart';

// Pulse-dot animation values mirror the pre-Flutter CSS in web/index.html.
// Keep duration / scale / opacity / color in sync if you change them.
class OnyxiaLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const OnyxiaLoadingIndicator({super.key, this.size = 24, this.color});

  @override
  State<OnyxiaLoadingIndicator> createState() => _OnyxiaLoadingIndicatorState();
}

class _OnyxiaLoadingIndicatorState extends State<OnyxiaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? ThemeHelper.accentColor();
    final dotBase = widget.size * 0.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            final scale = 1.0 + 0.3 * t;
            final opacity = 0.8 + 0.2 * t;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: dotBase,
                height: dotBase,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: .circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
