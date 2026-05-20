import 'package:onyxia/export.dart';

class VaultMembersDialog extends ConsumerStatefulWidget {
  const VaultMembersDialog({super.key});

  @override
  ConsumerState<VaultMembersDialog> createState() => _VaultMembersDialogState();
}

class _VaultMembersDialogState extends ConsumerState<VaultMembersDialog> {
  final TextEditingController _emailController = TextEditingController();
  final Map<String, User> _resolvedUsers = {};
  String _email = '';
  List<String> _resolvedForMemberIds = const [];
  bool _isSending = false;
  String? _generatedLink;
  String? _generatedLinkEmail;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_emailController.text == _email) return;
      setState(() => _email = _emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resolveMissing(List<VaultMember> members) async {
    final missing = members
        .map((m) => m.userId)
        .where((id) => !_resolvedUsers.containsKey(id))
        .toList();
    if (missing.isEmpty) return;

    final lookup = ref.read(userLookupProvider);
    final users = await Future.wait(missing.map(lookup.getUserById));
    if (!mounted) return;

    setState(() {
      for (final u in users) {
        _resolvedUsers[u.id] = u;
      }
      _resolvedForMemberIds = members.map((m) => m.userId).toList();
    });
  }

  bool get _isValidEmail => _email.trim().isNotEmpty && _email.contains('@');

  Future<void> _onSendInvite() async {
    if (!_isValidEmail || _isSending) return;
    final vault = ref.read(selectedVaultProvider);
    if (vault == null) {
      OnyxiaToast.show(text: 'No vault selected.', type: ToastType.error);
      return;
    }
    final me = ref.read(currentUserProvider).value;
    if (me == null) {
      OnyxiaToast.show(text: 'Not signed in.', type: ToastType.error);
      return;
    }
    final email = _email.trim().toLowerCase();

    setState(() => _isSending = true);

    // Branch A: email already belongs to an existing Onyxia user → add directly.
    final existing = await UsersRepository().getByEmail(email);
    if (!mounted) return;

    if (existing != null) {
      await VaultMembersRepository(vaultId: vault.id).add([
        VaultMember(
          vaultId: vault.id,
          userId: existing.id,
          role: UserRole.member,
          createdBy: me.id,
          updatedBy: me.id,
        ),
      ]).then((_) {
        if (!mounted) return;
        OnyxiaToast.show(
          text: '${existing.email} added to vault.',
          type: ToastType.success,
        );
        _emailController.clear();
        setState(() {
          _isSending = false;
          _generatedLink = null;
          _generatedLinkEmail = null;
        });
      });
    }
    // Branch B: not registered → create invitation row + surface copy-link.
    // Generate the UUID client-side (uuid: ^4.5.1 is already a dep) so we don't
    // need a roundtrip to read back the DB-generated token.
    else {
      final token = const Uuid().v4();
      await VaultInvitationsRepository(vaultId: vault.id).add([
        VaultInvitation(
          vaultId: vault.id,
          email: email,
          token: token,
        ),
      ]).then((_) {
        if (!mounted) return;
        setState(() {
          _generatedLink = '${Uri.base.origin}/invite?token=$token';
          _generatedLinkEmail = email;
          _isSending = false;
        });
        _emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(vaultMembersProvider);

    return OnyxiaDialog(
      title: 'Members',
      width: 480,
      height: 480,
      content: membersAsync.when(
        loading: () => Center(child: NarwhalSpinner()),
        error: (e, _) => Text(
          'Failed to load members: $e',
          style: NarwhalTextStyle(color: ThemeHelper.red600(context)),
        ),
        data: (members) => _buildContent(members),
      ),
    );
  }

  Widget _buildContent(List<VaultMember> members) {
    final memberIds = members.map((m) => m.userId).toList();
    if (!_listEquals(memberIds, _resolvedForMemberIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resolveMissing(members);
      });
    }

    final unresolved =
        members.any((m) => !_resolvedUsers.containsKey(m.userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite by email',
          style: NarwhalTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _emailController,
                enabled: !_isSending,
                decoration: NarwhalModalInputDecoration.create(
                  context,
                  hintText: 'invite@example.com',
                ),
                style: NarwhalTextStyle(),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) {
                  if (_isValidEmail) _onSendInvite();
                },
              ),
            ),
            const Gap(8),
            if (_isSending)
              SizedBox(width: 20, height: 20, child: NarwhalSpinner())
            else
              OnyxiaButton(
                label: 'Send',
                onTap: _isValidEmail ? _onSendInvite : null,
              ),
          ],
        ),
        if (_generatedLink != null) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeHelper.neutral200(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite link for $_generatedLinkEmail',
                  style: NarwhalTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral700(context),
                  ),
                ),
                const Gap(6),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generatedLink!,
                        style: NarwhalTextStyle(
                          fontSize: 12,
                          color: ThemeHelper.neutral800(context),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const Gap(8),
                    OnyxiaButton(
                      label: 'Copy',
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _generatedLink!));
                        OnyxiaToast.show(
                          text: 'Link copied.',
                          type: ToastType.success,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const Gap(16),
        Text(
          'Members (${members.length})',
          style: NarwhalTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        const Gap(8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 270),
          child: unresolved && _resolvedUsers.isEmpty
              ? Center(child: NarwhalSpinner())
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: ThemeHelper.neutral300(context),
                  ),
                  itemBuilder: (_, i) => _MemberRow(
                    member: members[i],
                    user: _resolvedUsers[members[i].userId],
                  ),
                ),
        ),
      ],
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _MemberRow extends StatelessWidget {
  final VaultMember member;
  final User? user;

  const _MemberRow({required this.member, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '...';
    final email = user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: NarwhalTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.neutral900(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: NarwhalTextStyle(
                      fontSize: 12,
                      color: ThemeHelper.neutral700(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            member.role.label,
            style: NarwhalTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.neutral700(context),
            ),
          ),
        ],
      ),
    );
  }
}
