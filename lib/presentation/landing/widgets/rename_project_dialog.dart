import 'package:onyxia/export.dart';

class RenameProjectDialog extends ConsumerStatefulWidget {
  final String projectName;
  final String projectId;

  const RenameProjectDialog({
    super.key,
    required this.projectName,
    required this.projectId,
  });

  @override
  ConsumerState<RenameProjectDialog> createState() =>
      _RenameProjectDialogState();
}

class _RenameProjectDialogState extends ConsumerState<RenameProjectDialog> {
  final TextEditingController _projectNameController = TextEditingController();
  late final FocusNode _popupFocusNode;

  @override
  void initState() {
    super.initState();
    _popupFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _popupFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _projectNameController.text = widget.projectName;

    return NarwhalModalDialog(
      width: 600,
      height: 260,
      title: 'Rename Project',
      content: Focus(
        focusNode: _popupFocusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.enter)
            return KeyEventResult.ignored;

          final String projectName = _projectNameController.text;
          ref
              .read(projectsProvider.notifier)
              .renameProject(widget.projectId, projectName);
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        },
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Project Name',
                    style: NarwhalStyles.modalTextFieldTitleStyle(context),
                  ),
                ],
              ),
              TextFormField(
                maxLength: 50,
                controller: _projectNameController,
                decoration: NarwhalModalInputDecoration.create(
                  context,
                  hintText: 'Rename This Project',
                ),
              ),
            ],
          ),
        ),
      ),
      onCancelPressed: () {
        Navigator.of(context).pop();
      },
      actionButtonText: 'Rename',
      onActionPressed: () {
        final String projectName = _projectNameController.text;
        ref
            .read(projectsProvider.notifier)
            .renameProject(widget.projectId, projectName);
        Navigator.of(context).pop();
      },
    );
  }
}
