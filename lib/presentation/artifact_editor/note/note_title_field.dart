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

  NoteStateProvider get _provider => widget.provider ?? selectedNoteStateProvider;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialItem = ref.read(_provider).value?.note;
      _controller.text = initialItem?.title ?? '';

      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          _titleOnFocusGain = ref.read(_provider).value?.note?.title;
        } else {
          final cleaned = ItemTitleValidationService.correctTitle(_controller.text);
          if (cleaned != _controller.text) _controller.text = cleaned;

          if (ItemTitleValidationService.errorMessage(ref, cleaned, ref.read(_provider).value?.note?.id ?? '') != null) {
            _controller.text = _titleOnFocusGain ?? cleaned;
            setState(() => _errorMessage = null);
            _overlayController.hide();
            return;
          }

          final previousTitle = ref.read(_provider).value?.note?.title;
          ref.read(_provider.notifier).updateTitle(cleaned);

          if (previousTitle != null && cleaned.isNotEmpty && cleaned != previousTitle && context.mounted) {
            final urlSelectedId = GoRouterState.of(context).pathParameters['selectedId'];
            if (urlSelectedId == previousTitle) {
              final projectId = ref.read(projectsProvider.select((s) => s.selectedProject.id));
              context.go('/project/$projectId/$cleaned');
            }
          }
          setState(() => _errorMessage = null);
          _overlayController.hide();
        }
      });

      _itemListener = ref.listenManual(
        _provider.select((state) => state.value?.note),
        (prev, next) {
          if (!_focusNode.hasFocus && next != null && next.title != _controller.text) {
            _controller.text = next.title;
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
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
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
            final msg = ItemTitleValidationService.errorMessage(ref, value, ref.read(_provider).value?.note?.id ?? '');
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
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
