import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_bard_crdt_engine.dart';
import '_cursor_rebase.dart';
import 'bard_collab_config.dart';
import 'bard_controller.dart';
import 'markdown_span.dart';
import 'wiki_link_overlay.dart';

const Offset _kOverlayOffset = Offset(0, 56);
const double _kOverlayWidth = 280;

// ── Character behavior system ─────────────────────────────────────────────────

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
  final bool noAdjacentDuplicate; // don't fire if same char immediately precedes opening
}

class BardEditor extends StatefulWidget {
  const BardEditor({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.maxLines,
    this.minLines,
    this.onChanged,
    this.availableWikiTargets = const <String>[],
    this.onWikiLinkTapped,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.expands = false,
    this.startCursorAtStart = true,
    this.collab,
  });

  final BardController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final List<String> availableWikiTargets;
  final ValueChanged<String>? onWikiLinkTapped;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool expands;
  final bool startCursorAtStart;

  /// Optional collaboration plumbing. When non-null, the editor instantiates
  /// an internal CRDT engine that mirrors the local controller against
  /// inbound remote ops, and emits outbound ops via [BardCollabConfig.onLocalOp].
  /// When null, the editor behaves identically to its pre-CRDT form.
  final BardCollabConfig? collab;

  @override
  State<BardEditor> createState() => _BardEditorState();
}

class _BardEditorState extends State<BardEditor> {
  late BardController _controller;
  late FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _wikiOverlay;
  List<String> _filteredTargets = [];
  int _wikiSelectedIndex = 0;
  int _wikiQueryStart = -1;

  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _focusFromTap = false;

  TextEditingValue? _prevControllerValue;

