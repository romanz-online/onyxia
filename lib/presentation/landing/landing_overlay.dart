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

  final TextEditingController _newProjectNameController =
      TextEditingController();

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
    _newProjectNameController.dispose();
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

  void _navigateToProject(Project project) {
    ref.read(projectsProvider.notifier).selectProject(project);
    context.go('/project/${project.id}/graph');
  }

  void _showNewProjectDialog() {
    _newProjectNameController.clear();
    showDialog(
      context: context,
      barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
      builder: (dialogContext) {
        return NarwhalModalDialog(
          width: 600,
          height: 260,
          title: 'New Project',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                'Project Name',
                style: NarwhalStyles.modalTextFieldTitleStyle(dialogContext),
              ),
              TextFormField(
                maxLength: 50,
                controller: _newProjectNameController,
                autofocus: true,
                decoration: NarwhalModalInputDecoration.create(
                  dialogContext,
                  hintText: 'Enter project name',
                ),
                style: NarwhalTextStyle(),
              ),
            ],
          ),
          onCancelPressed: () => Navigator.of(dialogContext).pop(),
          actionButtonText: 'Create',
          onActionPressed: () {
            final name = _newProjectNameController.text.trim();
            if (name.isEmpty) return;
            final currentUserId = ref.read(currentUserProvider).id;
            final now = DateTime.now();
            final newProject = Project(
              id: const Uuid().v4(),
              createdBy: currentUserId,
              createdAt: now,
              updatedAt: now,
              name: name,
            );
            ref.read(projectsProvider.notifier).addProject(newProject);
            Navigator.of(dialogContext).pop();
            _navigateToProject(newProject);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
    if (user.pending) return Center(child: NarwhalSpinner());

    final projects = ref.watch(projectsProvider).projects;

    return Row(
      children: [
        SizedBox(
          width: _leftColumnWidth,
          child: _buildProjectList(context, projects),
        ),
        VerticalDivider(
          width: 2,
          color: ThemeHelper.neutral300(context),
        ),
        Expanded(
          child: _buildRightColumn(context, user),
        ),
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

  Widget _buildProjectList(BuildContext context, List<Project> projects) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (projects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Your projects',
                style: NarwhalTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.neutral500(context),
                ),
              ),
            ),
          Expanded(
            child: projects.isEmpty
                ? Center(
                    child: Text(
                      'No projects',
                      style: NarwhalTextStyle(
                        fontSize: 13,
                        color: ThemeHelper.neutral500(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) =>
                        _buildProjectRow(context, projects[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, Project project) {
    return OnyxiaButton(
      label: project.name,
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
              NavigationUrlBuilder.buildProjectDashboardUrl(project.id));
        } else {
          _navigateToProject(project);
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
                    label: 'New Project',
                    onTap: _showNewProjectDialog,
                  ),
                  OnyxiaButton(
                    label: 'Import Project',
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
