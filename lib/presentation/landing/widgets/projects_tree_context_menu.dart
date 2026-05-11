import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/rename_project_dialog.dart';

List<ContextMenuItem> buildProjectContextMenuItems(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final items = <ContextMenuItem>[];

  items.add(ContextMenuItem(
    child: Row(children: [
      const Icon(Icons.open_in_new, size: 14),
      const SizedBox(width: 8),
      Text('Open in New Tab', style: NarwhalTextStyle()),
    ]),
    onTap: () {
      final url = NavigationUrlBuilder.buildProjectDashboardUrl(project.id);
      NavigationContextMenu.openInNewTab(url);
    },
  ));

  items.add(ContextMenuItem(
    child: Row(children: [
      const Icon(Icons.link, size: 14),
      const SizedBox(width: 8),
      Text('Copy Link', style: NarwhalTextStyle()),
    ]),
    onTap: () {
      final url = NavigationUrlBuilder.buildProjectDashboardUrl(project.id);
      NavigationContextMenu.copyLinkToClipboard(url);
    },
  ));

  items.add(ContextMenuItem(
    child: Divider(height: 1, thickness: 1, color: ThemeHelper.neutral400(context)),
    onTap: () {},
  ));

  items.add(ContextMenuItem(
    child: Text('Rename Project', style: NarwhalTextStyle()),
    onTap: () {
      showDialog(
        context: context,
        barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
        builder: (_) => RenameProjectDialog(
          projectName: project.name,
          projectId: project.id,
        ),
      );
    },
  ));

  items.add(ContextMenuItem(
    child: Text('Remove Project', style: NarwhalTextStyle()),
    onTap: () => _confirmRemove(context, ref, project),
  ));

  return items;
}

void _confirmRemove(BuildContext context, WidgetRef ref, Project project) async {
  String projectName = project.name;
  if (projectName.length > 25) projectName = '${projectName.substring(0, 25)}... ';

  final confirm = await showDialog<bool>(
    context: context,
    barrierColor: ThemeHelper.neutral900(context).withValues(alpha: 0.5),
    builder: (_) => NarwhalModalDialog(
      width: 600,
      height: 200,
      title: 'Remove $projectName?',
      hasLargeTitle: true,
      content: Text(
        'This is permanent.',
        style: NarwhalTextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      onCancelPressed: () => Navigator.of(context).pop(false),
      actionButtonText: 'Remove Project',
      onActionPressed: () => Navigator.of(context).pop(true),
    ),
  );

  if (confirm == true) {
    ref.read(projectsProvider.notifier).deleteProject(project.id);
  }
}