  BardCrdtEngine? _engine;
  StreamSubscription<void>? _engineUpdatesSub;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _controller = BardController();
      _ownsController = true;
    } else {
      _controller = widget.controller!;
    }

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }

    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
    _focusNode.onKeyEvent = _onKeyEvent;

    if (widget.collab != null) _attachCollab(widget.collab!);
  }

  void _attachCollab(BardCollabConfig config) {
    final engine = BardCrdtEngine(config);
    _engine = engine;
    _engineUpdatesSub = engine.updates.listen((_) => _applyEngineToController());
    // Sync initial state (snapshot + catch-up ops) into the controller without
    // waiting for the first updates event. addPostFrameCallback so widget
    // build is complete and selection logic in BardController's listener won't
    // misfire on an empty pre-frame value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyEngineToController();
    });
  }

  void _detachCollab() {
    _engineUpdatesSub?.cancel();
    _engineUpdatesSub = null;
    _engine?.dispose();
    _engine = null;
  }

  /// Pulls engine.currentText into _controller with a rebased cursor. Skips
  /// when texts already match (the equality check is the natural guard against
  /// outbound-emission loops) and when an IME composing region is active.
  void _applyEngineToController() {
    final engine = _engine;
    if (engine == null) return;
    final engineText = engine.currentText;
    if (engineText == _controller.text) return;
    if (_controller.value.composing.isValid) return;

    final newSelection = rebaseSelection(
      oldText: _controller.text,
      newText: engineText,
      oldSelection: _controller.selection,
    );
    _controller.value = TextEditingValue(
      text: engineText,
      selection: newSelection,
    );
  }

  /// Pushes any divergence between _controller.text and engine.currentText
  /// into the CRDT via Myers diff. Called after every controller listener
  /// firing on the local-typing path.
  void _syncControllerToEngine() {
    final engine = _engine;
    if (engine == null) return;
    if (engine.currentText == _controller.text) return;
    engine.applyFallbackChange(_controller.text);
  }

  @override
  void didUpdateWidget(BardEditor old) {
    super.didUpdateWidget(old);

    if (widget.collab != old.collab) {
      _detachCollab();
      if (widget.collab != null) _attachCollab(widget.collab!);
    }

    if (widget.controller != old.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      if (widget.controller == null) {
        _controller = BardController();
        _ownsController = true;
      } else {
        _controller = widget.controller!;
        _ownsController = false;
      }
      _controller.addListener(_onControllerChanged);
    }

    if (widget.focusNode != old.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      } else {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      }
      _focusNode.addListener(_onFocusChanged);
      _focusNode.onKeyEvent = _onKeyEvent;
    }
  }

  @override
  void dispose() {
    _detachCollab();
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    _removeWikiOverlay();
    super.dispose();
  }

  // ── Controller listener ──────────────────────────────────────────────────

  void _onControllerChanged() {
    final prev = _prevControllerValue;
    _prevControllerValue = _controller.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dispatchCharEvent(prev);
      _updateWikiOverlay();
      _syncControllerToEngine();
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeWikiOverlay();
      _focusFromTap = false;
      return;
    }

    if (widget.startCursorAtStart && !_focusFromTap) {
      _controller.selection = TextSelection.collapsed(offset: 0);
    }

    _focusFromTap = false;
  }

  // ── Character registry ────────────────────────────────────────────────────

  static final List<_CharProfile> _kCharRegistry = [
    _CharProfile(opening: '(', closing: ')', behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(opening: '[', closing: ']', behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(opening: '{', closing: '}', behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(opening: "'", closing: "'", behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(opening: '"', closing: '"', behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(opening: '_', closing: '_', behaviors: {
      BardBehavior.autocomplete,
      BardBehavior.skipClose,
      BardBehavior.wrapSelection,
      BardBehavior.deletePair
    }),
    _CharProfile(
        opening: '*',
        closing: '*',
        behaviors: {
          BardBehavior.autocomplete,
          BardBehavior.skipClose,
          BardBehavior.wrapSelection,
          BardBehavior.deletePair
        },
        noAdjacentDuplicate: true),
    _CharProfile(
        opening: '~~',
        closing: '~~',
        behaviors: {BardBehavior.autocomplete, BardBehavior.skipClose},
        triggerLength: 2,
        noAdjacentDuplicate: true),
    _CharProfile(opening: '~', closing: '~', behaviors: {BardBehavior.wrapSelection, BardBehavior.deletePair}),
    _CharProfile(opening: '=', closing: '=', behaviors: {BardBehavior.wrapSelection, BardBehavior.deletePair}),
    _CharProfile(opening: r'$', closing: r'$', behaviors: {BardBehavior.wrapSelection, BardBehavior.deletePair}),
    _CharProfile(opening: '%', closing: '%', behaviors: {BardBehavior.wrapSelection, BardBehavior.deletePair}),
  ];

  static final Map<String, _CharProfile> _profileByOpening = {
    for (final p in _kCharRegistry) p.opening: p,
  };

  static final Map<String, _CharProfile> _profileByClosing = {
    for (final p in _kCharRegistry) p.closing: p,
  };

  // ── Char event dispatch ───────────────────────────────────────────────────

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
    if (!curr.selection.isCollapsed || !prev.selection.isCollapsed) return false;
    final prevCursor = prev.selection.baseOffset;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != prevCursor - 1) return false;
    if (curr.text.length != prev.text.length - 1) return false;
    return curr.text == prev.text.substring(0, curCursor) + prev.text.substring(prevCursor);
  }

  bool _isSelectionTypeReplace(TextEditingValue prev, TextEditingValue curr) {
    if (prev.selection.isCollapsed) return false;
    if (!curr.selection.isCollapsed) return false;
    final selStart = prev.selection.start;
    final selEnd = prev.selection.end;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != selStart + 1) return false;
    if (curr.text.length != prev.text.length - (selEnd - selStart) + 1) return false;
    if (curr.text.substring(0, selStart) != prev.text.substring(0, selStart)) return false;
    if (curr.text.substring(selStart + 1) != prev.text.substring(selEnd)) return false;
    return true;
  }

  bool _isSingleCharInsert(TextEditingValue prev, TextEditingValue curr) {
    if (!curr.selection.isCollapsed || !prev.selection.isCollapsed) return false;
    final prevCursor = prev.selection.baseOffset;
    final curCursor = curr.selection.baseOffset;
    if (curCursor != prevCursor + 1) return false;
    return curr.text.length == prev.text.length + 1;
  }

  // ── Typed with selection: wrapSelection ──────────────────────────────────

  void _handleTypedWithSelection(TextEditingValue prev) {
    final curr = _controller.value;
    final selStart = prev.selection.start;
    final selEnd = prev.selection.end;
    final typedChar = curr.text[selStart];

    final profile = _profileByOpening[typedChar];
    if (profile == null || !profile.behaviors.contains(BardBehavior.wrapSelection)) return;

    final selected = prev.text.substring(selStart, selEnd);
    final newText =
        prev.text.substring(0, selStart) + profile.opening + selected + profile.closing + prev.text.substring(selEnd);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selStart + profile.opening.length,
        extentOffset: selEnd + profile.opening.length,
      ),
    );
  }

  // ── Typed char: skipClose + autocomplete ─────────────────────────────────

  void _handleTypedChar(TextEditingValue prev) {
    final curr = _controller.value;
    final cursor = curr.selection.baseOffset;
    final text = curr.text;
    final prevCursor = prev.selection.baseOffset;
    final justTyped = text[cursor - 1];

    // skip-close: 2-char profiles (e.g. ~~)
    for (final profile in _kCharRegistry) {
      if (profile.triggerLength != 2 || !profile.behaviors.contains(BardBehavior.skipClose)) continue;
      if (cursor < 2 || text.substring(cursor - 2, cursor) != profile.opening) continue;
      final cl = profile.closing.length;
      if (prevCursor + cl > prev.text.length) continue;
      if (prev.text.substring(prevCursor, prevCursor + cl) != profile.closing) continue;
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
        if (p.triggerLength == 2 && p.behaviors.contains(BardBehavior.autocomplete) && p.opening == twoChar) {
          profile = p;
          break;
        }
      }
    }
    if (profile == null) {
      final p = _profileByOpening[justTyped];
      if (p != null && p.triggerLength == 1 && p.behaviors.contains(BardBehavior.autocomplete)) {
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
    final rightIsClosing = cursor < text.length && text[cursor] == profile.closing[0];
    final rightOk = cursor >= text.length || _isWhitespace(text[cursor]) || rightIsClosing;
    if (!rightOk || (!leftOk && !rightIsClosing)) return;

    _insertClosingMarker(cursor, profile.closing);
  }

  // ── Backspace: deletePair ─────────────────────────────────────────────────

  void _handleDelete(TextEditingValue prev) {
    final curr = _controller.value;
    final curCursor = curr.selection.baseOffset;

    final deleted = prev.text[curCursor];
    final profile = _profileByOpening[deleted];
    if (profile == null || !profile.behaviors.contains(BardBehavior.deletePair)) return;

    final closing = profile.closing;
    if (curCursor + closing.length > curr.text.length) return;
    if (curr.text.substring(curCursor, curCursor + closing.length) != closing) return;

    final newText = curr.text.substring(0, curCursor) + curr.text.substring(curCursor + closing.length);
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

  bool _isWhitespace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

  bool _isWordBoundary(String c) => _isWhitespace(c) || c == '*' || c == '~';

  // ── Format application (Ctrl+I, Ctrl+B, etc.) ────────────────────────────

  void _applyFormat(MarkdownFormatType type) {
    final selection = _controller.selection;
    if (!selection.isValid) return;

    final marker = _markerFor(type);

    if (selection.isCollapsed) {
      final cursor = selection.baseOffset;
      final existingSpans = _controller.spansAt(cursor).where((s) => s.type == type).toList();

      if (existingSpans.isNotEmpty) {
        final span = existingSpans.first;
        if (cursor == span.contentStart) {
          return; // S5b: cursor at first content position — do nothing
        } else if (cursor == span.contentEnd) {
          _controller.selection = TextSelection.collapsed(offset: span.markerEndClose); // S6: jump
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

      final existingSpans = _controller.spansContaining(start, end).where((s) => s.type == type).toList();

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
      while (ws > 0 && !_isWordBoundary(text[ws - 1])) ws--;
      final newText = text.substring(0, ws) + marker + text.substring(ws, cursor) + marker + text.substring(cursor);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + 2 * ml),
      );
    } else if (leftBound && !rightBound) {
      // S3: word starts at cursor — wrap word forward, cursor at contentStart
      int we = cursor;
      while (we < text.length && !_isWordBoundary(text[we])) we++;
      final newText = text.substring(0, cursor) + marker + text.substring(cursor, we) + marker + text.substring(we);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + ml),
      );
    } else {
      // S4: cursor mid-word — wrap whole word, cursor keeps relative position
      int ws = cursor;
      while (ws > 0 && !_isWordBoundary(text[ws - 1])) ws--;
      int we = cursor;
      while (we < text.length && !_isWordBoundary(text[we])) we++;
      final rel = cursor - ws;
      final newText = text.substring(0, ws) + marker + text.substring(ws, we) + marker + text.substring(we);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: ws + ml + rel),
      );
    }
  }

  void _applyS7(int selStart, int selEnd, String marker, List<MarkdownSpan> partialSpans) {
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
      if (closeStart >= selStart && closeEnd <= selEnd && closeEnd > closeStart) {
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
    final newText = text.substring(0, start) + marker + text.substring(start, end) + marker + text.substring(end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + ml,
        extentOffset: end + ml,
      ),
    );
  }

  String _markerFor(MarkdownFormatType type) {
    switch (type) {
      case MarkdownFormatType.bold:
        return '**';
      case MarkdownFormatType.italic:
        return '*';
      case MarkdownFormatType.strikethrough:
        return '~~';
      case MarkdownFormatType.wikiLink:
        return '[[';
    }
  }

  void _insertMarkerPair(int selStart, int selEnd, String marker) {
    final text = _controller.text;
    final newText =
        text.substring(0, selStart) + marker + text.substring(selStart, selEnd) + marker + text.substring(selEnd);
    _controller.value = TextEditingValue(
      text: newText,
      selection: selStart == selEnd
          ? TextSelection.collapsed(offset: selStart + marker.length)
          : TextSelection(
              baseOffset: selStart + marker.length,
              extentOffset: selEnd + marker.length,
            ),
    );
  }

  void _removeSpanMarkers(MarkdownSpan span) {
    final text = _controller.text;
    final selection = _controller.selection;

    final newText = text.substring(0, span.markerStartOpen) +
        text.substring(span.contentStart, span.contentEnd) +
        text.substring(span.markerEndClose);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: _adjustOffset(selection.baseOffset, span).clamp(0, newText.length),
        extentOffset: _adjustOffset(selection.extentOffset, span).clamp(0, newText.length),
      ),
    );
  }

  int _adjustOffset(int offset, MarkdownSpan span) {
    if (offset <= span.markerStartOpen) return offset;
    if (offset < span.contentStart) return span.markerStartOpen;
    if (offset <= span.contentEnd) return offset - span.openMarkerLen;
    if (offset < span.markerEndClose) return span.contentEnd - span.openMarkerLen;
    return offset - span.openMarkerLen - span.closeMarkerLen;
  }

  // ── Wiki link overlay ─────────────────────────────────────────────────────

  void _updateWikiOverlay() {
    if (!mounted) return;
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      _removeWikiOverlay();
      return;
    }

    // Detect [[query pattern before cursor
    final before = text.substring(0, cursor);
    final match = RegExp(r'\[\[([^\]\n]*)$').firstMatch(before);

    if (match == null) {
      _removeWikiOverlay();
      return;
    }

    _wikiQueryStart = match.start;
    final query = match.group(1)!;
    final filtered = widget.availableWikiTargets.where((t) => t.toLowerCase().contains(query.toLowerCase())).toList();

    if (filtered.isEmpty && query.isNotEmpty) {
      _removeWikiOverlay();
      return;
    }

    _filteredTargets = filtered;
    _wikiSelectedIndex = _wikiSelectedIndex.clamp(0, filtered.isEmpty ? 0 : filtered.length - 1);

    if (_wikiOverlay == null) {
      _showWikiOverlay();
    } else {
      _wikiOverlay!.markNeedsBuild();
    }
  }

  void _showWikiOverlay() {
    final overlay = Overlay.of(context);
    _wikiOverlay = OverlayEntry(builder: (_) => _buildWikiOverlayWidget());
    overlay.insert(_wikiOverlay!);
  }

  void _removeWikiOverlay() {
    _wikiOverlay?.remove();
    _wikiOverlay = null;
    _wikiQueryStart = -1;
    _filteredTargets = [];
    _wikiSelectedIndex = 0;
  }

  Widget _buildWikiOverlayWidget() {
    return Positioned(
      width: _kOverlayWidth,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: _kOverlayOffset,
        child: WikiLinkOverlay(
          query: _wikiQueryStart >= 0
              ? _controller.text
                  .substring(_wikiQueryStart + 2, _controller.selection.baseOffset.clamp(0, _controller.text.length))
              : '',
          filteredTargets: _filteredTargets,
          selectedIndex: _wikiSelectedIndex,
          onSelected: _onWikiTargetSelected,
          onDismiss: _removeWikiOverlay,
        ),
      ),
    );
  }

  void _handleTap() {
    final offset = _controller.selection.baseOffset;
    if (offset < 0) return;
    final wikiSpan = _controller.spansAt(offset).where((s) => s.type == MarkdownFormatType.wikiLink).firstOrNull;
    if (wikiSpan == null) return;
    final title = _controller.text.substring(wikiSpan.contentStart, wikiSpan.contentEnd);
    widget.onWikiLinkTapped?.call(title);
  }

  void _onWikiTargetSelected(String target) {
    if (_wikiQueryStart < 0) return;
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    // Replace [[query with [[target]]
    final newText = text.substring(0, _wikiQueryStart) + '[[$target]]' + text.substring(cursor);
    final newCursor = _wikiQueryStart + target.length + 4; // [[ + target + ]]
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _removeWikiOverlay();
  }

  // ── Keyboard event handling ───────────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Wiki overlay navigation
    if (_wikiOverlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _wikiSelectedIndex = (_wikiSelectedIndex + 1).clamp(0, _filteredTargets.length - 1);
        _wikiOverlay?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _wikiSelectedIndex = (_wikiSelectedIndex - 1).clamp(0, _filteredTargets.length - 1);
        _wikiOverlay?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
        if (_filteredTargets.isNotEmpty) {
          _onWikiTargetSelected(_filteredTargets[_wikiSelectedIndex]);
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeWikiOverlay();
        return KeyEventResult.handled;
      }
    }

    if (!isCtrl) return KeyEventResult.ignored;

    final format = _kFormatHotkeys[(event.logicalKey, isShift)];
    if (format != null) {
      _applyFormat(format);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  static final _kFormatHotkeys = <(LogicalKeyboardKey, bool), MarkdownFormatType>{
    (LogicalKeyboardKey.keyI, false): MarkdownFormatType.italic,
    (LogicalKeyboardKey.keyB, false): MarkdownFormatType.bold,
    (LogicalKeyboardKey.keyX, true): MarkdownFormatType.strikethrough,
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Listener(
        onPointerDown: (_) {
          _focusFromTap = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _focusFromTap = false);
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: widget.decoration,
          style: widget.style,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onTap: _handleTap,
          expands: widget.expands,
        ),
      ),
    );
  }
}
