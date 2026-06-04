part of 'bard_editor.dart';

enum BardBehavior {
  autocomplete, // type in whitespace → insert closing pair
  typeInWord, // type with non-whitespace adjacent → (reserved, no chars use this yet)
  wrapSelection, // type with text selected → wrap selection
  deletePair, // backspace → delete adjacent closing char
  skipClose, // type closing when it's already immediately right → advance cursor
}

class _CharProfile {
  const _CharProfile({
    required this.opening,
    required this.closing,
    required this.behaviors,
    this.triggerLength = 1,
    this.noAdjacentDuplicate = false,
  });

  final String opening;
  final String closing;
  final Set<BardBehavior> behaviors;
  final int triggerLength; // 2 for ~~: fires after second char of opening
  final bool
  noAdjacentDuplicate; // don't fire if same char immediately precedes opening
}

final List<_CharProfile> _kCharRegistry = [
  _CharProfile(
    opening: '(',
    closing: ')',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '[',
    closing: ']',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '{',
    closing: '}',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: "'",
    closing: "'",
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '"',
    closing: '"',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '_',
    closing: '_',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '*',
    closing: '*',
    behaviors: {.autocomplete, .skipClose, .wrapSelection, .deletePair},
    noAdjacentDuplicate: true,
  ),
  _CharProfile(
    opening: '~~',
    closing: '~~',
    behaviors: {.autocomplete, .skipClose},
    triggerLength: 2,
    noAdjacentDuplicate: true,
  ),
  _CharProfile(
    opening: '~',
    closing: '~',
    behaviors: {.wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '=',
    closing: '=',
    behaviors: {.wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: r'$',
    closing: r'$',
    behaviors: {.wrapSelection, .deletePair},
  ),
  _CharProfile(
    opening: '%',
    closing: '%',
    behaviors: {.wrapSelection, .deletePair},
  ),
];

final Map<String, _CharProfile> _profileByOpening = {
  for (final p in _kCharRegistry) p.opening: p,
};

final Map<String, _CharProfile> _profileByClosing = {
  for (final p in _kCharRegistry) p.closing: p,
};

extension _CharBehaviors on _BardEditorState {
  void _dispatchCharEvent(TextEditingValue? prev) {
    if (prev == null) return;
    final curr = _controller.value;
    if (_isSingleCharDelete(prev, curr)) {
      _handleDelete(prev);
      return;
    }
    if (_isSelectionTypeReplace(prev, curr)) {
      _handleTypedWithSelection(prev);
      return;
    }
    if (_isSingleCharInsert(prev, curr)) {
      _handleTypedChar(prev);
      return;
    }
  }

  bool _isSingleCharDelete(TextEditingValue prev, TextEditingValue curr) {
    if (!curr.selection.isCollapsed || !prev.selection.isCollapsed)
      return false;
    final prevCursor = prev.selection.baseOffset;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != prevCursor - 1) return false;
    if (curr.text.length != prev.text.length - 1) return false;
    return curr.text ==
        prev.text.substring(0, curCursor) + prev.text.substring(prevCursor);
  }

  bool _isSelectionTypeReplace(TextEditingValue prev, TextEditingValue curr) {
    if (prev.selection.isCollapsed) return false;
    if (!curr.selection.isCollapsed) return false;
    final selStart = prev.selection.start;
    final selEnd = prev.selection.end;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != selStart + 1) return false;
    if (curr.text.length != prev.text.length - (selEnd - selStart) + 1) {
      return false;
    }
    if (curr.text.substring(0, selStart) != prev.text.substring(0, selStart)) {
      return false;
    }
    if (curr.text.substring(selStart + 1) != prev.text.substring(selEnd)) {
      return false;
    }
    return true;
  }

  bool _isSingleCharInsert(TextEditingValue prev, TextEditingValue curr) {
    if (!curr.selection.isCollapsed || !prev.selection.isCollapsed)
      return false;
    final prevCursor = prev.selection.baseOffset;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != prevCursor + 1) return false;
    return curr.text.length == prev.text.length + 1;
  }

  void _handleTypedWithSelection(TextEditingValue prev) {
    final curr = _controller.value;
    final selStart = prev.selection.start;
    final selEnd = prev.selection.end;
    final typedChar = curr.text[selStart];

    final profile = _profileByOpening[typedChar];
    if (profile == null ||
        !profile.behaviors.contains(BardBehavior.wrapSelection))
      return;

    final selected = prev.text.substring(selStart, selEnd);
    final newText =
        prev.text.substring(0, selStart) +
        profile.opening +
        selected +
        profile.closing +
        prev.text.substring(selEnd);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selStart + profile.opening.length,
        extentOffset: selEnd + profile.opening.length,
      ),
    );
  }

  void _handleTypedChar(TextEditingValue prev) {
    final curr = _controller.value;
    final cursor = curr.selection.baseOffset;
    final text = curr.text;
    final prevCursor = prev.selection.baseOffset;
    final justTyped = text[cursor - 1];

    // skip-close: 2-char profiles (e.g. ~~)
    for (final profile in _kCharRegistry) {
      if (profile.triggerLength != 2 ||
          !profile.behaviors.contains(BardBehavior.skipClose))
        continue;
      if (cursor < 2 || text.substring(cursor - 2, cursor) != profile.opening) {
        continue;
      }
      final cl = profile.closing.length;
      if (prevCursor + cl > prev.text.length) continue;
      if (prev.text.substring(prevCursor, prevCursor + cl) != profile.closing) {
        continue;
      }
      _controller.value = TextEditingValue(
        text: prev.text,
        selection: TextSelection.collapsed(offset: prevCursor + cl),
      );
      return;
    }

    // skip-close: 1-char profiles
    final closeProfile = _profileByClosing[justTyped];
    if (closeProfile != null &&
        closeProfile.triggerLength == 1 &&
        closeProfile.behaviors.contains(BardBehavior.skipClose) &&
        prevCursor < prev.text.length &&
        prev.text[prevCursor] == closeProfile.closing) {
      _controller.value = TextEditingValue(
        text: prev.text,
        selection: TextSelection.collapsed(offset: prevCursor + 1),
      );
      return;
    }

    // find autocomplete profile: 2-char trigger first, then 1-char
    _CharProfile? profile;
    if (cursor >= 2) {
      final twoChar = text.substring(cursor - 2, cursor);
      for (final p in _kCharRegistry) {
        if (p.triggerLength == 2 &&
            p.behaviors.contains(BardBehavior.autocomplete) &&
            p.opening == twoChar) {
          profile = p;
          break;
        }
      }
    }
    if (profile == null) {
      final p = _profileByOpening[justTyped];
      if (p != null &&
          p.triggerLength == 1 &&
          p.behaviors.contains(BardBehavior.autocomplete)) {
        profile = p;
      }
    }
    if (profile == null) return;

    // noAdjacentDuplicate: same char immediately precedes the opening
    if (profile.noAdjacentDuplicate) {
      final checkPos = cursor - profile.triggerLength - 1;
      if (checkPos >= 0 && text[checkPos] == profile.opening[0]) return;
    }

    final leftCheckPos = cursor - profile.triggerLength - 1;
    final leftOk = leftCheckPos < 0 || _isWhitespace(text[leftCheckPos]);
    final rightIsClosing =
        cursor < text.length && text[cursor] == profile.closing[0];
    final rightOk =
        cursor >= text.length || _isWhitespace(text[cursor]) || rightIsClosing;
    if (!rightOk || (!leftOk && !rightIsClosing)) return;

    _insertClosingMarker(cursor, profile.closing);
  }

  void _handleDelete(TextEditingValue prev) {
    final curr = _controller.value;
    final curCursor = curr.selection.baseOffset;

    final deleted = prev.text[curCursor];
    final profile = _profileByOpening[deleted];
    if (profile == null || !profile.behaviors.contains(BardBehavior.deletePair))
      return;

    final closing = profile.closing;
    if (curCursor + closing.length > curr.text.length) return;
    if (curr.text.substring(curCursor, curCursor + closing.length) != closing) {
      return;
    }

    final newText =
        curr.text.substring(0, curCursor) +
        curr.text.substring(curCursor + closing.length);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: curCursor),
    );
  }

  void _insertClosingMarker(int cursor, String marker) {
    final text = _controller.text;
    final newText = text.substring(0, cursor) + marker + text.substring(cursor);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  bool _isWhitespace(String c) =>
      c == ' ' || c == '\t' || c == '\n' || c == '\r';
}
