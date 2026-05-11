import 'package:onyxia/export.dart';

class UserProfileOverlay extends ConsumerStatefulWidget {
  final User user;

  const UserProfileOverlay({super.key, required this.user});

  @override
  ConsumerState<UserProfileOverlay> createState() => _UserProfileOverlayState();
}

class _UserProfileOverlayState extends ConsumerState<UserProfileOverlay> {
  int _selectedTabIndex = 0;

  TextStyle _sectionHeaderStyle(Color color) => NarwhalTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Row(
          children: [
            Expanded(
                child: Container(color: ThemeHelper.neutral300(context))),
            SizedBox(
              width: 1000,
              child: Row(
                children: [
                  // Left sidebar — profile preview + tabs
                  Container(
                    width: 220,
                    decoration: BoxDecoration(
                        color: ThemeHelper.neutral300(context)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              Text(
                                widget.user.name,
                                style: NarwhalTextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeHelper.black(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.email,
                                style: NarwhalTextStyle(
                                  fontSize: 14,
                                  color: ThemeHelper.neutral600(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTabButton(label: 'Profile', index: 0),
                                _buildTabButton(
                                    label: 'Notifications', index: 2),
                                _buildTabButton(
                                    label: 'Privacy & Security', index: 5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: ThemeHelper.neutral300(context)),
                      child: Column(
                        children: [
                          // Header with close button
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: ThemeHelper.neutral200(context),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'User Profile',
                                  style: NarwhalTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeHelper.black(context),
                                  ),
                                ),
                                NarwhalIconButton(
                                  icon: NarwhalIcons.close,
                                  size: 28,
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildTabContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ThemeHelper.neutral300(context)
                    : ThemeHelper.white(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final isSelected = _selectedTabIndex == index;
    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: (isSelected || isHovered)
                    ? ThemeHelper.neutral200(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: NarwhalTextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? ThemeHelper.black(context)
                      : ThemeHelper.neutral600(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileTab();
      case 2:
        return const SizedBox.shrink();
      case 5:
        return _buildPrivacyTab();
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: _sectionHeaderStyle(ThemeHelper.neutral900(context))
                .copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(Icons.email_outlined, 'Email', widget.user.email),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingItem(
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security to your account',
            trailing: NarwhalSwitch(value: false, onChanged: null),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ThemeHelper.neutral600(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: NarwhalTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.neutral600(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: NarwhalTextStyle(
                    fontSize: 16,
                    color: ThemeHelper.black(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: ThemeHelper.neutral600(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NarwhalTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.black(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: NarwhalTextStyle(
                    fontSize: 14,
                    color: ThemeHelper.neutral600(context),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

extension UserProfileOverlayExtension on BuildContext {
  Future<void> showUserProfileOverlay(User user) async {
    await showGeneralDialog(
      context: this,
      barrierDismissible: true,
      barrierLabel: 'User Profile',
      pageBuilder: (context, animation, secondaryAnimation) =>
          UserProfileOverlay(user: user),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }
}
