import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

class ImportVaultDialog extends ConsumerStatefulWidget {
  final List<web.File> files;
  final void Function(Vault vault) onComplete;

  const ImportVaultDialog({
    super.key,
    required this.files,
    required this.onComplete,
  });

  @override
  ConsumerState<ImportVaultDialog> createState() => _ImportVaultDialogState();
}

class _ImportVaultDialogState extends ConsumerState<ImportVaultDialog> {
  final TextEditingController _nameController = TextEditingController();

  bool _importing = false;
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        PortingService.folderNameFromFiles(widget.files) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _importing = true;
      _done = 0;
    });

    final newVault = Vault(name: name);
    await VaultsRepository().add([newVault]);

    await PortingService.importFiles(
      files: widget.files,
      vaultId: newVault.id,
      userId: ref.read(currentUserProvider).value?.id ?? '',
      onProgress: (done, _) {
        if (mounted) setState(() => _done = done);
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onComplete(newVault);
  }

  @override
  Widget build(BuildContext context) {
    if (_importing) {
      return OnyxiaDialog(
        width: 600,
        height: 260,
        title: 'Importing Vault',
        content: Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              ImportProgressView(done: _done, total: widget.files.length),
              const Spacer(),
              Row(
                mainAxisAlignment: .end,
                children: [OnyxiaButton(label: 'Importing...', onTap: null)],
              ),
            ],
          ),
        ),
      );
    }

    return OnyxiaDialog(
      width: 600,
      height: 260,
      title: 'Import Vault',
      content: Expanded(
        child: Column(
          crossAxisAlignment: .start,
          spacing: 10,
          children: [
            Text(
              'Vault Name',
              style: NarwhalStyles.modalTextFieldTitleStyle(context),
            ),
            TextFormField(
              maxLength: 50,
              controller: _nameController,
              autofocus: true,
              decoration: NarwhalModalInputDecoration.create(
                context,
                hintText: 'Enter vault name',
              ),

              style: NarwhalTextStyle(color: ThemeHelper.neutral900(context)),
            ),
            Text(
              'Importing ${widget.files.length} files from folder.',
              style: NarwhalTextStyle(
                fontSize: 12,
                color: ThemeHelper.neutral500(context),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: .end,
              children: [
                OnyxiaButton(label: 'Cancel', onTap: Navigator.of(context).pop),
                const Gap(20),
                OnyxiaButton(label: 'Import', onTap: _startImport),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ImportProgressView extends StatelessWidget {
  final int done;
  final int total;

  const ImportProgressView({
    super.key,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? null : done / total;
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      spacing: 12,
      children: [
        Text(
          'Importing $done / $total files',
          style: NarwhalTextStyle(
            fontSize: 14,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: ThemeHelper.neutral200(context),
          valueColor: AlwaysStoppedAnimation<Color>(
            ThemeHelper.blue500(context),
          ),
        ),
        Text(
          "Please don't close this window until the import is complete.",
          style: NarwhalTextStyle(
            fontSize: 12,
            color: ThemeHelper.neutral500(context),
          ),
        ),
      ],
    );
  }
}
