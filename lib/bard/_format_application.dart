part of 'bard_editor.dart';

extension _Format on _BardEditorState {
  void _applyFormat(MarkdownFormatType type) {
    final selection = _controller.selection;
    if (!selection.isValid) return;

    final marker = _markerFor(type);

    if (selection.isCollapsed) {
      final cursor = selection.baseOffset;
      final existingSpans = _controller
          .spansAt(cursor)
          .where((s) => s.type == type)
          .toList();

      if (existingSpans.isNotEmpty) {
        final span = existingSpans.first;
        if (cursor == span.contentStart) {
          return; // S5b: cursor at first content position — do nothing
        } else if (cursor == span.contentEnd) {
          _controller.selection = .collapsed(
            offset: span.markerEndClose,
          ); // S6: jump
        } else {
          _removeSpanMarkers(span); // S5a: remove markers
        }
      } else {
        _applySmartWordWrap(cursor, marker); // S1–S4
      }
    } else {
      final start = selection.start;
      final end = selection.end;

      // S7: partial overlap — marker chars of this type fall inside selection
      final partialSpans = _controller.parseResult.inlineSpans
          .where((s) => s.type == type)
          .where((s) => !s.fullyContainsRange(start, end))
          .where((s) => s.markerStartOpen < end && s.markerEndClose > start)
          .toList();

      if (partialSpans.isNotEmpty) {
        _applyS7(start, end, marker, partialSpans);
        return;
      }

      final existingSpans = _controller
          .spansContaining(start, end)
          .where((s) => s.type == type)
          .toList();

      if (existingSpans.isNotEmpty) {
        _removeSpanMarkers(existingSpans.first); // S9
      } else {
        _insertMarkerPair(start, end, marker); // S8
      }
    }
  }

  void _applySmartWordWrap(int cursor, String marker) {
    final text = _controller.text;
    final ml = marker.length;

    final leftBound = cursor == 0 || _isWordBoundary(text[cursor - 1]);
    final rightBound = cursor >= text.length || _isWordBoundary(text[cursor]);

    if (leftBound && rightBound) {
      // S1: both sides boundary — insert empty pair, cursor between markers
      _insertMarkerPair(cursor, cursor, marker);
    } else if (!leftBound && rightBound) {
      // S2: word ends at cursor — wrap word backward, cursor at markerEndClose
      int ws = cursor;
      while (ws > 0 && !_isWordBoundary(text[ws - 1])) {
        ws--;
      }
      final newText =
          text.substring(0, ws) +
          marker +
          text.substring(ws, cursor) +
          marker +
          text.substring(cursor);
      _controller.value = TextEditingValue(
        text: newText,
        selection: .collapsed(offset: cursor + 2 * ml),
      );
    } else if (leftBound && !rightBound) {
      // S3: word starts at cursor — wrap word forward, cursor at contentStart
      int we = cursor;
      while (we < text.length && !_isWordBoundary(text[we])) {
        we++;
      }
      final newText =
          text.substring(0, cursor) +
          marker +
          text.substring(cursor, we) +
          marker +
          text.substring(we);
      _controller.value = TextEditingValue(
        text: newText,
        selection: .collapsed(offset: cursor + ml),
      );
    } else {
      // S4: cursor mid-word — wrap whole word, cursor keeps relative position
      int ws = cursor;
      while (ws > 0 && !_isWordBoundary(text[ws - 1])) {
        ws--;
      }
      int we = cursor;
      while (we < text.length && !_isWordBoundary(text[we])) {
        we++;
      }
      final rel = cursor - ws;
      final newText =
          text.substring(0, ws) +
          marker +
          text.substring(ws, we) +
          marker +
          text.substring(we);
      _controller.value = TextEditingValue(
        text: newText,
        selection: .collapsed(offset: ws + ml + rel),
      );
    }
  }

  void _applyS7(
    int selStart,
    int selEnd,
    String marker,
    List<MarkdownSpan> partialSpans,
  ) {
    // Collect marker byte-ranges that lie fully within [selStart, selEnd)
    final ranges = <(int, int)>[];
    for (final span in partialSpans) {
      final openStart = span.markerStartOpen;
      final openEnd = span.contentStart;
      final closeStart = span.contentEnd;
      final closeEnd = span.markerEndClose;
      if (openStart >= selStart && openEnd <= selEnd && openEnd > openStart) {
        ranges.add((openStart, openEnd));
      }
      if (closeStart >= selStart &&
          closeEnd <= selEnd &&
          closeEnd > closeStart) {
        ranges.add((closeStart, closeEnd));
      }
    }

    // Remove ranges from highest to lowest to preserve lower offsets
    ranges.sort((a, b) => b.$1.compareTo(a.$1));

    var text = _controller.text;
    var start = selStart;
    var end = selEnd;

    for (final (rStart, rEnd) in ranges) {
      text = text.substring(0, rStart) + text.substring(rEnd);
      final removed = rEnd - rStart;
      if (rStart < start) start -= removed;
      if (rStart < end) end -= removed;
    }

    // Re-wrap adjusted [start, end) with marker
    final ml = marker.length;
    final newText =
        text.substring(0, start) +
        marker +
        text.substring(start, end) +
        marker +
        text.substring(end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: start + ml, extentOffset: end + ml),
    );
  }

  String _markerFor(MarkdownFormatType type) => switch (type) {
    .bold => '**',
    .italic => '*',
    .strikethrough => '~~',
    .wikiLink => '[[',
  };

  void _insertMarkerPair(int selStart, int selEnd, String marker) {
    final text = _controller.text;
    final newText =
        text.substring(0, selStart) +
        marker +
        text.substring(selStart, selEnd) +
        marker +
        text.substring(selEnd);
    _controller.value = TextEditingValue(
      text: newText,
      selection: selStart == selEnd
          ? .collapsed(offset: selStart + marker.length)
          : TextSelection(
              baseOffset: selStart + marker.length,
              extentOffset: selEnd + marker.length,
            ),
    );
  }

  void _removeSpanMarkers(MarkdownSpan span) {
    final text = _controller.text;
    final selection = _controller.selection;

    final newText =
        text.substring(0, span.markerStartOpen) +
        text.substring(span.contentStart, span.contentEnd) +
        text.substring(span.markerEndClose);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: _adjustOffset(
          selection.baseOffset,
          span,
        ).clamp(0, newText.length),
        extentOffset: _adjustOffset(
          selection.extentOffset,
          span,
        ).clamp(0, newText.length),
      ),
    );
  }

  int _adjustOffset(int offset, MarkdownSpan span) {
    if (offset <= span.markerStartOpen) return offset;
    if (offset < span.contentStart) return span.markerStartOpen;
    if (offset <= span.contentEnd) return offset - span.openMarkerLen;
    if (offset < span.markerEndClose) {
      return span.contentEnd - span.openMarkerLen;
    }
    return offset - span.openMarkerLen - span.closeMarkerLen;
  }

  bool _isWordBoundary(String c) => _isWhitespace(c) || c == '*' || c == '~';
}
