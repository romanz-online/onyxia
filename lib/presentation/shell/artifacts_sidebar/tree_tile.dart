import 'package:onyxia/export.dart';

// TODO: rename textfield selection bar should be ThemeHelper.accent(). the super tree rename node border is also purple but should be ThemeHelper.accent().

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
  final OnyxiaValidatorController _validator = OnyxiaValidatorController();

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
    _validator.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    _controller.text = _baseName;
    _validator.clear();
    widget.controller.setRenamingNodeId(null);
  }

  Future<void> _saveChanges() async {
    if (_committing) return;
    _committing = true;
    _validator.clear();
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

    if (!_isRenaming) {
      return Row(
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
      );
    }

    return OnyxiaValidator(
      controller: _validator,
      // TODO: OnyxiaValidator needs a maxWidth parameter for its balloon. unbounded it should be intrinsicwidth or whatever but here it should be smaller, like 300px.
      child: Transform.translate(
        offset: const Offset(0, -1),
        child: Row(
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(.space): DoNothingAndStopPropagationIntent(),
                  SingleActivator(.enter): DoNothingAndStopPropagationIntent(),
                  SingleActivator(.arrowUp):
                      DoNothingAndStopPropagationIntent(),
                  SingleActivator(.arrowDown):
                      DoNothingAndStopPropagationIntent(),
                  SingleActivator(.arrowLeft):
                      DoNothingAndStopPropagationIntent(),
                  SingleActivator(.arrowRight):
                      DoNothingAndStopPropagationIntent(),
                  SingleActivator(.home): DoNothingAndStopPropagationIntent(),
                  SingleActivator(.end): DoNothingAndStopPropagationIntent(),
                },
                child: KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == .escape) {
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
                    onTapOutside: (_) => _saveChanges(),
                    onChanged: (value) {
                      _validator.showError(
                        ItemNameValidationService.validate(
                          ref.read(artifactsProvider).value ??
                              const <Artifact>[],
                          value,
                          widget.item.id,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
