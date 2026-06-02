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
    return PopScope(
      canPop: !_importing, // blocks dialog dismissal while importing
      child: OnyxiaDialog(
        width: 500,
        height: 260,
        title: _importing ? 'Importing Vault...' : 'Import Vault',
        content: Expanded(
          child: Padding(
            padding: .all(20),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 10,
              children: [
                if (_importing) ...[
                  ImportProgressView(
                    done: _done,
                    total: widget.files.length,
                    currentFileName: _done > widget.files.length
                        ? 'Done.'
                        : widget.files[_done].name,
                  ),
                ] else ...[
                  Text(
                    'Vault Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: .w600,
                      color: ThemeHelper.foreground1(),
                    ),
                  ),
                  OnyxiaTextFormField(
                    maxLength: 40,
                    controller: _nameController,
                    autofocus: true,
                    hintText: 'Enter vault name',
                    onSubmitted: (_) => _startImport(),
                  ),
                  // Text(
                  //   'Importing ${widget.files.length} files from folder.',
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: ThemeHelper.foreground2(),
                  //   ),
                  // ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: .end,
                    children: [
                      OnyxiaButton(
                        label: 'Cancel',
                        onPressed: Navigator.of(context).pop,
                      ),
                      const Gap(20),
                      OnyxiaButton(label: 'Import', onPressed: _startImport),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImportProgressView extends StatelessWidget {
  final int done;
  final int total;
  final String currentFileName;

  const ImportProgressView({
    super.key,
    required this.done,
    required this.total,
    required this.currentFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      spacing: 12,
      children: [
        Text(
          'Importing: $currentFileName\n($done / $total)',
          style: TextStyle(fontSize: 14, color: ThemeHelper.foreground1()),
        ),
        LinearProgressIndicator(
          value: total == 0 ? null : done / total,
          minHeight: 6,
          backgroundColor: ThemeHelper.background2(),
          valueColor: AlwaysStoppedAnimation<Color>(ThemeHelper.accent()),
        ),
        Text(
          'Keep this window open.',
          style: TextStyle(fontSize: 12, color: ThemeHelper.foreground2()),
        ),
      ],
    );
  }
}
