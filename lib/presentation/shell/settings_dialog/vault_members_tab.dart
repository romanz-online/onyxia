import 'package:onyxia/export.dart';

class VaultMembersTab extends ConsumerStatefulWidget {
  const VaultMembersTab({super.key});

  @override
  ConsumerState<VaultMembersTab> createState() => _VaultMembersTabState();
}

class _VaultMembersTabState extends ConsumerState<VaultMembersTab> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_overlayController.hide);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    final email = _emailController.text.trim().toLowerCase();
    final msg = EmailValidationService.errorMessage(email);

    if (msg == null) {
      _overlayController.hide();
    } else {
      setState(() => _errorMessage = msg);
      _overlayController.show();
      _focusNode.requestFocus();
    }

    return msg == null;
  }

  Future<void> _tryAddMember() async {
    if (_isProcessing) return;
    final vault = ref.read(selectedVaultProvider);
    if (vault == null) {
      OnyxiaToast.error(text: 'No vault selected');
      return;
    }
    final me = ref.read(currentUserProvider).value;
    if (me == null) {
      OnyxiaToast.error(text: 'Not signed in');
      return;
    }

    final email = _emailController.text.trim().toLowerCase();

    setState(() => _isProcessing = true);

    final existing = await UsersRepository().getByEmail(email);
    if (!mounted) return;

    if (existing != null) {
      // email already belongs to an existing Onyxia user so add them directly
      await VaultMembersRepository(vaultId: vault.id)
          .add([
            VaultMember(
              vaultId: vault.id,
              userId: existing.id,
              role: .member,
              createdBy: me.id,
              updatedBy: me.id,
            ),
          ])
          .then((_) {
            OnyxiaToast.show(text: '${existing.email} added to vault');
            _emailController.clear();
            setState(() {
              _isProcessing = false;
            });
          });
    } else {
      // TODO: this should just create a ghost account that will be added to the vault members, and once the user actually logs in for the first time they'll fill in their password etc. and see that they're already a part of a vault. this might mean i need to stop using the real "users" table and start mirroring it into my own table where i can keep additional information. unsure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(vaultMembersWithUsersProvider);

    return entriesAsync.when(
      loading: () => Center(child: OnyxiaLoadingIndicator()),
      error: (e, _) => Text(
        'Failed to load members: $e',
        style: TextStyle(color: ThemeHelper.error()),
      ),
      data: (entries) => _buildContent(entries),
    );
  }

  Widget _buildContent(List<VaultMemberWithUser> entries) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: .center,
            spacing: 8,
            children: [
              Expanded(
                child:
                    // TODO: turn this error speech balloon into a reusable widget. i'm already duplicating code three times and will probably need it more. it should take a validator as an arg which is just a service or function that returns a String? error message. should be as configurable as OnyxiaTooltip
                    OverlayPortal(
                      controller: _overlayController,
                      overlayChildBuilder: (context) =>
                          CompositedTransformFollower(
                            link: _layerLink,
                            targetAnchor: .bottomCenter,
                            followerAnchor: .topCenter,
                            offset: const Offset(0, 9),
                            child: Align(
                              alignment: .topCenter,
                              child: IntrinsicWidth(
                                child: IntrinsicHeight(
                                  child: SpeechBalloon(
                                    nipLocation: .top,
                                    color: ThemeHelper.error(),
                                    borderRadius: 6,
                                    nipHeight: 8,
                                    width: .infinity,
                                    height: .infinity,
                                    child: Center(
                                      child: Padding(
                                        padding: .symmetric(
                                          vertical: 5,
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          _errorMessage ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: ThemeHelper.foreground1(),
                                            fontWeight: .w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      child: CompositedTransformTarget(
                        link: _layerLink,
                        child: OnyxiaTextFormField(
                          controller: _emailController,
                          focusNode: _focusNode,
                          enabled: !_isProcessing,
                          hintText: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                          autofocus: true,
                          onSubmitted: (_) {
                            if (_validateEmail()) _tryAddMember();
                          },
                        ),
                      ),
                    ),
              ),
              if (_isProcessing)
                const OnyxiaLoadingIndicator()
              else ...[
                OnyxiaButton(
                  label: 'Add',
                  onPressed: () {
                    if (_validateEmail()) _tryAddMember();
                  },
                ),
              ],
            ],
          ),
        ),
        const Gap(12),
        Divider(height: 1, color: ThemeHelper.auxiliary()),
        // Member list
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: .symmetric(vertical: 24),
                    child: Text(
                      'No members yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeHelper.foreground1(),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: ThemeHelper.auxiliary()),
                  itemBuilder: (_, i) => _MemberRow(
                    member: entries[i].member,
                    user: entries[i].user,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final VaultMember member;
  final User? user;

  const _MemberRow({required this.member, required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';

    return Padding(
      padding: .symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  user?.name ?? '...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: .w500,
                    color: ThemeHelper.foreground1(),
                  ),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.foreground1(),
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
              ],
            ),
          ),
          member.role == .owner
              ? Text(
                  member.role.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: .w500,
                    color: ThemeHelper.foreground1(),
                  ),
                )
              : OnyxiaIconButton(
                  icon: LucideIcons.userMinus400,
                  iconColor: ThemeHelper.foreground1(),
                  onPressed: () => {}, // TODO: implement member removal
                ),
        ],
      ),
    );
  }
}
