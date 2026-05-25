part of 'bard_editor.dart';

const Offset _kOverlayOffset = Offset(0, 56);
const double _kOverlayWidth = 280;

extension _WikiOverlay on _BardEditorState {
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
    final filtered = widget.availableWikiTargets
        .where((t) => t.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty && query.isNotEmpty) {
      _removeWikiOverlay();
      return;
    }

    _filteredTargets = filtered;
    _wikiSelectedIndex = _wikiSelectedIndex.clamp(
      0,
      filtered.isEmpty ? 0 : filtered.length - 1,
    );

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
              ? _controller.text.substring(
                  _wikiQueryStart + 2,
                  _controller.selection.baseOffset
                      .clamp(0, _controller.text.length),
                )
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
    final wikiSpan = _controller
        .spansAt(offset)
        .where((s) => s.type == MarkdownFormatType.wikiLink)
        .firstOrNull;
    if (wikiSpan == null) return;
    final title =
        _controller.text.substring(wikiSpan.contentStart, wikiSpan.contentEnd);
    widget.onWikiLinkTapped?.call(title);
  }

  void _onWikiTargetSelected(String target) {
    if (_wikiQueryStart < 0) return;
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    // Replace [[query with [[target]]
    final newText =
        text.substring(0, _wikiQueryStart) + '[[$target]]' + text.substring(cursor);
    final newCursor = _wikiQueryStart + target.length + 4; // [[ + target + ]]
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _removeWikiOverlay();
  }
}
