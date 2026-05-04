import 'package:onyxia/export.dart';

class BasicTextInputBox extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final bool enabled;
  final double height;
  final InputDecoration? customDecoration;
  final bool showClearButton;
  final VoidCallback? onClearPressed;
  final BorderRadius borderRadius;
  final OutlineInputBorder? border;
  final OutlineInputBorder? focusedBorder;
  final FocusNode? focusNode;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;

  const BasicTextInputBox({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.hintText,
    this.hintStyle,
    this.style,
    this.enabled = true,
    this.height = 24,
    this.customDecoration,
    this.showClearButton = false,
    this.onClearPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.border,
    this.focusedBorder,
    this.focusNode,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical,
    this.contentPadding,
  });

  @override
  State<BasicTextInputBox> createState() => _BasicTextInputBoxState();
}

class _BasicTextInputBoxState extends State<BasicTextInputBox> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.showClearButton && widget.controller != null) {
      widget.controller!.addListener(_onTextChanged);
      _hasText = widget.controller!.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    if (widget.showClearButton && widget.controller != null) {
      widget.controller!.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller!.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _defaultClearPressed() {
    widget.controller?.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorder = widget.border ??
        OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: ThemeHelper.neutral400(context),
            width: 1,
          ),
        );

    final defaultFocusedBorder = widget.focusedBorder ??
        OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: ThemeHelper.accentColor(),
            width: 1,
          ),
        );

    return TextField(
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      textAlignVertical: TextAlignVertical.center,
      controller: widget.controller,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      style: widget.style ??
          NarwhalTextStyle(
            color: ThemeHelper.neutral700(context),
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
      cursorColor: ThemeHelper.accentColor(),
      decoration: widget.customDecoration ??
          InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle ??
                NarwhalTextStyle(
                  color: ThemeHelper.neutral500(context),
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w400,
                ),
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 8),
            filled: false,
            border: defaultBorder,
            enabledBorder: defaultBorder,
            disabledBorder: defaultBorder,
            errorBorder: defaultBorder,
            focusedBorder: defaultFocusedBorder,
            suffixIcon: widget.showClearButton && _hasText
                ? GestureDetector(
                    onTap: widget.onClearPressed ?? _defaultClearPressed,
                    child: NarwhalIcon(
                      NarwhalIcons.close,
                      size: 14,
                      color: ThemeHelper.neutral500(context),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
    );
  }
}
