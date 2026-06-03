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
  final OnyxiaValidatorController _validator = OnyxiaValidatorController();
  ProviderSubscription<Artifact?>? _itemListener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = ref.read(selectedArtifactProvider)?.name ?? '';

      _focusNode.addListener(() async {
        if (_focusNode.hasFocus) return;
        final note = ref.read(selectedArtifactProvider);
        if (note == null) return;
        await ref
            .read(artifactsProvider.notifier)
            .renameItem(note, _controller.text);
        if (!mounted) return;
        // Source of truth is the artifact name after the (attempted) rename:
        // a valid edit -> new name, illegal chars -> stripped name,
        // empty/dupe -> unchanged.
        final current = ref.read(selectedArtifactProvider)?.name ?? note.name;
        if (_controller.text != current) _controller.text = current;
        _validator.clear();
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
    _validator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnyxiaValidator(
      controller: _validator,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        textInputAction: .unspecified,
        onSubmitted: (_) => widget.nextFocusNode?.requestFocus(),
        onChanged: (value) {
          _validator.showError(
            ItemNameValidationService.validate(
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
