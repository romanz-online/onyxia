import 'package:onyxia/export.dart';
import 'dart:async';

class NewVaultDialog extends ConsumerStatefulWidget {
  const NewVaultDialog();

  @override
  ConsumerState<NewVaultDialog> createState() => NewVaultDialogState();
}

class NewVaultDialogState extends ConsumerState<NewVaultDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    final newVault = Vault(name: name);
    await VaultsRepository().add([newVault]);
    await _waitForVaultInProvider(newVault.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    navigatorKey.currentContext?.go(Routes.vaultUrl(newVault.id));
  }

  Future<void> _waitForVaultInProvider(String id) {
    final completer = Completer<void>();
    late ProviderSubscription sub;
    sub = ref.listenManual<AsyncValue<List<Vault>>>(vaultsProvider, (_, next) {
      if ((next.value?.any((v) => v.id == id) ?? false) &&
          !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .whenComplete(sub.close);
  }

  @override
  Widget build(BuildContext context) {
    return OnyxiaDialog(
      width: 500,
      height: 260,
      title: _creating ? 'Creating Vault...' : 'New Vault',
      content: Expanded(
        child: Padding(
          padding: .all(20),
          child: _creating
              ? Center(child: const OnyxiaLoadingIndicator())
              : Column(
                  crossAxisAlignment: .start,
                  spacing: 10,
                  children: [
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
                      onSubmitted: (_) => _create(),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: .end,
                      children: [
                        OnyxiaButton(
                          label: 'Cancel',
                          onPressed: Navigator.of(context).pop,
                        ),
                        const Gap(20),
                        OnyxiaButton(label: 'Create', onPressed: _create),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
