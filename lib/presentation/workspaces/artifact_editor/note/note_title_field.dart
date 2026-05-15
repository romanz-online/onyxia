import 'package:onyxia/export.dart';
import 'package:speech_balloon/speech_balloon.dart';

class NoteTitleField extends ConsumerStatefulWidget {
  final NoteStateProvider? provider;
  final FocusNode? nextFocusNode;

  const NoteTitleField({super.key, this.provider, this.nextFocusNode});

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

  String? _titleOnFocusGain;

  NoteStateProvider get _provider =>
      widget.provider ?? selectedNoteStateProvider;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialItem = ref.read(_provider).value?.note;
      _controller.text = initialItem?.name ?? '';

      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          _titleOnFocusGain = ref.read(_provider).value?.note?.name;
        } else {
          final note = ref.read(_provider).value?.note;
          if (note == null) return;
          final error = ref
              .read(artifactsProvider.notifier)
              .renameItem(note, _controller.text);
          if (error != null) {
            _controller.text = _titleOnFocusGain ?? note.name;
          }
          setState(() => _errorMessage = null);
          _overlayController.hide();
        }
      });

      _itemListener = ref.listenManual(
        _provider.select((state) => state.value?.note),
        (prev, next) {
          if (!_focusNode.hasFocus &&
              next != null &&
              next.name != _controller.text) {
            _controller.text = next.name;
          }
        },
      );
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
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          textInputAction: TextInputAction.unspecified,
          onSubmitted: (_) => widget.nextFocusNode?.requestFocus(),
          onChanged: (value) {
            final msg = ItemTitleValidationService.errorMessage(
                ref.read(artifactsProvider).value ?? const <Artifact>[],
                value,
                ref.read(_provider).value?.note?.id ?? '');
            setState(() => _errorMessage = msg);
            if (msg != null) {
              _overlayController.show();
            } else {
              _overlayController.hide();
            }
          },
          style: NarwhalTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ThemeHelper.neutral700(context),
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            hintText: 'Untitled',
            hintStyle: NarwhalTextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ThemeHelper.neutral700(context).withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
