import 'package:onyxia/export.dart';
import 'package:speech_balloon/speech_balloon.dart';

// TODO: renaming through this title field makes the artifact reload fully, or it flickers or something. this doesn't happen when renaming through the tree tile, which is completely smooth.

class NoteTitleField extends ConsumerStatefulWidget {
  final FocusNode? nextFocusNode;

  const NoteTitleField({super.key, this.nextFocusNode});

  @override
  ConsumerState<NoteTitleField> createState() => _NoteTitleFieldState();
}

class _NoteTitleFieldState extends ConsumerState<NoteTitleField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  String? _errorMessage;
  ProviderSubscription<Artifact?>? _itemListener;

  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = ref.read(selectedArtifactProvider)?.name ?? '';

      _focusNode.addListener(() async {
        if (_focusNode.hasFocus) {
          _currentTitle = ref.read(selectedArtifactProvider)?.name;
          return;
        }
        final note = ref.read(selectedArtifactProvider);
        if (note == null) return;
        final error = await ref
            .read(artifactsProvider.notifier)
            .renameItem(note, _controller.text);
        if (!mounted) return;
        if (error != null) {
          _controller.text = _currentTitle ?? note.name;
        }
        setState(() => _errorMessage = null);
        _overlayController.hide();
      });

      _itemListener = ref.listenManual(selectedArtifactProvider, (prev, next) {
        if (!_focusNode.hasFocus &&
            next != null &&
            next.name != _controller.text) {
          _controller.text = next.name;
        }
      });
    });
  }

  @override
  void dispose() {
    _itemListener?.close();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          textInputAction: .unspecified,
          onSubmitted: (_) => widget.nextFocusNode?.requestFocus(),
          onChanged: (value) {
            final msg = ItemTitleValidationService.errorMessage(
              ref.read(artifactsProvider).value ?? const <Artifact>[],
              value,
              ref.read(selectedArtifactProvider)?.id ?? '',
            );
            setState(() => _errorMessage = msg);
            if (msg != null) {
              _overlayController.show();
            } else {
              _overlayController.hide();
            }
          },
          style: TextStyle(
            fontSize: 24,
            fontWeight: .w700,
            color: ThemeHelper.foreground1(),
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            hintText: 'Untitled',
            hintStyle: TextStyle(
              fontSize: 28,
              fontWeight: .w700,
              color: ThemeHelper.foreground1().withValues(alpha: 0.4),
            ),
            border: .none,
            contentPadding: .all(4),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
