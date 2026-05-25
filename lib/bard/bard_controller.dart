import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:onyxia/presentation/common_widget/narwhal_text_style.dart';
import 'markdown_parser.dart';
import 'markdown_span.dart';

// TODO: integrate visi-links, taking the form ![[...]] which embed the linked item's content beneath the link

// TODO: also integrate ![](link) for non-artifact embeds that have a URL

// TODO: claude did a lot of work here for CRDT and parsing that i haven't checked manually yet. seems to be working but needs to be analyzed for efficiency and coherency

const Color _kMarkerDimColor = Color(0xFF9CA3AF);
const Color _kWikiLinkColor = Colors.orangeAccent;
const Color _kBlockquoteColor = Color(0xFF6B7280);
const double _kHiddenFontSize = 0.0;

class BardController extends TextEditingController {
  BardController({super.text});

  // Tier 1: parse cache — only invalidated when text changes
  String? _cachedText;
  MarkdownParseResult _parseResult = MarkdownParseResult.empty;

  // Tier 2: render cache — invalidated when cursor crosses a span boundary
  // or the base style changes. Pure cursor movement within a "neutral zone"
  // between spans reuses the cached span without rebuilding.
  int _cachedCursorOffset = -1;
  TextSpan? _cachedSpan;
  TextStyle? _cachedBaseStyle;

  /// Sorted offsets at which the per-interval `cursorInAnyOwner` /
  /// `cursorOnLine` checks in [_buildSpanTree] can change their answer. For
  /// inline spans these are `markerStartOpen` and `markerEndClose + 1`; for
  /// line spans, `lineStart` and `lineEnd + 1`. Two offsets that fall in the
  /// same bucket between consecutive boundaries produce identical span trees.
  List<int>? _cursorBoundaries;

  MarkdownParseResult get parseResult => _parseResult;

  List<MarkdownSpan> spansAt(int offset) =>
      _parseResult.inlineSpans.where((s) => s.containsOffset(offset)).toList();

  List<MarkdownSpan> spansContaining(int start, int end) =>
      _parseResult.inlineSpans
          .where((s) => s.fullyContainsRange(start, end))
          .toList();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final val = value;

    if (withComposing && val.composing.isValid) {
      return _buildWithComposing(val, style);
    }

    final cursorOffset = val.selection.isValid ? val.selection.baseOffset : -1;

    // Tier 1: re-parse only when text changes
    if (val.text != _cachedText) {
      _parseResult = parseMarkdown(val.text);
      _cachedText = val.text;
      _cachedCursorOffset = -1; // force Tier 2 rebuild
      _cachedSpan = null;
      _cursorBoundaries = _computeCursorBoundaries(_parseResult);
    }

