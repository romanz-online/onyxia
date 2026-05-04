import 'package:onyxia/export.dart';

class NarwhalEditorLinkDialog extends ConsumerStatefulWidget {
  final bool isAddMode;
  final String initialLink;
  final String initialTitle;

  const NarwhalEditorLinkDialog({super.key, required this.isAddMode, this.initialLink = '', this.initialTitle = ''});

  @override
  ConsumerState<NarwhalEditorLinkDialog> createState() => _NarwhalEditorLinkDialogState();
}

class _NarwhalEditorLinkDialogState extends ConsumerState<NarwhalEditorLinkDialog> {
  final TextEditingController _textControllerTitle = TextEditingController();
  final TextEditingController _textControllerLink = TextEditingController();
  bool _allowAdd = false;

  @override
  void initState() {
    super.initState();
    _textControllerLink.text = widget.initialLink;
    _textControllerTitle.text = widget.initialTitle;
    _allowAdd = validLink();
  }

  @override
  void dispose() {
    _textControllerTitle.dispose();
    _textControllerLink.dispose();
    super.dispose();
  }

  bool validLink() {
    return _textControllerLink.text.isNotEmpty;
  }

  void tryUpdateState() {
    var newStateAllowAdd = validLink();
    if (newStateAllowAdd != _allowAdd) {
      setState(() {
        _allowAdd = newStateAllowAdd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NarwhalModalDialog(
      width: 600,
      height: 312,
      title: widget.isAddMode ? 'Add Link' : 'Edit Link',
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8.0, children: [
        Text(
          "Link",
          style: NarwhalStyles.modalTextFieldTitleStyle(context),
        ),
        TextField(
          controller: _textControllerLink,
          onChanged: (_) => tryUpdateState(),
          autofocus: true,
          style: NarwhalTextStyle(color: ThemeHelper.neutral700(context)),
          decoration: NarwhalModalInputDecoration.create(context, hintText: "http://www.ics.com"),
        ),
        Text(
          "Title",
          style: NarwhalStyles.modalTextFieldTitleStyle(context),
        ),
        TextField(
          controller: _textControllerTitle,
          onChanged: (_) => tryUpdateState(),
          autofocus: true,
          style: NarwhalTextStyle(color: ThemeHelper.neutral700(context)),
          decoration: NarwhalModalInputDecoration.create(context, hintText: "Optional Link Title"),
        ),
      ]),
      onCancelPressed: () => Navigator.of(context).pop(),
      actionButtonText: 'Submit',
      onActionPressed: _allowAdd
          ? () {
              Navigator.of(context).pop((_textControllerTitle.text, _textControllerLink.text));
            }
          : null,
    );
  }
}
