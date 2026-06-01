import 'package:onyxia/export.dart';

class VaultMembersTab extends ConsumerStatefulWidget {
  const VaultMembersTab({super.key});

  @override
  ConsumerState<VaultMembersTab> createState() => _VaultMembersTabState();
}

class _VaultMembersTabState extends ConsumerState<VaultMembersTab> {
  final TextEditingController _emailController = TextEditingController();
  String _email = '';
  bool _isProcessing = false;

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
    if (!_isValidEmail || _isProcessing) return;
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
    final email = _email.trim().toLowerCase();

    setState(() => _isProcessing = true);

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
                // TODO: this needs a speech bubble similar to the one made from item_title_validation_service.dart
                child: OnyxiaTextFormField(
                  controller: _emailController,
                  enabled: !_isProcessing,
                  hintText: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  onSubmitted: (_) {
                    if (_isValidEmail) _onSendInvite();
                  },
                ),
              ),
              if (_isProcessing)
                const OnyxiaLoadingIndicator()
              else ...[
                OnyxiaButton(
                  label: 'Add',
                  onPressed: _isValidEmail ? _onSendInvite : null,
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