    // Tier 2: rebuild only when the cursor crosses a span boundary, the
    // base style changes, or we don't have a cached span yet. Pure cursor
    // movement within a single bucket is a no-op.
    final boundaries = _cursorBoundaries!;
    final oldBucket = _bucketOf(_cachedCursorOffset, boundaries);
    final newBucket = _bucketOf(cursorOffset, boundaries);
    if (_cachedSpan == null ||
        style != _cachedBaseStyle ||
        oldBucket != newBucket) {
      _cachedSpan = _buildSpanTree(val.text, _parseResult, cursorOffset, style);
      _cachedBaseStyle = style;
    }
    _cachedCursorOffset = cursorOffset;
    return _cachedSpan!;
  }

  static List<int> _computeCursorBoundaries(MarkdownParseResult r) {
    final set = SplayTreeSet<int>();
    for (final s in r.inlineSpans) {
      set.add(s.markerStartOpen);
      set.add(s.markerEndClose + 1);
    }
    for (final s in r.lineSpans) {
      set.add(s.lineStart);
      set.add(s.lineEnd + 1);
    }
    return set.toList();
  }

  static int _bucketOf(int offset, List<int> sortedBoundaries) {
    int lo = 0, hi = sortedBoundaries.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sortedBoundaries[mid] <= offset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  TextSpan _buildWithComposing(TextEditingValue val, TextStyle? style) {
    final before = val.text.substring(0, val.composing.start);
    final composing =
        val.text.substring(val.composing.start, val.composing.end);
    final after = val.text.substring(val.composing.end);

    return TextSpan(
      style: style,
      children: [
        if (before.isNotEmpty)
          _buildSpanTree(before, parseMarkdown(before), -1, style),
        TextSpan(
          text: composing,
          style: (style ?? const NarwhalTextStyle()).copyWith(
            decoration: TextDecoration.underline,
            backgroundColor: Colors.transparent,
          ),
        ),
        if (after.isNotEmpty)
          _buildSpanTree(after, parseMarkdown(after), -1, style),
      ],
    );
  }

  TextSpan _buildSpanTree(
    String text,
    MarkdownParseResult result,
    int cursorOffset,
    TextStyle? baseStyle,
  ) {
    if (text.isEmpty) return TextSpan(text: text, style: baseStyle);
    if (result.inlineSpans.isEmpty && result.lineSpans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Collect event points where active spans change
    final points = SplayTreeSet<int>()
      ..add(0)
      ..add(text.length);

    for (final s in result.inlineSpans) {
      points.add(s.markerStartOpen);
      if (s.contentStart != s.markerStartOpen) points.add(s.contentStart);
      if (s.contentEnd != s.contentStart) points.add(s.contentEnd);
      if (s.markerEndClose != s.contentEnd) points.add(s.markerEndClose);
    }

    for (final s in result.lineSpans) {
      points.add(s.lineStart);
      if (s.markerEnd != s.lineStart) points.add(s.markerEnd);
      points.add(s.lineEnd);
    }

    final sortedPoints = points.toList();
    final children = <TextSpan>[];

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final start = sortedPoints[i];
      final end = sortedPoints[i + 1];
      if (start >= end || start >= text.length) continue;

      final actualEnd = end.clamp(0, text.length);
      if (start >= actualEnd) continue;

      final intervalText = text.substring(start, actualEnd);

      final activeInline = result.inlineSpans
          .where((s) =>
              s.markerStartOpen <= start && actualEnd <= s.markerEndClose)
          .toList();

      final activeLines = result.lineSpans
          .where((s) => s.lineStart <= start && actualEnd <= s.lineEnd)
          .toList();

      // Classify: is this interval a marker region for any inline span?
      final markerOwners = activeInline
          .where((s) =>
              s.intervalIsOpenMarker(start, actualEnd) ||
              s.intervalIsCloseMarker(start, actualEnd))
          .toList();

      // Is this a line prefix marker?
      final linePrefixOwner = activeLines
          .where((s) => s.intervalIsPrefix(start, actualEnd))
          .firstOrNull;

      final contentSpans = activeInline
          .where((s) => s.intervalIsContent(start, actualEnd))
          .toList();

      final TextStyle intervalStyle;

      if (markerOwners.isNotEmpty) {
        final cursorInAnyOwner = markerOwners.any((s) =>
            cursorOffset >= s.markerStartOpen &&
            cursorOffset <= s.markerEndClose);

        if (cursorInAnyOwner) {
          // Show marker dimly, still apply content styles underneath
          intervalStyle =
              _buildContentStyle(baseStyle, contentSpans, activeLines)
                  .copyWith(color: _kMarkerDimColor);
        } else {
          intervalStyle = const NarwhalTextStyle(
            fontSize: _kHiddenFontSize,
            color: Color(0x00000000),
          );
        }
      } else if (linePrefixOwner != null) {
        final cursorOnLine = cursorOffset >= linePrefixOwner.lineStart &&
            cursorOffset <= linePrefixOwner.lineEnd;

        if (cursorOnLine) {
          intervalStyle =
              _buildContentStyle(baseStyle, contentSpans, activeLines)
                  .copyWith(color: _kMarkerDimColor);
        } else {
          intervalStyle = const NarwhalTextStyle(
            fontSize: _kHiddenFontSize,
            color: Color(0x00000000),
          );
        }
      } else {
        intervalStyle =
            _buildContentStyle(baseStyle, contentSpans, activeLines);
      }

      children.add(TextSpan(text: intervalText, style: intervalStyle));
    }

    if (children.isEmpty) return TextSpan(text: text, style: baseStyle);
    return TextSpan(style: baseStyle, children: children);
  }

  NarwhalTextStyle _buildContentStyle(
    TextStyle? baseStyle,
    List<MarkdownSpan> contentSpans,
    List<LineSpan> lineSpans,
  ) {
    double? fontSize = baseStyle?.fontSize;
    FontWeight? fontWeight = baseStyle?.fontWeight;
    FontStyle? fontStyle = baseStyle?.fontStyle;
    Color? color = baseStyle?.color;
    final fontFamily = baseStyle?.fontFamily ?? 'Segoe UI';
    final decorations = <TextDecoration>[];

    if (baseStyle?.decoration != null &&
        baseStyle!.decoration != TextDecoration.none) {
      decorations.add(baseStyle.decoration!);
    }

    for (final s in lineSpans) {
      switch (s.type) {
        case LineFormatType.heading1:
          fontSize = 24.0;
          fontWeight = FontWeight.bold;
        case LineFormatType.heading2:
          fontSize = 20.0;
          fontWeight = FontWeight.bold;
        case LineFormatType.heading3:
          fontSize = 16.0;
          fontWeight = FontWeight.bold;
        case LineFormatType.bulletList:
        case LineFormatType.numberedList:
          break;
        case LineFormatType.blockquote:
          color = _kBlockquoteColor;
          fontStyle = FontStyle.italic;
      }
    }

    for (final s in contentSpans) {
      switch (s.type) {
        case MarkdownFormatType.bold:
          fontWeight = FontWeight.bold;
        case MarkdownFormatType.italic:
          fontStyle = FontStyle.italic;
        case MarkdownFormatType.strikethrough:
          decorations.add(TextDecoration.lineThrough);
        case MarkdownFormatType.wikiLink:
          color = _kWikiLinkColor;
          decorations.add(TextDecoration.underline);
      }
    }

    final decoration = decorations.isEmpty
        ? null
        : decorations.length == 1
            ? decorations.first
            : TextDecoration.combine(decorations);

    return NarwhalTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle ?? FontStyle.normal,
      color: color,
      fontFamily: fontFamily,
      decoration: decoration,
    );
  }
}
