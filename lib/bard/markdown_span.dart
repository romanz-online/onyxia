enum MarkdownFormatType { bold, italic, strikethrough, wikiLink }

enum LineFormatType {
  bulletList,
  numberedList,
  heading1,
  heading2,
  heading3,
  blockquote,
}

class MarkdownSpan {
  const MarkdownSpan({
    required this.type,
    required this.markerStartOpen,
    required this.contentStart,
    required this.contentEnd,
    required this.markerEndClose,
    required this.isExplicitlyClosed,
  });

  final MarkdownFormatType type;
  final int markerStartOpen;
  final int contentStart;
  final int contentEnd;
  final int markerEndClose;
  final bool isExplicitlyClosed;

  int get openMarkerLen => contentStart - markerStartOpen;
  int get closeMarkerLen =>
      isExplicitlyClosed ? markerEndClose - contentEnd : 0;

  bool containsOffset(int offset) =>
      offset >= markerStartOpen && offset <= markerEndClose;

  bool fullyContainsRange(int start, int end) =>
      markerStartOpen <= start && end <= markerEndClose;

  bool offsetInOpenMarker(int offset) =>
      offset >= markerStartOpen && offset < contentStart;

  bool offsetInCloseMarker(int offset) =>
      isExplicitlyClosed && offset >= contentEnd && offset < markerEndClose;

  bool offsetIsMarker(int offset) =>
      offsetInOpenMarker(offset) || offsetInCloseMarker(offset);

  bool intervalIsOpenMarker(int start, int end) =>
      start >= markerStartOpen && end <= contentStart;

  bool intervalIsCloseMarker(int start, int end) =>
      isExplicitlyClosed && start >= contentEnd && end <= markerEndClose;

  bool intervalIsContent(int start, int end) =>
      start >= contentStart && end <= contentEnd;
}

class LineSpan {
  const LineSpan({
    required this.type,
    required this.lineStart,
    required this.lineEnd,
    required this.markerEnd,
  });

  final LineFormatType type;
  final int lineStart;
  final int lineEnd;
  final int markerEnd;

  bool containsOffset(int offset) => offset >= lineStart && offset <= lineEnd;

  bool intervalIsPrefix(int start, int end) =>
      start >= lineStart && end <= markerEnd;

  bool intervalIsContent(int start, int end) =>
      start >= markerEnd && end <= lineEnd;
}

class MarkdownParseResult {
  const MarkdownParseResult({
    required this.inlineSpans,
    required this.lineSpans,
  });

  final List<MarkdownSpan> inlineSpans;
  final List<LineSpan> lineSpans;

  static const empty = MarkdownParseResult(inlineSpans: [], lineSpans: []);
}
