import 'package:onyxia/export.dart';

class LandingOverlay extends ConsumerStatefulWidget {
  const LandingOverlay({super.key});

  @override
  ConsumerState<LandingOverlay> createState() => _LandingOverlayState();
}

class _LandingOverlayState extends ConsumerState<LandingOverlay> {
  static const double _width = 600;
  static const double _height = 400;
  static const double _leftColumnWidth = 180;

  Offset _position = const Offset(100, 100);
  bool _positionInitialized = false;

  final TextEditingController _newVaultNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _positionInitialized) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        _position = Offset(
          (size.width - _width) / 2,
          (size.height - _height) / 2,
        );
        _positionInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _newVaultNameController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _position = Offset(
        (_position.dx + details.delta.dx).clamp(0, size.width - _width),
        (_position.dy + details.delta.dy).clamp(0, size.height - _height),
      );
    });
  }

  void _navigateToVault(Vault vault) {
    context.go('/vault/${vault.id}/graph');
  }

  void _showNewVaultDialog() {
    _newVaultNameController.clear();
    showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (dialogContext) {
        return NarwhalModalDialog(
          width: 600,
          height: 260,
          title: 'New Vault',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                'Vault Name',
                style: NarwhalStyles.modalTextFieldTitleStyle(dialogContext),
              ),
              TextFormField(
                maxLength: 50,
                controller: _newVaultNameController,
                autofocus: true,
                decoration: NarwhalModalInputDecoration.create(
                  dialogContext,
                  hintText: 'Enter vault name',
                ),
                style: NarwhalTextStyle(),
              ),
            ],
          ),
          onCancelPressed: () => Navigator.of(dialogContext).pop(),
          actionButtonText: 'Create',
          onActionPressed: () {
            final name = _newVaultNameController.text.trim();
            if (name.isEmpty) return;
            final currentUserId = ref.read(currentUserProvider).value?.id ?? '';
            final now = DateTime.now();
            final newVault = Vault(
              id: const Uuid().v4(),
              createdBy: currentUserId,
              createdAt: now,
              updatedAt: now,
              name: name,
            );
            VaultsRepository().add([newVault]);
            Navigator.of(dialogContext).pop();
            _navigateToVault(newVault);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ?? User.initial();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _onPanUpdate,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral100(context),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: ThemeHelper.neutral300(context), width: 2),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.neutral900(context).withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildContent(context, user),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    if (!user.isLogged) return _buildPreAuth(context);

    final vaults = ref.watch(vaultsProvider).value ?? const <Vault>[];

    return Row(
      children: [
        SizedBox(
          width: _leftColumnWidth,
          child: _buildVaultList(context, vaults),
        ),
        VerticalDivider(width: 2, color: ThemeHelper.neutral300(context)),
        Expanded(child: _buildRightColumn(context, user)),
      ],
    );
  }

  Widget _buildPreAuth(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Text(
              'Onyxia',
              style: NarwhalTextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.neutral700(context),
              ),
            ),
            SizedBox(
              width: 320,
              child: AutofillGroup(child: const EmailAuthForm()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultList(BuildContext context, List<Vault> vaults) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Expanded(
            child: vaults.isEmpty
                ? Center(
                    child: Text(
                      'No vaults',
                      style: NarwhalTextStyle(
                        fontSize: 13,
                        color: ThemeHelper.neutral500(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: vaults.length,
                    itemBuilder: (context, index) =>
                        _buildVaultRow(context, vaults[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultRow(BuildContext context, Vault vault) {
    return OnyxiaButton(
      label: vault.name,
      onTap: () {
        final bool isCtrlOrCmd =
            HardwareKeyboard.instance.logicalKeysPressed.intersection({
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlRight,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.metaRight,
        }).isNotEmpty;
        if (isCtrlOrCmd) {
          NavigationContextMenu.openInNewTab(
              NavigationUrlBuilder.buildGraphUrl(vault.id));
        } else {
          _navigateToVault(vault);
        }
      },
    );
  }

  Widget _buildRightColumn(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onyxia',
            style: NarwhalTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.neutral700(context),
            ),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'You are logged in as ${user.email}',
                  style: NarwhalTextStyle(
                    fontSize: 13,
                    color: ThemeHelper.neutral500(context),
                  ),
                ),
              ),
              OnyxiaButton(
                label: 'Sign out',
                onTap: ref.read(currentUserProvider.notifier).signOut,
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OnyxiaButton(label: 'New Vault', onTap: _showNewVaultDialog),
                  OnyxiaButton(label: 'Import Vault'), // TODO: implement
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
