import 'package:onyxia/export.dart';

class RenameVaultDialog extends ConsumerStatefulWidget {
  final String vaultName;
  final String vaultId;

  const RenameVaultDialog({
    super.key,
    required this.vaultName,
    required this.vaultId,
  });

  @override
  ConsumerState<RenameVaultDialog> createState() => _RenameVaultDialogState();
}

class _RenameVaultDialogState extends ConsumerState<RenameVaultDialog> {
  final TextEditingController _vaultNameController = TextEditingController();
  late final FocusNode _popupFocusNode;

  @override
  void initState() {
    super.initState();
    _popupFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _vaultNameController.dispose();
    _popupFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _vaultNameController.text = widget.vaultName;

    return NarwhalModalDialog(
      width: 600,
      height: 260,
      title: 'Rename Vault',
      content: Focus(
        focusNode: _popupFocusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.enter)
            return KeyEventResult.ignored;

          ref.read(vaultsProvider.notifier).renameVault(
                widget.vaultId,
                _vaultNameController.text,
              );
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
                    'Vault Name',
                    style: NarwhalStyles.modalTextFieldTitleStyle(context),
                  ),
                ],
              ),
              TextFormField(
                maxLength: 50,
                controller: _vaultNameController,
                decoration: NarwhalModalInputDecoration.create(
                  context,
                  hintText: 'Rename this Vault',
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
        ref.read(vaultsProvider.notifier).renameVault(
              widget.vaultId,
              _vaultNameController.text,
            );
        Navigator.of(context).pop();
      },
    );
  }
}
