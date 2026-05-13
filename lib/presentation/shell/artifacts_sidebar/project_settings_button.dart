import 'package:onyxia/export.dart';

class ProjectSettingsButton extends ConsumerStatefulWidget {
  const ProjectSettingsButton({super.key});

  @override
  ConsumerState createState() => _ProjectSettingsButtonState();
}

class _ProjectSettingsButtonState extends ConsumerState<ProjectSettingsButton> {
  bool _isMenuOpen = false;

  void _setMenuOpen(bool open) {
    if (_isMenuOpen == open) return;
    setState(() => _isMenuOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ref.read(selectedProjectProvider)?.id;
    if (projectId == null) return const SizedBox.shrink();

    return OnyxiaOverlay(
      isOpen: _isMenuOpen,
      onClose: () => _setMenuOpen(false),
      anchor: const Aligned(
        follower: Alignment.bottomLeft,
        target: Alignment.bottomRight,
        offset: Offset(4, 0),
        backup: Aligned(
          follower: Alignment.bottomRight,
          target: Alignment.topRight,
          offset: Offset(0, -6),
        ),
      ),
      builder: (context, closeOverlay) => _buildMenu(closeOverlay),
      child: NarwhalIconButton(
        icon: LucideIcons.settings,
        isPressed: _isMenuOpen,
        onPressed: () => _setMenuOpen(!_isMenuOpen),
      ),
    );
  }

  Widget _buildMenu(VoidCallback closeOverlay) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(6.0),
      color:
          Theme.of(context).popupMenuTheme.color ?? Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(25),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          shrinkWrap: true,
          children: [
            InkWell(
              mouseCursor: SystemMouseCursors.basic,
              onTap: () {
                closeOverlay();
                showDialog(
                  context: context,
                  builder: (_) => const ProjectMembersDialog(),
                );
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: 7.5,
                  horizontal: 16.0,
                ),
                child: Text('Members', style: NarwhalTextStyle()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
