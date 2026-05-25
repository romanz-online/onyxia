import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_bard_crdt_engine.dart';
import '_cursor_rebase.dart';
import 'bard_collab_config.dart';
import 'bard_controller.dart';
import 'markdown_span.dart';
import 'wiki_link_overlay.dart';

part '_char_behaviors.dart';
part '_format_application.dart';
part '_wiki_overlay_controller.dart';

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

  // Wiki overlay state (owned by State; methods live in [_WikiOverlay]).
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

  /// True for the synchronous window during which `_applyEngineToController`
  /// is writing engine text back to the controller. The controller listener
  /// fires during that assignment; it must not turn around and re-sync that
  /// same text to the engine (which would broadcast a new local op whose id
  /// the existing `_recentRemoteIds` guard can't recognize).
  bool _applyingRemote = false;

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
    _applyingRemote = true;
    try {
      _controller.value = TextEditingValue(
        text: engineText,
        selection: newSelection,
      );
    } finally {
      _applyingRemote = false;
    }
  }

  /// Pushes a local edit (computed from the controller's prev→curr diff) into
  /// the CRDT as a typed insert/delete/replace. Diffing against the captured
  /// previous controller value — never against engine.currentText — is what
  /// closes the race: a remote op that lands between this listener fire and
  /// the engine apply can't fool us into producing operations that revert it.
  void _applyLocalEditToEngine(String prevText, String currText) {
    final engine = _engine;
    if (engine == null || prevText == currText) return;
    final shorter =
        prevText.length < currText.length ? prevText.length : currText.length;
    int p = 0;
    while (p < shorter && prevText.codeUnitAt(p) == currText.codeUnitAt(p)) {
      p++;
    }
    int s = 0;
    while (s < shorter - p &&
        prevText.codeUnitAt(prevText.length - 1 - s) ==
            currText.codeUnitAt(currText.length - 1 - s)) {
      s++;
    }
    final removedLen = prevText.length - s - p;
    final inserted = currText.substring(p, currText.length - s);
    if (removedLen == 0 && inserted.isEmpty) return;
    if (removedLen == 0) {
      engine.applyTypedInsert(p, inserted);
    } else if (inserted.isEmpty) {
      engine.applyTypedDelete(p, removedLen);
    } else {
      engine.applyTypedReplace(p, removedLen, inserted);
    }
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

  void _onControllerChanged() {
    final prev = _prevControllerValue;
    final curr = _controller.value;
    _prevControllerValue = curr;
    // Snapshot the remote-apply flag now so the post-frame closure can tell
    // whether this listener fire originated from a remote update — by the
    // time the callback runs, the flag has been reset.
    final wasRemote = _applyingRemote;

    if (prev != null && !wasRemote) {
      _applyLocalEditToEngine(prev.text, curr.text);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!wasRemote) _dispatchCharEvent(prev);
      _updateWikiOverlay();
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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Wiki overlay navigation
    if (_wikiOverlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _wikiSelectedIndex =
            (_wikiSelectedIndex + 1).clamp(0, _filteredTargets.length - 1);
        _wikiOverlay?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _wikiSelectedIndex =
            (_wikiSelectedIndex - 1).clamp(0, _filteredTargets.length - 1);
        _wikiOverlay?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
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
