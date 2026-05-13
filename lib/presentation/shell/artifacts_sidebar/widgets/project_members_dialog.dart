import 'package:onyxia/export.dart';

class ProjectMembersDialog extends ConsumerStatefulWidget {
  const ProjectMembersDialog({super.key});

  @override
  ConsumerState<ProjectMembersDialog> createState() =>
      _ProjectMembersDialogState();
}

class _ProjectMembersDialogState extends ConsumerState<ProjectMembersDialog> {
  final TextEditingController _emailController = TextEditingController();
  final Map<String, User> _resolvedUsers = {};
  String _email = '';
  List<String> _resolvedForMemberIds = const [];

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

  Future<void> _resolveMissing(List<ProjectMember> members) async {
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

  void _onSendInvite() {
    final trimmed = _email.trim();
    NarwhalToast.show(
      text: 'Invite sent to $trimmed',
      type: ToastType.success,
    );
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(projectMembersProvider);

    return OnyxiaDialog(
      title: 'Project Members',
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

  Widget _buildContent(List<ProjectMember> members) {
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
        TextField(
          controller: _emailController,
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
  final ProjectMember member;
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
