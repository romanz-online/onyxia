import 'package:onyxia/export.dart';

class OnyxiaScrollView extends StatefulWidget {
  final Widget child;
  const OnyxiaScrollView({super.key, required this.child});

  @override
  State<OnyxiaScrollView> createState() => _OnyxiaScrollViewState();
}

class _OnyxiaScrollViewState extends State<OnyxiaScrollView> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      thumbColor: Theme.of(
        context,
      ).scrollbarTheme.thumbColor?.resolve({WidgetState.hovered}),
      radius: Theme.of(context).scrollbarTheme.radius ?? .circular(4),
      thickness: 6,
      fadeDuration: .zero, // thumb is persistent and doesn't disappear
      timeToFade: .zero,
      child: SingleChildScrollView(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}
