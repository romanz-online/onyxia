import 'package:onyxia/export.dart';

/// A unified search filter field widget that provides consistent highlighting
/// when text is entered or when hovered, matching the behavior of other filter components.
class NarwhalSearchFilterField extends StatefulWidget {
  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;
  final double width;
  final double height;

  const NarwhalSearchFilterField({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
    this.hint = 'Search',
    this.width = 200,
    this.height = 40,
  });

  @override
  State<NarwhalSearchFilterField> createState() => _NarwhalSearchFilterFieldState();
}

class _NarwhalSearchFilterFieldState extends State<NarwhalSearchFilterField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: HoverBuilder(
        builder: (context, isHovered) {
          final borderColor = ThemeHelper.neutral400(context);
          final hoverBorderColor = ThemeHelper.neutral600(context).withValues(alpha: 0.5);
          final focusBorderColor = ThemeHelper.blue500(context);
          final backgroundColor = ThemeHelper.neutral100(context);
          final hasText = widget.value.isNotEmpty;

          // Priority: focused > hovered > default
          final currentBorderColor = _isFocused ? focusBorderColor : (isHovered ? hoverBorderColor : borderColor);

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: currentBorderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Focus(
              onFocusChange: (focused) {
                setState(() {
                  _isFocused = focused;
                });
              },
              child: SearchTextField(
                controller: widget.controller,
                value: widget.value,
                fillColor: hasText ? ThemeHelper.blue100(context) : backgroundColor,
                onChanged: widget.onChanged,
                onClear: widget.onClear,
                hint: widget.hint,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final InputBorder border;
  final String hint;
  final double height;
  final double width;
  final Color? fillColor;
  final FocusNode? focusNode;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
    required this.border,
    this.hint = 'Search',
    this.height = 30,
    this.width = 300,
    this.fillColor,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hoverColor: Colors.transparent,
          hintText: hint,
          hintStyle: NarwhalTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: ThemeHelper.neutral500(context),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10.0),
            child: const NarwhalIcon(NarwhalIcons.search, size: 10),
          ),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const NarwhalIcon(NarwhalIcons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                )
              : null,
          isDense: true,
          border: border,
          focusedBorder: border,
          enabledBorder: border,
          filled: true,
          fillColor: fillColor ?? ThemeHelper.neutral100(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
        ),
        style: const NarwhalTextStyle(fontSize: 12),
        onChanged: onChanged,
      ),
    );
  }
}
