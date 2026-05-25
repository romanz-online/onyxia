import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/shell/artifacts_sidebar/providers/rename_artifact_id_provider.dart';
import 'package:speech_balloon/speech_balloon.dart';

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
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _errorMessage = null;
      _isEditing = false;
    });
    _overlayController.hide();
    final newName = _controller.text + (widget.trailingExtension ?? '');
    final error = await ref
        .read(artifactsProvider.notifier)
        .renameItem(widget.item, newName);
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
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: const Offset(0, 9),
        child: Align(
          alignment: Alignment.topCenter,
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: SpeechBalloon(
                nipLocation: NipLocation.top,
                color: ThemeHelper.red500(context),
                borderRadius: 6,
                nipHeight: 8,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    child: Text(
                      _errorMessage ?? '',
                      style: NarwhalTextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
              offset: const Offset(-4, -2),
              child: Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeHelper.neutral200(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: NarwhalTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: ThemeHelper.neutral700(context),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          autofocus: true,
                          onSubmitted: (_) => _saveChanges(),
                          onChanged: (value) {
                            final msg = ItemTitleValidationService.errorMessage(
                                ref.read(artifactsProvider).value ??
                                    const <Artifact>[],
                                value,
                                widget.item.id);
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
                ],
              ),
            )
          : GestureDetector(
              onDoubleTap: startEditing,
              child: widget.trailingExtension == null
                  ? Text(
                      widget.item.name,
                      style: NarwhalTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: ThemeHelper.neutral700(context),
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            _baseName,
                            style: NarwhalTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: ThemeHelper.neutral700(context),
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          widget.trailingExtension!,
                          style: NarwhalTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: ThemeHelper.neutral500(context),
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
