import 'package:onyxia/export.dart';

final _forbidden = RegExp(r'[*"\\/<>:|?]');

class ItemNameValidationService {
  static String correctTitle(String text) =>
      text.replaceAll(_forbidden, '').replaceAll(RegExp(r'[\r\n]'), '');

  static String? errorMessage(
    List<Artifact> existing,
    String value,
    String excludeId,
  ) {
    // TODO: rename to "validate"
    if (_forbidden.hasMatch(value)) {
      return 'Title cannot contain any of these characters: * " / \\ < > : | ?';
    }
    final stripped = correctTitle(value);
    if (stripped.isNotEmpty &&
        existing.any((e) => e.name == stripped && e.id != excludeId)) {
      return 'An item with this title already exists';
    }
    return null;
  }
}
