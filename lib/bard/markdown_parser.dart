import 'markdown_span.dart';

enum _TokenType {
  bold,
  italic,
  strikethrough,
  wikilinkOpen,
  wikilinkClose,
  newline,
}

class _Token {
  const _Token(this.type, this.start, this.end);
  final _TokenType type;
  final int start;
  final int end;
}

MarkdownParseResult parseMarkdown(String text) {
  if (text.isEmpty) return .empty;

  final tokens = _tokenize(text);
  final newlinePositions = tokens
      .where((t) => t.type == .newline)
      .map((t) => t.start)
      .toList();

  final inlineSpans = [
    ..._matchSymmetricType(tokens, .bold, .bold, text, newlinePositions),
    ..._matchSymmetricType(tokens, .italic, .italic, text, newlinePositions),
    ..._matchSymmetricType(
      tokens,
      .strikethrough,
      .strikethrough,
      text,
      newlinePositions,
    ),
    ..._matchWikiLinks(tokens, text, newlinePositions),
  ]..sort((a, b) => a.markerStartOpen.compareTo(b.markerStartOpen));

  final lineSpans = _parseLineSpans(text);

  return MarkdownParseResult(inlineSpans: inlineSpans, lineSpans: lineSpans);
}

List<_Token> _tokenize(String text) {
  final tokens = <_Token>[];
  int i = 0;
  while (i < text.length) {
    final c = text[i];
    final next = i + 1 < text.length ? text[i + 1] : null;

    if (c == '*' && next == '*') {
      tokens.add(_Token(.bold, i, i + 2));
      i += 2;
    } else if (c == '*') {
      tokens.add(_Token(.italic, i, i + 1));
      i++;
    } else if (c == '~' && next == '~') {
      tokens.add(_Token(.strikethrough, i, i + 2));
      i += 2;
    } else if (c == '[' && next == '[') {
      tokens.add(_Token(.wikilinkOpen, i, i + 2));
      i += 2;
    } else if (c == ']' && next == ']') {
      tokens.add(_Token(.wikilinkClose, i, i + 2));
      i += 2;
    } else if (c == '\n') {
      tokens.add(_Token(.newline, i, i + 1));
      i++;
    } else {
      i++;
    }
  }
  return tokens;
}

// For bold, italic, strikethrough: the same token type acts as both open and close.
// Each type is matched completely independently.
List<MarkdownSpan> _matchSymmetricType(
  List<_Token> tokens,
  _TokenType tokenType,
  MarkdownFormatType spanType,
  String text,
  List<int> newlinePositions,
) {
  final opens = <_Token>[];
  final spans = <MarkdownSpan>[];

  for (final token in tokens) {
    if (token.type != tokenType) continue;

    if (opens.isEmpty) {
      opens.add(token);
    } else {
      final open = opens.removeLast();
      spans.add(
        MarkdownSpan(
          type: spanType,
          markerStartOpen: open.start,
          contentStart: open.end,
          contentEnd: token.start,
          markerEndClose: token.end,
          isExplicitlyClosed: true,
        ),
      );
    }
  }

  // Auto-close unclosed opens at next \n or end of text
  for (final open in opens) {
    final autoCloseAt =
        _nextNewlineAfter(open.start, newlinePositions) ?? text.length;
    spans.add(
      MarkdownSpan(
        type: spanType,
        markerStartOpen: open.start,
        contentStart: open.end,
        contentEnd: autoCloseAt,
        markerEndClose: autoCloseAt,
        isExplicitlyClosed: false,
      ),
    );
  }

  return spans;
}

List<MarkdownSpan> _matchWikiLinks(
  List<_Token> tokens,
  String text,
  List<int> newlinePositions,
) {
  final opens = <_Token>[];
  final spans = <MarkdownSpan>[];

  for (final token in tokens) {
    if (token.type == .wikilinkOpen) {
      opens.add(token);
    } else if (token.type == .wikilinkClose && opens.isNotEmpty) {
      final open = opens.removeLast();
      spans.add(
        MarkdownSpan(
          type: .wikiLink,
          markerStartOpen: open.start,
          contentStart: open.end,
          contentEnd: token.start,
          markerEndClose: token.end,
          isExplicitlyClosed: true,
        ),
      );
    }
    // Unmatched ]] tokens are silently ignored
  }

  for (final open in opens) {
    final autoCloseAt =
        _nextNewlineAfter(open.start, newlinePositions) ?? text.length;
    spans.add(
      MarkdownSpan(
        type: .wikiLink,
        markerStartOpen: open.start,
        contentStart: open.end,
        contentEnd: autoCloseAt,
        markerEndClose: autoCloseAt,
        isExplicitlyClosed: false,
      ),
    );
  }

  return spans;
}

List<LineSpan> _parseLineSpans(String text) {
  final spans = <LineSpan>[];
  int lineStart = 0;

  while (lineStart <= text.length) {
    final newlineIdx = text.indexOf('\n', lineStart);
    final lineEnd = newlineIdx == -1 ? text.length : newlineIdx;
    final line = text.substring(lineStart, lineEnd);

    final span = _detectLineFormat(line, lineStart, lineEnd);
    if (span != null) spans.add(span);

    if (newlineIdx == -1) break;
    lineStart = newlineIdx + 1;
  }

  return spans;
}

LineSpan? _detectLineFormat(String line, int lineStart, int lineEnd) {
  // Check longer prefixes first to avoid premature matching
  if (line.startsWith('### ')) {
    return LineSpan(
      type: .heading3,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + 4,
    );
  }
  if (line.startsWith('## ')) {
    return LineSpan(
      type: .heading2,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + 3,
    );
  }
  if (line.startsWith('# ')) {
    return LineSpan(
      type: .heading1,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + 2,
    );
  }
  if (line.startsWith('- ') || line.startsWith('* ')) {
    return LineSpan(
      type: .bulletList,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + 2,
    );
  }
  if (line.startsWith('> ')) {
    return LineSpan(
      type: .blockquote,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + 2,
    );
  }
  final numberedMatch = RegExp(r'^\d+\. ').firstMatch(line);
  if (numberedMatch != null) {
    return LineSpan(
      type: .numberedList,
      lineStart: lineStart,
      lineEnd: lineEnd,
      markerEnd: lineStart + numberedMatch.end,
    );
  }
  return null;
}

int? _nextNewlineAfter(int position, List<int> sortedNewlines) {
  for (final nl in sortedNewlines) {
    if (nl > position) return nl;
  }
  return null;
}

List<String> extractWikiLinks(String content) {
  final result = parseMarkdown(content);
  return result.inlineSpans
      .where((s) => s.type == .wikiLink)
      .map((s) => content.substring(s.contentStart, s.contentEnd))
      .toList();
}
