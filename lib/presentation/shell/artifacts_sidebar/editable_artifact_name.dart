import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/shell/artifacts_sidebar/providers/rename_artifact_id_provider.dart';
import 'package:speech_balloon/speech_balloon.dart';

class EditableArtifactName extends ConsumerStatefulWidget {
  final Artifact item;

  const EditableArtifactName({super.key, required this.item});

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

  void startEditing() {
    _controller.text = widget.item.name;
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
    _controller = TextEditingController(text: widget.item.name);

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

  void _saveChanges() {
    setState(() {
      _errorMessage = null;
      _isEditing = false;
    });
    _overlayController.hide();
    final newName =
        ItemTitleValidationService.correctTitle(_controller.text.trim());
    if (newName.isEmpty || newName == widget.item.name) {
      _controller.text = widget.item.name;
      return;
    }
    if (ItemTitleValidationService.errorMessage(ref, newName, widget.item.id) !=
        null) {
      _controller.text = widget.item.name;
      return;
    }
    ref
        .read(artifactsProvider.notifier)
        .updateItem(widget.item.copyWith(name: newName));

    if (context.mounted) {
      final urlSelectedId =
          GoRouterState.of(context).pathParameters['selectedId'];
      if (urlSelectedId == widget.item.name) {
        final projectId =
            ref.read(selectedProjectProvider.select((p) => p?.id));
        context.go(widget.item.navigationUrl(projectId));
      }
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
              offset: Offset(-4, 4),
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
                                ref, value, widget.item.id);
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
              child: Text(
                widget.item.name,
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
    );
  }
}
