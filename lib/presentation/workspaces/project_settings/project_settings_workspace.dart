import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/workspaces/project_settings/settings_sidebar.dart';
import 'package:onyxia/presentation/workspaces/project_settings/project_name_tab.dart';

class ProjectSettingsWorkspace extends ConsumerStatefulWidget {
  const ProjectSettingsWorkspace({super.key});

  @override
  ConsumerState<ProjectSettingsWorkspace> createState() =>
      _ProjectSettingsWorkspaceState();
}

class _ProjectSettingsWorkspaceState extends ConsumerState<ProjectSettingsWorkspace> {
  int _selectedTabIndex = 0;

  // Form controllers for editable fields
  final TextEditingController _projectNameController = TextEditingController();
  final FocusNode _projectNameFocusNode = FocusNode();

  bool _hasChanges = false;
  bool _isSaving = false;
  String _originalProjectName = '';
  String _originalProjectImageUrl = '';
  String _newProjectImageUrl = '';
  String _originalProjectBarImageUrl = '';
  String _newProjectImageBarUrl = '';

  late Project activeProject;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectNameFocusNode.dispose();
    super.dispose();
  }

  void _initControllers() {
    final p = ref.read(selectedProjectProvider);
    if (p == null) return;
    activeProject = p;
    _projectNameController.text = activeProject.name;
    _originalProjectName = activeProject.name;
    _projectNameController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasNameChange = _projectNameController.text != _originalProjectName;
    final hasImageChange = _newProjectImageUrl != _originalProjectImageUrl;
    final hasBarImageChange =
        _newProjectImageBarUrl != _originalProjectBarImageUrl;

    setState(() {
      _hasChanges = hasNameChange || hasImageChange || hasBarImageChange;
    });
  }

  void _handleSave() {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final projectId = activeProject.id;

    // Save project name if changed
    if (_projectNameController.text != _originalProjectName) {
      ref
          .read(projectsProvider.notifier)
          .renameProject(projectId, _projectNameController.text);
      _originalProjectName = _projectNameController.text;
    }

    if (mounted) {
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
    }
  }

  void _handleReset() {
    setState(() {
      _projectNameController.text = _originalProjectName;
      _newProjectImageUrl = _originalProjectImageUrl;
      _newProjectImageBarUrl = _originalProjectBarImageUrl;
      _hasChanges = false;
    });
  }

  void _onImageUrlsChanged(String cardImageUrl, String barImageUrl) {
    setState(() {
      _newProjectImageUrl = cardImageUrl;
      _newProjectImageBarUrl = barImageUrl;
    });
    _checkForChanges();
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ThemeHelper.neutral400(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Project Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.neutral700(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return ProjectNameTab(
          projectNameController: _projectNameController,
          projectNameFocusNode: _projectNameFocusNode,
          activeProject: activeProject,
          newProjectImageUrl: _newProjectImageUrl,
          newProjectImageBarUrl: _newProjectImageBarUrl,
          onImageUrlsChanged: _onImageUrlsChanged,
        );
      default:
        return Center(
          child: Text(
            'Coming soon',
            style: NarwhalTextStyle(
              color: ThemeHelper.neutral500(context),
              fontSize: 16,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.neutral100(context),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SettingsSidebar(
              selectedTabIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              projectName: activeProject.name,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildTabContent()),
                  // Only show notification for Project Name tab (index 0)
                  if (_hasChanges && _selectedTabIndex == 0)
                    SaveChangesBar(
                      isSaving: _isSaving,
                      onSave: _handleSave,
                      onReset: _handleReset,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
