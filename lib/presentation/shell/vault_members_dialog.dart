import 'package:onyxia/export.dart';

class VaultMembersDialog extends ConsumerStatefulWidget {
  const VaultMembersDialog({super.key});

  @override
  ConsumerState<VaultMembersDialog> createState() => _VaultMembersDialogState();
}

class _VaultMembersDialogState extends ConsumerState<VaultMembersDialog> {
  final TextEditingController _emailController = TextEditingController();
  String _email = '';
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
      await VaultInvitationsRepository(vaultId: vault.id)
          .add([VaultInvitation(vaultId: vault.id, email: email, token: token)])
          .then((_) {
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
    final entriesAsync = ref.watch(vaultMembersWithUsersProvider);

    return OnyxiaDialog(
      title: 'Members',
      width: 480,
      height: 480,
      content: entriesAsync.when(
        loading: () => Expanded(child: Center(child: OnyxiaLoadingIndicator())),
        error: (e, _) => Text(
          'Failed to load members: $e',
          style: TextStyle(color: ThemeHelper.error()),
        ),
        data: (entries) => _buildContent(entries),
      ),
    );
  }

  Widget _buildContent(List<VaultMemberWithUser> entries) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'Invite by email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: .w600,
            color: ThemeHelper.foreground1(),
          ),
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: .center,
          spacing: 8,
          children: [
            Expanded(
              child: OnyxiaTextFormField(
                controller: _emailController,
                enabled: !_isSending,
                hintText: 'invite@example.com',
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) {
                  if (_isValidEmail) _onSendInvite();
                },
              ),
            ),
            if (_isSending)
              SizedBox(width: 20, height: 20, child: OnyxiaLoadingIndicator())
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
            padding: .all(12),
            decoration: BoxDecoration(
              color: ThemeHelper.background2(),
              borderRadius: .circular(8),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'Invite link for $_generatedLinkEmail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: .w600,
                    color: ThemeHelper.foreground1(),
                  ),
                ),
                const Gap(6),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generatedLink!,
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.foreground1(),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    OnyxiaButton(
                      label: 'Copy',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _generatedLink!));
                        OnyxiaToast.show(text: 'Link copied.', type: .success);
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
          'Members (${entries.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: .w600,
            color: ThemeHelper.foreground1(),
          ),
        ),
        const Gap(8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 270),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: ThemeHelper.auxiliary()),
            itemBuilder: (_, i) =>
                _MemberRow(member: entries[i].member, user: entries[i].user),
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
    final name = user?.name ?? '...';
    final email = user?.email ?? '';

    return Padding(
      padding: .symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  name,
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
          Text(
            member.role.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: .w500,
              color: ThemeHelper.foreground1(),
            ),
          ),
        ],
      ),
    );
  }
}
