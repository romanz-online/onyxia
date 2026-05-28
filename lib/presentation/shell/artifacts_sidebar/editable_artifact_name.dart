import 'package:onyxia/export.dart';
import 'package:speech_balloon/speech_balloon.dart';

final renameArtifactIdProvider =
    NotifierProvider.autoDispose<RenameArtifactIdNotifier, String?>(
      RenameArtifactIdNotifier.new,
    );

class RenameArtifactIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

class EditableArtifactName extends ConsumerStatefulWidget {
  final Artifact item;

  /// When non-null, the tail of [item.name] is split off as a render-only
  /// suffix (e.g. `.png`). The base portion is what gets shown in the
  /// editable text field; on save the suffix is re-appended so the stored
  /// artifact name still ends in the extension.
  final String? trailingExtension;

  const EditableArtifactName({
    super.key,
    required this.item,
    this.trailingExtension,
  });

  @override
  ConsumerState<EditableArtifactName> createState() =>
      EditableArtifactNameState();
}

class EditableArtifactNameState extends ConsumerState<EditableArtifactName> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  String? _errorMessage;

  String get _baseName {
    final ext = widget.trailingExtension;
    if (ext == null || !widget.item.name.endsWith(ext)) {
      return widget.item.name;
    }
    return widget.item.name.substring(0, widget.item.name.length - ext.length);
  }

  void startEditing() {
    _controller.text = _baseName;
    setState(() {
      _isEditing = true;
    });
    Future.microtask(() {
      _focusNode.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _baseName);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveChanges();
      }
    });
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
    _focusNode.unfocus();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _errorMessage = null;
      _isEditing = false;
    });
    _overlayController.hide();
    final error = await ref
        .read(artifactsProvider.notifier)
        .renameItem(widget.item, _controller.text);
    if (!mounted) return;
    if (error != null) {
      _controller.text = _baseName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRenameId = ref.watch(renameArtifactIdProvider);
    if (pendingRenameId == widget.item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(renameArtifactIdProvider.notifier).set(null);
        startEditing();
      });
    }

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
                color: ThemeHelper.red500(),
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
                        color: Colors.white,
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
      child: _isEditing
          ? Transform.translate(
              offset: const Offset(-4, -1),
              child: Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeHelper.neutral800(),
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
                                color: ThemeHelper.neutral300(),
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
              onDoubleTap: startEditing,
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
                        color: ThemeHelper.neutral300(),
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
                        color: ThemeHelper.neutral500(),
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
