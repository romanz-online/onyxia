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

  void _rename() {
    ref
        .read(vaultsProvider.notifier)
        .renameVault(widget.vaultId, _vaultNameController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _vaultNameController.text = widget.vaultName;

    return OnyxiaDialog(
      width: 600,
      height: 260,
      title: 'Rename Vault',
      content: Expanded(
        child: Focus(
          focusNode: _popupFocusNode,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return .ignored;
            if (event.logicalKey != .enter) return .ignored;
            _rename();
            return .handled;
          },
          child: Column(
            crossAxisAlignment: .start,
            spacing: 10,
            children: [
              Text(
                'Vault Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: .w600,
                  color: ThemeHelper.neutral200(context),
                ),
              ),
              OnyxiaTextFormField(
                maxLength: 50,
                controller: _vaultNameController,
                hintText: widget.vaultName,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: .end,
                children: [
                  OnyxiaButton(
                    label: 'Cancel',
                    onTap: Navigator.of(context).pop,
                  ),
                  const Gap(20),
                  OnyxiaButton(label: 'Rename', onTap: _rename),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
