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

    final email = _emailController.text.trim().toLowerCase();

    setState(() => _isProcessing = true);

    // The RPC adds the member directly. If no account exists for this email
    // yet, it creates a "ghost" user that becomes the real account when that
    // person signs up — so we can add anyone, registered or not.
    try {
      final user = await VaultMembersRepository(
        vaultId: vault.id,
      ).addByEmail(email: email);
      if (!mounted) return;
      OnyxiaToast.show(
        text: user.isRegistered
            ? '$email added to vault'
            : "$email added.\nThey'll join when they sign up.",
        duration: const Duration(seconds: 10),
      );
      _emailController.clear();
    } catch (_) {
      if (!mounted) return;
      OnyxiaToast.error(text: 'Could not add $email');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      // TODO: sort entries so that the most recently created (createdAt) is at the top/start, and then owners always come before everyone else
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
                // TODO: prevent adding emails that are already in the members
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
              :
                // TODO: after adding a new member, the list doesn't automatically refresh
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
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

// TODO: add hover highlight to each row using HoverBuilder, like each theme option in ThemeTab
class _MemberRow extends StatelessWidget {
  final VaultMember member;
  final User? user;

  const _MemberRow({required this.member, required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user?.email;
    final isGhost = user != null && !user!.isRegistered;
    final name = user == null
        ? null
        : user!.name.isEmpty
        ? null
        : user?.name;

    return Padding(
      padding: .symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisAlignment: .start,
              children: [
                if (name != null)
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: .w500,
                      color: isGhost
                          ? ThemeHelper.foreground3()
                          : ThemeHelper.foreground1(),
                      fontStyle: isGhost ? .italic : .normal,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                if (email != null)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isGhost
                          ? ThemeHelper.foreground3()
                          : ThemeHelper.foreground1(),
                      fontStyle: isGhost ? .italic : .normal,
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
                    fontSize: 14,
                    fontWeight: .w500,
                    color: ThemeHelper.foreground1(),
                  ),
                )
              : OnyxiaIconButton(
                  icon: LucideIcons.userMinus400,
                  iconColor: ThemeHelper.foreground1(),
                  onPressed: () => {}, // TODO: implement member removal
                  // TODO: implement some sort of permission system so that non-owners can't remove members from vaults or delete/rename vaults they don't own, add members, etc.
                ),
        ],
      ),
    );
  }
}
