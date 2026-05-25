import 'package:onyxia/export.dart';

// TODO: when on any screen but the unauth base screen and vaults list screen, there should be a backwards arro in the top left corner that directs the user back to the unauth base screen

// TODO: "create account" and "forgot password?" should lead to new "screens" rather than just swapping out the email sign in form

enum LandingMode { signIn, invite, resetPassword }

class LandingOverlay extends ConsumerStatefulWidget {
  final LandingMode initialMode;
  final String? inviteToken;
  final String? inviteDestPath;

  const LandingOverlay({
    super.key,
    this.initialMode = LandingMode.signIn,
    this.inviteToken,
    this.inviteDestPath,
  });

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
  final TextEditingController _importVaultNameController =
      TextEditingController();

  // Reset-password mode state.
  final TextEditingController _resetPasswordController =
      TextEditingController();
  final TextEditingController _resetConfirmController = TextEditingController();
  String? _resetError;
  bool _resetSubmitting = false;

  // Invite-mode state.
  Future<Vault?>? _inviteVaultFuture;
  bool _acceptInFlight = false;

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

    if (widget.initialMode == LandingMode.invite) {
      final destVaultId = _extractVaultId(widget.inviteDestPath ?? '');
      if (destVaultId != null) {
        _inviteVaultFuture = VaultsRepository().get(destVaultId);
      }
      // Already-signed-in case: ref.listen won't fire if there's no state
      // transition, so kick the RPC after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.inviteToken == null) return;
        final user = ref.read(currentUserProvider).value;
        if (user != null && user.isLogged) _acceptInvitation();
      });
    }
  }

  @override
  void dispose() {
    _newVaultNameController.dispose();
    _importVaultNameController.dispose();
    _resetPasswordController.dispose();
    _resetConfirmController.dispose();
    super.dispose();
  }

  String? _extractVaultId(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'vault') return segments[1];
    return null;
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

  Future<void> _acceptInvitation() async {
    final token = widget.inviteToken;
    if (token == null || _acceptInFlight) return;
    _acceptInFlight = true;
    try {
      final vaultId = await Supabase.instance.client
          .rpc('accept_vault_invitation', params: {'p_token': token}) as String;
      if (!mounted) return;
      GoRouter.of(context).go('/vault/$vaultId');
    } on PostgrestException catch (e) {
      _acceptInFlight = false;
      throw _humanizeInvitationError(e);
    }
  }

  Future<void> _submitReset() async {
    final password = _resetPasswordController.text;
    if (password.length < 6) {
      setState(() => _resetError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _resetConfirmController.text) {
      setState(() => _resetError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _resetSubmitting = true;
      _resetError = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).updatePassword(password);
      if (!mounted) return;
      context.go(Routes.home);
    } on AuthException catch (e) {
      if (mounted) setState(() => _resetError = e.message);
    } finally {
      if (mounted) setState(() => _resetSubmitting = false);
    }
  }

  Future<void> _showImportVaultDialog() async {
    // TODO: after selecting, this should show a progress bar of uploads that the user has to sit through and after that they're redirected to the vault automatically
    final files = await PortingService.pickFolder();
    if (files.isEmpty || !mounted) return;

    _importVaultNameController.text =
        PortingService.folderNameFromFiles(files) ?? '';

    showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (dialogContext) {
        return NarwhalModalDialog(
          width: 600,
          height: 260,
          title: 'Import Vault',
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
                controller: _importVaultNameController,
                autofocus: true,
                decoration: NarwhalModalInputDecoration.create(
                  dialogContext,
                  hintText: 'Enter vault name',
                ),
                style: NarwhalTextStyle(),
              ),
              Text(
                'Importing ${files.length} files from folder.',
                style: NarwhalTextStyle(
                  fontSize: 12,
                  color: ThemeHelper.neutral500(dialogContext),
                ),
              ),
            ],
          ),
          onCancelPressed: () => Navigator.of(dialogContext).pop(),
          actionButtonText: 'Import',
          onActionPressed: () async {
            final name = _importVaultNameController.text.trim();
            if (name.isEmpty) return;
            final userId = ref.read(currentUserProvider).value?.id ?? '';
            final now = DateTime.now();
            final newVault = Vault(
              id: const Uuid().v4(),
              createdBy: userId,
              createdAt: now,
              updatedAt: now,
              name: name,
            );
            await VaultsRepository().add([newVault]);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            _navigateToVault(newVault);
            // Fire-and-forget: imports stream into the vault as they
            // complete via the realtime channel. Errors surface via the
            // global error handler.
            PortingService.importFiles(
              files: files,
              vaultId: newVault.id,
              userId: userId,
            );
          },
        );
      },
    );
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

    // Invite-mode: kick the accept RPC on the sign-out→sign-in transition.
    if (widget.initialMode == LandingMode.invite &&
        widget.inviteToken != null) {
      ref.listen<AsyncValue<User>>(currentUserProvider, (prev, next) {
        final wasLogged = prev?.value?.isLogged ?? false;
        final nowLogged = next.value?.isLogged ?? false;
        if (!wasLogged && nowLogged) _acceptInvitation();
      });
    }

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
    switch (widget.initialMode) {
      case LandingMode.invite:
        return _buildInvite(context);
      case LandingMode.resetPassword:
        return _buildResetPassword(context);
      case LandingMode.signIn:
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

  Widget _buildInvite(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'Onyxia',
              style: NarwhalTextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.neutral700(context),
              ),
            ),
            FutureBuilder<Vault?>(
              future: _inviteVaultFuture,
              builder: (context, snapshot) {
                final vaultName = snapshot.data?.name;
                final titleText = vaultName != null
                    ? "You've been invited to $vaultName"
                    : "You've been invited to a vault.";
                return Text(
                  titleText,
                  style: NarwhalTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral800(context),
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            Text(
              'Invitations expire 14 days after being sent.',
              style: NarwhalTextStyle(
                fontSize: 13,
                color: ThemeHelper.neutral600(context),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Sign in with your Google account to join.',
              style: NarwhalTextStyle(
                fontSize: 14,
                color: ThemeHelper.neutral600(context),
              ),
              textAlign: TextAlign.center,
            ),
            OnyxiaButton(
              label: 'Sign in with Google',
              onTap: ref.read(currentUserProvider.notifier).signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPassword(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set a new password',
              textAlign: TextAlign.center,
              style: NarwhalTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ThemeHelper.neutral800(context),
              ),
            ),
            const Gap(20),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _resetPasswordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: NarwhalModalInputDecoration.create(
                      context,
                      hintText: 'New password',
                    ),
                    style: NarwhalTextStyle(fontSize: 13),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _resetConfirmController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: NarwhalModalInputDecoration.create(
                      context,
                      hintText: 'Confirm new password',
                    ),
                    style: NarwhalTextStyle(fontSize: 13),
                    onSubmitted: (_) => _submitReset(),
                  ),
                ],
              ),
            ),
            if (_resetError != null) ...[
              const Gap(8),
              Text(
                _resetError!,
                style: NarwhalTextStyle(
                  fontSize: 12,
                  color: ThemeHelper.red600(context),
                ),
              ),
            ],
            const Gap(16),
            Center(
              child: OnyxiaButton(
                label: _resetSubmitting ? '...' : 'Update password',
                onTap: _resetSubmitting ? null : _submitReset,
              ),
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
                  OnyxiaButton(
                    label: 'New Vault',
                    onTap: _showNewVaultDialog,
                  ),
                  OnyxiaButton(
                    label: 'Import Vault',
                    onTap: _showImportVaultDialog,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Exception _humanizeInvitationError(PostgrestException e) {
  final msg = e.message;
  if (msg.contains('invitation_not_found')) {
    return Exception(
        'This invitation has already been used or does not exist.');
  }
  if (msg.contains('invitation_expired')) {
    return Exception(
        'This invitation has expired. Ask the vault owner for a new one.');
  }
  if (msg.contains('invitation_email_mismatch')) {
    return Exception(
        'This invitation was sent to a different email than the one you signed in with.');
  }
  if (msg.contains('unauthenticated')) {
    return Exception('You need to be signed in to accept an invitation.');
  }
  return Exception('Could not accept invitation: $msg');
}
