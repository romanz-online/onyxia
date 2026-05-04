import 'dart:math' as math;
import 'package:onyxia/export.dart';

/// A widget that wraps its child with angry shaking animation and dynamic shadow effects
/// @ponder ponder/NarwhalAngry.gif
class NarwhalAngry extends StatefulWidget {
  final Widget child;
  final NarwhalAngryController controller;

  const NarwhalAngry({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<NarwhalAngry> createState() => _NarwhalAngryState();
}

class _NarwhalAngryState extends State<NarwhalAngry> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final double angryShadowBaseAlpha = 0.3;
  final double angryShadowMultiplier = 0.6;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    widget.controller._bind(_shakeController);
  }

  @override
  void dispose() {
    widget.controller._unbind();
    _shakeController.dispose();
    super.dispose();
  }

  void _initAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        Widget transformedChild = Transform.translate(
          offset: Offset(
            math.sin(_shakeAnimation.value * math.pi * 4) * 3,
            0,
          ),
          child: widget.child,
        );

        transformedChild = Container(
          decoration: BoxDecoration(
            boxShadow: _shakeAnimation.value > 0 ? [
              BoxShadow(
                color: ThemeHelper.red()
                    .withValues(alpha: angryShadowBaseAlpha + _shakeAnimation.value * angryShadowMultiplier),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: ThemeHelper.red().withValues(
                    alpha: (angryShadowBaseAlpha - 0.1) + _shakeAnimation.value * (angryShadowMultiplier - 0.1)),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ] : [],
          ),
          child: transformedChild,
        );

        return transformedChild;
      },
    );
  }
}

/// Controller for triggering angry shake animations
class NarwhalAngryController {
  AnimationController? _controller;

  /// Trigger the angry shake animation
  void triggerShake() {
    if (_controller != null) {
      _controller!.reset();
      _controller!.forward().then((_) {
        _controller!.reset();
      });
    }
  }

  /// Internal method to bind the animation controller
  void _bind(AnimationController controller) {
    _controller = controller;
  }

  /// Internal method to unbind the animation controller
  void _unbind() {
    _controller = null;
  }
}
