import 'package:onyxia/export.dart';

class VaultMembersTab extends ConsumerStatefulWidget {
  const VaultMembersTab({super.key});

  @override
  ConsumerState<VaultMembersTab> createState() => _VaultMembersTabState();
}

class _VaultMembersTabState extends ConsumerState<VaultMembersTab> {
  final OnyxiaValidatorController _balloon = OnyxiaValidatorController(
    validator: EmailValidationService.errorMessage,
  );

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_balloon.clear);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    _balloon.dispose();
    super.dispose();
  }

  /// Validates the entered email, rejects duplicates, then adds the member.
  void _submit(List<VaultMemberWithUser> entries) {
    final email = _emailController.text.trim().toLowerCase();

    if (!_balloon.validate(email)) {
      _focusNode.requestFocus();
      return;
    }

    if (entries.any((e) => e.user.email.toLowerCase() == email)) {
      _balloon.showError('Already a member');
      _focusNode.requestFocus();
      return;
    }

    _tryAddMember(email);
  }

  Future<void> _tryAddMember(String email) async {
    if (_isProcessing) return;
    final vault = ref.read(selectedVaultProvider);
    if (vault == null) {
      OnyxiaToast.error(text: 'No vault selected');
      return;
    }

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

  Future<void> _removeMember(VaultMember member) async {
    final vault = ref.read(selectedVaultProvider);
    if (vault == null) return;
    try {
      await VaultMembersRepository(vaultId: vault.id).delete(member);
    } catch (_) {
      OnyxiaToast.error(text: 'Could not remove member');
    }
  }

  /// Owners first, then most recently created first (null `createdAt` last).
  List<VaultMemberWithUser> _sorted(List<VaultMemberWithUser> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final aOwner = a.member.role == .owner;
      final bOwner = b.member.role == .owner;
      if (aOwner != bOwner) return aOwner ? -1 : 1;

      final aDate = a.member.createdAt;
      final bDate = b.member.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(vaultMembersWithUsersProvider);
    final isOwner = ref.watch(currentUserRoleProvider) == .owner;

    return entriesAsync.when(
      loading: () => Center(child: OnyxiaLoadingIndicator()),
      error: (e, _) => Text(
        'Failed to load members: $e',
        style: TextStyle(color: ThemeHelper.error()),
      ),
      data: (entries) => _buildContent(isOwner, _sorted(entries)),
    );
  }

  Widget _buildContent(bool isOwner, List<VaultMemberWithUser> entries) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (isOwner) ...[
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: .center,
              spacing: 8,
              children: [
                Expanded(
                  child: OnyxiaValidator(
                    controller: _balloon,
                    child: OnyxiaTextFormField(
                      controller: _emailController,
                      focusNode: _focusNode,
                      enabled: !_isProcessing,
                      hintText: 'Enter email address',
                      // TODO: i wish this would show cached emails like on the login screen
                      keyboardType: .emailAddress,
                      autofocus: true,
                      onSubmitted: (_) => _submit(entries),
                    ),
                  ),
                ),
                if (_isProcessing)
                  const OnyxiaLoadingIndicator()
                else ...[
                  OnyxiaButton(label: 'Add', onPressed: () => _submit(entries)),
                ],
              ],
            ),
          ),
          const Gap(12),
          Divider(height: 1, color: ThemeHelper.auxiliary()),
        ],
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
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _MemberRow(
                    member: entries[i].member,
                    user: entries[i].user,
                    onRemove: () => _removeMember(entries[i].member),
                    isOwner: isOwner,
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
  final VoidCallback onRemove;
  final bool isOwner;

  const _MemberRow({
    required this.member,
    required this.user,
    required this.onRemove,
    required this.isOwner,
  });

  // TODO: switch positions i think. owner/remove on the left, aligned towards a spine, then on the other side of the spine the name/email, also aligned towards the spine

  @override
  Widget build(BuildContext context) {
    final email = user?.email;
    final isGhost = user != null && !user!.isRegistered;
    final name = user == null
        ? null
        : user!.name.isEmpty
        ? null
        : user?.name;

    return HoverBuilder(
      builder: (context, isHovered) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: .all(.circular(4)),
            color: isHovered ? ThemeHelper.background2() : Colors.transparent,
          ),
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
              if (member.role == .owner)
                Text(
                  member.role.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: .w500,
                    color: ThemeHelper.foreground1(),
                  ),
                )
              else if (isOwner)
                OnyxiaIconButton(
                  icon: LucideIcons.userMinus400,
                  iconColor: ThemeHelper.foreground1(),
                  onPressed: onRemove,
                ),
            ],
          ),
        );
      },
    );
  }
}
