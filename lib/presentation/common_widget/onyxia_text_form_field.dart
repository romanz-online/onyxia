import 'package:onyxia/export.dart';

class OnyxiaTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLength;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final double? fontSize;

  const OnyxiaTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.maxLength,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLength: maxLength,
      autofocus: autofocus,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: ThemeHelper.accent().withValues(alpha: 0.75),
      style: TextStyle(fontSize: fontSize, color: ThemeHelper.foreground1()),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: ThemeHelper.foreground2().withValues(alpha: 0.7),
        ),
        contentPadding: .fromLTRB(8, 0, 8, 8),
        counter: const SizedBox(),
        fillColor: ThemeHelper.background1(),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeHelper.auxiliary(), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeHelper.foreground2(), width: 1),
        ),
      ),
    );
  }
}
