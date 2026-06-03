import 'package:onyxia/export.dart';

final _forbidden = RegExp(r'[*"\\/<>:|?]');

class ItemNameValidationService {
  static String correctTitle(String text) =>
      text.replaceAll(_forbidden, '').replaceAll(RegExp(r'[\r\n]'), '');

  /// Returns a human-readable error message or `null` if it's valid
  static String? validate(
    List<Artifact> existing,
    String value,
    String excludeId,
  ) {
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
