import 'package:onyxia/export.dart';

// TODO: this tile should be 100% uninteractable (except for the text form) when being edited. lots of gestures still make it through to the tile while editing like dragging and clicking

class TreeTile extends ConsumerWidget {
  final TreeNode<Artifact> node;
  final TreeController<Artifact> controller;

  const TreeTile({super.key, required this.node, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeData = ref.watch(
      artifactsProvider.select(
        (async) => (async.value ?? const <Artifact>[]).firstWhere(
          (n) => n.id == node.data.id,
          orElse: () => node.data,
        ),
      ),
    );

    return Container(
      height: 22,
      child: Padding(
        padding: .only(right: 12),
        child: _EditableArtifactName(
          item: nodeData,
          trailingExtension: _imageExt(nodeData),
          controller: controller,
        ),
      ),
    );
  }

  String? _imageExt(Artifact a) {
    if (a is! ImageArtifact) return null;
    final dot = a.name.lastIndexOf('.');
    if (dot <= 0 || dot == a.name.length - 1) return null;
    return a.name.substring(dot + 1).toUpperCase();
  }
}

class _EditableArtifactName extends ConsumerStatefulWidget {
  final Artifact item;

  /// When non-null, the tail of [item.name] is split off as a render-only
  /// suffix (e.g. `.png`). The base portion is what gets shown in the
  /// editable text field; on save the suffix is re-appended so the stored
  /// artifact name still ends in the extension.
  final String? trailingExtension;

  /// Source of truth for rename mode: this node is being renamed when
  /// `controller.renamingNodeId == item.id`. Entering/leaving rename is done
  /// by writing `setRenamingNodeId(...)` back to the controller.
  final TreeController<Artifact> controller;

  const _EditableArtifactName({
    required this.item,
    this.trailingExtension,
    required this.controller,
  });

  @override
  ConsumerState<_EditableArtifactName> createState() =>
      EditableArtifactNameState();
}

class EditableArtifactNameState extends ConsumerState<_EditableArtifactName> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  String? _errorMessage;

  String? _prevRenamingNodeId;
  bool _committing = false;

  bool get _isRenaming => widget.controller.renamingNodeId == widget.item.id;

  String get _baseName {
    final ext = widget.trailingExtension;
    if (ext == null || !widget.item.name.endsWith(ext)) {
      return widget.item.name;
    }
    return widget.item.name.substring(0, widget.item.name.length - ext.length);
  }

  void startEditing() {
    _controller.text = _baseName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isRenaming) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _focusNode.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _baseName);
    _prevRenamingNodeId = widget.controller.renamingNodeId;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isRenaming) {
        _saveChanges();
      }
    });

    if (_isRenaming) startEditing();
  }

  @override
  void didUpdateWidget(_EditableArtifactName oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.controller.renamingNodeId;
    if (current == widget.item.id && _prevRenamingNodeId != widget.item.id) {
      startEditing();
    }
    _prevRenamingNodeId = current;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    _controller.text = _baseName;
    _overlayController.hide();
    setState(() => _errorMessage = null);
    widget.controller.setRenamingNodeId(null);
  }

  Future<void> _saveChanges() async {
    if (_committing) return;
    _committing = true;
    setState(() => _errorMessage = null);
    _overlayController.hide();
    widget.controller.setRenamingNodeId(null);
    final error = await ref
        .read(artifactsProvider.notifier)
        .renameItem(widget.item, _controller.text);
    if (!mounted) return;
    if (error != null) _controller.text = _baseName;
    _committing = false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedArtifactId = ref.watch(selectedArtifactProvider)?.id ?? '';

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: .bottomCenter,
        followerAnchor: .topCenter,
        offset: const Offset(0, 9),
        child: Align(
          alignment: .topCenter,
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: SpeechBalloon(
                nipLocation: .top,
                color: ThemeHelper.error(),
                borderRadius: 6,
                nipHeight: 8,
                width: .infinity,
                height: .infinity,
                child: Center(
                  child: Padding(
                    padding: .symmetric(vertical: 5, horizontal: 12),
                    child: Text(
                      _errorMessage ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeHelper.foreground1(),
                        fontWeight: .w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: _isRenaming
          ? Transform.translate(
              offset: const Offset(0, -1),
              child: Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeHelper.background2(),
                          borderRadius: .circular(4),
                        ),
                        child: Shortcuts(
                          shortcuts: const <ShortcutActivator, Intent>{
                            SingleActivator(LogicalKeyboardKey.space):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.enter):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowUp):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowDown):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowLeft):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowRight):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.home):
                                DoNothingAndStopPropagationIntent(),
                            SingleActivator(LogicalKeyboardKey.end):
                                DoNothingAndStopPropagationIntent(),
                          },
                          child: KeyboardListener(
                            focusNode: _keyboardFocusNode,
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.escape) {
                                _cancelEditing();
                              }
                            },
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .normal,
                                color: ThemeHelper.foreground1(),
                              ),
                              decoration: InputDecoration(
                                border: .none,
                                contentPadding: .zero,
                                isDense: true,
                                fillColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                              ),
                              autofocus: true,
                              onSubmitted: (_) => _saveChanges(),
                              onChanged: (value) {
                                final msg =
                                    ItemTitleValidationService.errorMessage(
                                      ref.read(artifactsProvider).value ??
                                          const <Artifact>[],
                                      value,
                                      widget.item.id,
                                    );
                                setState(() => _errorMessage = msg);
                                if (msg != null) {
                                  _overlayController.show();
                                } else {
                                  _overlayController.hide();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onDoubleTap: () =>
                  widget.controller.setRenamingNodeId(widget.item.id),
              child: Row(
                mainAxisSize: .min,
                mainAxisAlignment: .spaceBetween,
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      _baseName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: .normal,
                        color: widget.item.id == selectedArtifactId
                            ? ThemeHelper.foreground1()
                            : ThemeHelper.foreground2(),
                        letterSpacing: 0.5,
                      ),
                      overflow: .ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (widget.trailingExtension != null)
                    Text(
                      widget.trailingExtension!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: .normal,
                        color: ThemeHelper.foreground3(),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
    );
  }
}
