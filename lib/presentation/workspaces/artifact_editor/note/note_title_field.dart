import 'package:onyxia/export.dart';

class NoteTitleField extends ConsumerStatefulWidget {
  final FocusNode? nextFocusNode;

  const NoteTitleField({super.key, this.nextFocusNode});

  @override
  ConsumerState<NoteTitleField> createState() => _NoteTitleFieldState();
}

class _NoteTitleFieldState extends ConsumerState<NoteTitleField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final OnyxiaValidatorController _balloon = OnyxiaValidatorController();
  ProviderSubscription<Artifact?>? _itemListener;

  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // TODO: this is allowing me to submit names that are empty or with illegal characters in the validator, even though the error balloon is correctly appearing. it's working correctly in the tree tile.
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
        _balloon.clear();
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
    _balloon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnyxiaValidator(
      controller: _balloon,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        textInputAction: .unspecified,
        onSubmitted: (_) => widget.nextFocusNode?.requestFocus(),
        onChanged: (value) {
          _balloon.showError(
            ItemNameValidationService.errorMessage(
              ref.read(artifactsProvider).value ?? const <Artifact>[],
              value,
              ref.read(selectedArtifactProvider)?.id ?? '',
            ),
          );
        },
        style: TextStyle(
          fontSize: 24,
          fontWeight: .w700,
          color: ThemeHelper.foreground1(),
        ),
        decoration: InputDecoration(
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
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
    );
  }
}
