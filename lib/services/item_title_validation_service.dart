import 'package:onyxia/export.dart';

final _forbidden = RegExp(r'[*"\\/<>:|?]');

class ItemTitleValidationService {
  static String correctTitle(String text) =>
      text.replaceAll(_forbidden, '').replaceAll(RegExp(r'[\r\n]'), '');

  static String? errorMessage(WidgetRef ref, String value, String excludeId) {
    if (_forbidden.hasMatch(value)) {
      return 'Title cannot contain any of these characters: * " / \\ < > : | ?';
    }
    final stripped = correctTitle(value);
    if (stripped.isNotEmpty &&
        (ref.read(artifactsProvider).value ?? const <Artifact>[])
            .any((e) => e.name == stripped && e.id != excludeId)) {
      return 'An item with this title already exists';
    }
    return null;
  }
}
