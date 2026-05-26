import 'package:onyxia/export.dart';

// TODO: get rid of this file

class NarwhalStyles {
  NarwhalStyles._();

  static modalTextFieldTitleStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 14,
      fontWeight: .w600,
      color: ThemeHelper.neutral800(context),
    );
  }

  static dropdownListTextStyle(BuildContext context) {
    return NarwhalTextStyle(
      fontSize: 15,
      fontWeight: .w400,
      color: ThemeHelper.neutral900(context),
    );
  }
}
