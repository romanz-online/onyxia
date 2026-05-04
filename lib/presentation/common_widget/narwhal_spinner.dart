import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NarwhalSpinner extends StatefulWidget {
  final String _assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final double speed; 

  const NarwhalSpinner._(
    this._assetPath, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.speed = 10.0, 
    super.key,
  });

  factory NarwhalSpinner({
    double? width = 80,
    double? height = 80,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    double speed = 10.0,
    Key? key,
  }) {
    return NarwhalSpinner._(
      'assets/lottie/loading/CirclularAnimation.json',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      speed: speed,
      key: key,
    );
  }

  factory NarwhalSpinner.loading({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    double speed = 5.0,
    Key? key,
  }) {
    return NarwhalSpinner._(
      'assets/lottie/loading/NarwhalLoading.json',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      speed: speed,
      key: key,
    );
  }

  factory NarwhalSpinner.logo({
    double? width,
    double? height,
    BoxFit fit = BoxFit.fill,
    Alignment alignment = Alignment.center,
    double speed = 10.0,
    Key? key,
  }) {
    return NarwhalSpinner._(
      'assets/lottie/loading/NarwhalLogo.json',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      speed: speed,
      key: key,
    );
  }

  @override
  State<NarwhalSpinner> createState() => _NarwhalSpinnerState();
}

class _NarwhalSpinnerState extends State<NarwhalSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget._assetPath,
      controller: _controller,
      repeat: true,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      onLoaded: (composition) {
        _controller
          ..duration = composition.duration ~/ widget.speed.toInt()
          ..repeat();
      },
    );
  }
}
