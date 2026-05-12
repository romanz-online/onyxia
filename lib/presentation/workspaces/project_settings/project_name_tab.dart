import 'package:onyxia/export.dart';

class ProjectNameTab extends StatelessWidget {
  final TextEditingController projectNameController;
  final FocusNode projectNameFocusNode;
  final Project activeProject;
  final String newProjectImageUrl;
  final String newProjectImageBarUrl;
  final Function(String, String) onImageUrlsChanged;

  const ProjectNameTab({
    super.key,
    required this.projectNameController,
    required this.projectNameFocusNode,
    required this.activeProject,
    required this.newProjectImageUrl,
    required this.newProjectImageBarUrl,
    required this.onImageUrlsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 550,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ThemeHelper.neutral300(context),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Project Name',
                  style: NarwhalTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral700(context),
                  ),
                ),
                TextField(
                  controller: projectNameController,
                  focusNode: projectNameFocusNode,
                  decoration: InputDecoration(
                    hintText: activeProject.name,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: ThemeHelper.neutral400(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: ThemeHelper.neutral400(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: ThemeHelper.accentColor(),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    hintStyle: NarwhalTextStyle(
                        color: ThemeHelper.neutral500(context)),
                  ),
                  style:
                      NarwhalTextStyle(color: ThemeHelper.neutral900(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
