import 'package:onyxia/export.dart';

class HoverBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  const HoverBuilder({
    super.key,
    required this.builder,
    this.onHoverEnter,
    this.onHoverExit,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverExit?.call();
      },
      hitTestBehavior: .translucent,
      child: widget.builder(context, _isHovered),
    );
  }
}
