import 'package:onyxia/export.dart';

class ProjectWizardData {
  final String projectId;
  final String name;
  final List<UserDefinition> pendingMembers;

  const ProjectWizardData({
    required this.projectId,
    required this.name,
    required this.pendingMembers,
  });
}

class ProjectCreationWizard extends ConsumerStatefulWidget {
  const ProjectCreationWizard();

  @override
  ConsumerState<ProjectCreationWizard> createState() => _ProjectCreationWizardState();
}

class _ProjectCreationWizardState extends ConsumerState<ProjectCreationWizard> {
  final String _projectId = const Uuid().v4();
  int _step = 0;
  final _nameController = TextEditingController();
  final _acronymController = TextEditingController();
  final _teamSearchController = TextEditingController();
  List<UserDefinition> _pendingMembers = [];
  bool _showSuggestions = false;

  // Returns null when valid, or an error string when invalid.
  String? get _acronymError {
    final value = _acronymController.text;
    if (value.isEmpty) return null; // empty = auto-generate, always valid
    if (!RegExp(r'^[A-Z]{1,4}$').hasMatch(value)) return 'Use 1–4 uppercase letters (A–Z) only';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _acronymController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  bool get _canProceed => _nameController.text.trim().isNotEmpty && _acronymError == null;

  void _next() {
    if (!_canProceed) return;
    setState(() => _step = 1);
  }

  void _back() {
    setState(() => _step = 0);
  }

  void _submit() {
    if (!_canProceed) return;
    final name = _nameController.text.trim();
    Navigator.of(context).pop(ProjectWizardData(
      projectId: _projectId,
      name: name,
      pendingMembers: _pendingMembers,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 680,
        height: 640,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildStepIndicator(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _step == 0
                          ? _buildStep1(context)
                          : GestureDetector(
                              onTap: () {
                                if (_showSuggestions) setState(() => _showSuggestions = false);
                              },
                              behavior: HitTestBehavior.translucent,
                              child: SingleChildScrollView(child: _buildStep2(context)),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Text(
            'Create New Project',
            style: NarwhalStyles.modalTitleStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(context, 0, 'Project Details'),
          Expanded(
            child: Container(
              height: 1,
              color: _step >= 1 ? ThemeHelper.blue500(context) : ThemeHelper.neutral300(context),
            ),
          ),
          _buildStepDot(context, 1, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStepDot(BuildContext context, int stepIndex, String label) {
    final bool isActive = _step == stepIndex;
    final bool isCompleted = _step > stepIndex;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? ThemeHelper.blue500(context) : ThemeHelper.neutral200(context),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : ThemeHelper.neutral500(context),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? ThemeHelper.blue500(context) : ThemeHelper.neutral500(context),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: name + description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Project Name', style: NarwhalStyles.modalTextFieldTitleStyle(context)),
              const SizedBox(height: 8),
              TextFormField(
                maxLength: 50,
                controller: _nameController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _next(),
                style: NarwhalTextStyle(color: ThemeHelper.neutral700(context)),
                decoration: InputDecoration(
                  hintText: 'Name your project',
                  hintStyle: NarwhalTextStyle(
                    color: ThemeHelper.neutral500(context).withValues(alpha: 0.7),
                  ),
                  fillColor: ThemeHelper.neutral100(context),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ThemeHelper.neutral400(context), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ThemeHelper.blue500(context), width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final currentUserEmail = ref.read(currentUserProvider).email;
    final pendingEmails = _pendingMembers.map((m) => m.email).toSet();
    final searchText = _teamSearchController.text.toLowerCase();
    final allUsers = ref.watch(userDefinitionsProvider).asData?.value ?? [];
    final filteredUsers = allUsers.where((u) {
      if (u.email == currentUserEmail) return false;
      if (pendingEmails.contains(u.email)) return false;
      if (searchText.isEmpty) return true;
      return u.name.toLowerCase().contains(searchText) || u.email.toLowerCase().contains(searchText);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team section
        Text(
          'Invite Teammates',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add people to your project. You can also do this later from the Access tab.',
          style: TextStyle(fontSize: 13, color: ThemeHelper.neutral500(context)),
        ),
        const SizedBox(height: 12),
        // Search field
        TextField(
          controller: _teamSearchController,
          onChanged: (_) => setState(() => _showSuggestions = true),
          onTap: () => setState(() => _showSuggestions = true),
          style: NarwhalTextStyle(color: ThemeHelper.neutral700(context), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name or email',
            hintStyle: NarwhalTextStyle(color: ThemeHelper.neutral500(context), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: NarwhalIcon(NarwhalIcons.team),
            ),
            fillColor: ThemeHelper.neutral100(context),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ThemeHelper.blue500(context), width: 1),
            ),
          ),
        ),
        // Suggestions list
        if (_showSuggestions) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: ThemeHelper.neutral100(context),
              border: Border(
                left: BorderSide(color: ThemeHelper.neutral400(context)),
                right: BorderSide(color: ThemeHelper.neutral400(context)),
                bottom: BorderSide(color: ThemeHelper.neutral400(context)),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: filteredUsers.isEmpty
                ? SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        searchText.isEmpty ? 'Start typing to search' : 'No matches found',
                        style: NarwhalTextStyle(
                          color: ThemeHelper.neutral500(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredUsers.length,
                    itemBuilder: (_, i) {
                      final user = filteredUsers[i];
                      return _WizardUserSuggestionTile(
                        user: user,
                        onTap: () {
                          setState(() {
                            _pendingMembers.add(user);
                            _teamSearchController.clear();
                            _showSuggestions = false;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
        // Added members
        if (_pendingMembers.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._pendingMembers.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _WizardMemberTile(
                  member: member,
                  onRemove: () => setState(() => _pendingMembers.remove(member)),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NarwhalButton(
          text: 'Cancel',
          type: NarwhalButtonType.secondary,
          onTap: () => Navigator.of(context).pop(null),
        ),
        Row(
          spacing: 12,
          children: [
            if (_step == 1) ...[
              NarwhalButton(
                text: 'Back',
                type: NarwhalButtonType.secondary,
                onTap: _back,
              ),
            ],
            NarwhalButton(
              text: _step == 0 ? 'Next' : 'Create Project',
              type: NarwhalButtonType.primary,
              onTap: _step == 0 ? _next : _submit,
              enabled: _canProceed,
            ),
          ],
        ),
      ],
    );
  }
}

class _WizardUserSuggestionTile extends StatefulWidget {
  final UserDefinition user;
  final VoidCallback onTap;

  const _WizardUserSuggestionTile({required this.user, required this.onTap});

  @override
  State<_WizardUserSuggestionTile> createState() => _WizardUserSuggestionTileState();
}

class _WizardUserSuggestionTileState extends State<_WizardUserSuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (v) => setState(() => _hovered = v),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: _hovered ? ThemeHelper.neutral300(context) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.user.name,
                style: NarwhalTextStyle(fontSize: 13, color: ThemeHelper.neutral700(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.user.email,
                style: NarwhalTextStyle(fontSize: 13, color: ThemeHelper.neutral500(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardMemberTile extends StatelessWidget {
  final UserDefinition member;
  final VoidCallback onRemove;

  const _WizardMemberTile({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        border: Border.all(color: ThemeHelper.neutral300(context)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style:
                  NarwhalTextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ThemeHelper.neutral700(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.email,
              style: NarwhalTextStyle(fontSize: 13, color: ThemeHelper.neutral500(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: ThemeHelper.neutral500(context)),
          ),
        ],
      ),
    );
  }
}
