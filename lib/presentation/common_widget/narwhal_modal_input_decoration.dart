import 'package:onyxia/export.dart';

class NarwhalModalInputDecoration {
  static InputDecoration create(
    BuildContext context, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: NarwhalTextStyle(
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
    );
  }
}
