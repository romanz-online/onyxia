import 'package:onyxia/export.dart';

// TODO: this doesn't apply just here, but i should get rid of the Onyxia* prefix and instead adopt a method of hiding TextFormField from material.dart in my export.dart so that i can properly fully override and not risk using flutter's native on accident. need to properly weigh the pros and cons and how realistic this is

class OnyxiaTextFormField extends StatelessWidget {
  final TextEditingController? controller;
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
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      autofocus: autofocus,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: TextStyle(
        fontSize: fontSize,
        color: ThemeHelper.neutral900(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: ThemeHelper.neutral500(context).withValues(alpha: 0.7),
        ),
        counter: const SizedBox(),
        fillColor: ThemeHelper.neutral100(context),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ThemeHelper.neutral400(context),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ThemeHelper.neutral600(context),
            width: 1,
          ),
        ),
      ),
    );
  }
}
