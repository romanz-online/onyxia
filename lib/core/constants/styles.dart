import 'package:onyxia/export.dart';

class NarwhalStyles {
  NarwhalStyles._();

  static modalTitleStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: ThemeHelper.neutral800(context),
    );
  }

  static modalLargeTitleStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: ThemeHelper.neutral800(context),
    );
  }

  static modalContentStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: ThemeHelper.neutral800(context),
    );
  }

  static const modalButtonTextStyle = NarwhalTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: NarwhalColors.blue700,
  );

  static const modalDisabledButtonTextStyle = NarwhalTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: NarwhalColors.neutral400,
  );

  static modalTextFieldTitleStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ThemeHelper.neutral800(context),
    );
  }

  static modalTextFieldHintStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ThemeHelper.neutral800(context),
    );
  }

  static modalTextFieldBorderStyle(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
    );
  }

  static modalTextFieldFocusedBorderStyle(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      borderSide:
          BorderSide(color: ThemeHelper.neutral400(context), width: 1.5),
    );
  }

  static modalTextFieldInputHintStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: ThemeHelper.neutral500(context),
    );
  }

  static dropdownListTextStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: ThemeHelper.neutral900(context),
    );
  }

  static dropdownChipTextStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ThemeHelper.blue800(context),
    );
  }
}
