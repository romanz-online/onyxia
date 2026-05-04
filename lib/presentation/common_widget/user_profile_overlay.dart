import 'package:onyxia/export.dart';

class UserProfileOverlay extends ConsumerStatefulWidget {
  final UserDefinition user;
  final bool isEditable;

  const UserProfileOverlay({
    super.key,
    required this.user,
    this.isEditable = false,
  });

  @override
  ConsumerState<UserProfileOverlay> createState() => _UserProfileOverlayState();
}

class _UserProfileOverlayState extends ConsumerState<UserProfileOverlay> {
  int _selectedTabIndex = 0;

  // Form controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _aboutMeFocusNode = FocusNode();

  // Change tracking
  bool _hasChanges = false;
  bool _isSaving = false;
  String _originalName = '';
  String _originalAboutMe = '';

  // Animation for shake effect
  final NarwhalAngryController _angryController = NarwhalAngryController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    _nameFocusNode.dispose();
    _aboutMeFocusNode.dispose();
    super.dispose();
  }

  void _initControllers() {
    _nameController.text = widget.user.name;
    _aboutMeController.text = widget.user.aboutMe;

    // Store original values for change detection
    _originalName = widget.user.name;
    _originalAboutMe = widget.user.aboutMe;

    // Add listeners for change detection and preview updates
    _nameController.addListener(_onTextChanged);
    _aboutMeController.addListener(_onTextChanged);
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != _originalName || _aboutMeController.text != _originalAboutMe;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _onTextChanged() {
    _checkForChanges();
    // Trigger rebuild to update the preview card
    setState(() {});
  }

  String _getTabTitle(int tabIndex) => switch (tabIndex) {
        0 => 'Edit Profile',
        1 => 'Appearance',
        2 => 'Notification Settings',
        4 => 'Plugins',
        5 => 'Privacy & Security',
        6 => 'Advanced Settings',
        _ => 'Edit Profile',
      };

  void _resetChanges() {
    setState(() {
      _nameController.text = _originalName;
      _aboutMeController.text = _originalAboutMe;
      _hasChanges = false;
    });
  }

  TextStyle _sectionHeaderStyle(Color color) {
    return NarwhalTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Left margin with sidebar color
                  Expanded(child: Container(color: ThemeHelper.neutral300(context))),

                  // Main content area (constrained to 800px max)
                  SizedBox(
                    width: 1000,
                    child: Row(
                      children: [
                        // Left sidebar
                        Container(
                          width: 220,
                          decoration: BoxDecoration(color: ThemeHelper.neutral300(context)),
                          child: Column(
                            children: [
                              // Profile preview section
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.isEditable ? currentUser.name : widget.user.name,
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

                              // Navigation tabs
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTabButton(label: 'Profile', index: 0),
                                      _buildTabButton(label: 'Notifications', index: 2),
                                      _buildTabButton(label: 'Privacy & Security', index: 5),
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
                            decoration: BoxDecoration(color: ThemeHelper.neutral300(context)),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget.isEditable ? _getTabTitle(_selectedTabIndex) : 'User Profile',
                                        style: NarwhalTextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ThemeHelper.black(context),
                                        ),
                                      ),
                                      NarwhalIconButton(
                                        icon: NarwhalIcons.close,
                                        size: 28,
                                        onPressed: () {
                                          if (_hasChanges) {
                                            _angryController.triggerShake();
                                            return;
                                          }
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Content area with notification bar overlay
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Main content
                                      _buildTabContent(currentUser),

                                      // Bottom notification bar (positioned)
                                      if (widget.isEditable && _hasChanges)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Center(
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(
                                                  maxWidth: 500,
                                                ),
                                                child: NarwhalAngry(
                                                  controller: _angryController,
                                                  child: _buildChangeNotificationBar(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right margin with content color
                  Expanded(
                    child: Container(
                      // this color used to be the hard-coded value 'Colors(0xFF36393F)', which is approximately 'NarwhalColors.neutral700'
                      // when in DarkMode, that color is returned by 'ThemeHelper.neutral300(context)'.
                      // Thus, the logic below.
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ThemeHelper.neutral300(context)
                          : ThemeHelper.white(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index, bool disabled = false}) {
    final isSelected = _selectedTabIndex == index;

    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled
                ? null
                : () {
                    if (_hasChanges && index != _selectedTabIndex) {
                      _angryController.triggerShake();
                      return;
                    }
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.transparent
                    : (isSelected || isHovered)
                        ? ThemeHelper.neutral200(context)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: NarwhalTextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: disabled
                        ? ThemeHelper.neutral400(context)
                        : isSelected
                            ? ThemeHelper.black(context)
                            : ThemeHelper.neutral600(context)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(UserDefinition currentUser) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileTab(currentUser);
      case 1:
        return _buildAppearanceTab();
      case 2:
        return const SizedBox.shrink();
      case 3:
        return _buildPrivacyTab();
      case 4:
        return _buildAdvancedTab();
      default:
        return _buildProfileTab(currentUser);
    }
  }

  Widget _buildProfileTab(UserDefinition currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditable) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Text fields
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Name',
                              style: _sectionHeaderStyle(ThemeHelper.neutral700(context)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                hintText: widget.user.email.split('@').first,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ThemeHelper.neutral400(context),
                                  ),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                hintStyle: NarwhalTextStyle(
                                  color: ThemeHelper.neutral500(context),
                                ),
                              ),
                              style: NarwhalTextStyle(
                                color: ThemeHelper.black(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // About Me section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Me',
                              style: _sectionHeaderStyle(ThemeHelper.neutral700(context)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _aboutMeController,
                              focusNode: _aboutMeFocusNode,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Role, company, field...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ThemeHelper.neutral400(context),
                                  ),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                hintStyle: NarwhalTextStyle(
                                  color: ThemeHelper.neutral500(context),
                                ),
                              ),
                              style: NarwhalTextStyle(
                                color: ThemeHelper.black(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Read-only view
            _buildInfoSection(
              title: 'Contact Information',
              items: [
                _buildInfoItem(Icons.email_outlined, 'Email', widget.user.email),
                _buildInfoItem(
                  Icons.person_outline,
                  'About Me',
                  widget.user.aboutMe.isNotEmpty ? widget.user.aboutMe : 'No information provided',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch between light and dark themes',
            trailing: NarwhalSwitch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: widget.isEditable
                  ? (value) {
                      // Theme switching logic would go here
                    }
                  : null,
            ),
          ),
          _buildSettingItem(
            icon: Icons.text_fields_outlined,
            title: 'Font Size',
            subtitle: 'Adjust text size for better readability',
            trailing: NarwhalIcon(
              NarwhalIcons.expandArrowCollapsed,
              color: ThemeHelper.neutral600(context),
            ),
            onTap: widget.isEditable
                ? () {
                    // Handle font size settings
                    debugPrint('Font size tapped');
                  }
                : null,
          ),
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
            icon: Icons.visibility_outlined,
            title: 'Profile Visibility',
            subtitle: 'Control who can see your profile information',
            trailing: NarwhalIcon(
              NarwhalIcons.expandArrowCollapsed,
              color: ThemeHelper.neutral600(context),
            ),
            onTap: widget.isEditable
                ? () {
                    // Handle profile visibility settings
                    debugPrint('Profile visibility tapped');
                  }
                : null,
          ),
          _buildSettingItem(
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security to your account',
            trailing: NarwhalSwitch(
              value: false,
              onChanged: widget.isEditable
                  ? (value) {
                      // 2FA toggle logic
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            trailing: NarwhalIcon(
              NarwhalIcons.expandArrowCollapsed,
              color: ThemeHelper.errorColor(),
            ),
            onTap: widget.isEditable
                ? () {
                    // Handle account deletion
                    debugPrint('Delete account tapped');
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: NarwhalTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ThemeHelper.neutral900(context),
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ThemeHelper.neutral600(context),
          ),
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
    VoidCallback? onTap,
  }) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isHovered && onTap != null
                    ? ThemeHelper.neutral200(context).withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: ThemeHelper.neutral600(context),
                  ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangeNotificationBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // this color used to be the hard-coded value 'Colors(0xFF2F3136)', which is approximately 'NarwhalColors.neutral700'.
        // when in DarkMode, that color is returned by 'ThemeHelper.neutral300(context)'.
        // Thus, the logic below.
        color: Theme.of(context).brightness == Brightness.dark
            ? ThemeHelper.neutral300(context)
            : ThemeHelper.white(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.neutral200(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.neutral900(context).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You\'ve made changes to your profile.',
            style: NarwhalTextStyle(
              fontSize: 14,
              color: ThemeHelper.neutral900(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              HoverBuilder(
                builder: (context, isHovered) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _resetChanges,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isHovered ? ThemeHelper.accentColor().withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Reset',
                          style: NarwhalTextStyle(color: ThemeHelper.accentColor()),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Maintain button space with Container to prevent layout shift
              SizedBox(
                width: 64, // Fixed width to maintain layout
                height: 32, // Fixed height to maintain layout
                child: _isSaving
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: NarwhalSpinner(),
                        ),
                      )
                    : HoverBuilder(
                        builder: (context, isHovered) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                setState(() => _isSaving = true);

                                try {
                                  final currentUser = ref.read(currentUserProvider);
                                  final finalName = _nameController.text.trim().isEmpty
                                      ? widget.user.email.split('@').first
                                      : _nameController.text.trim();
                                  final updatedUser = currentUser.copyWith(
                                    name: finalName,
                                    aboutMe: _aboutMeController.text,
                                  );

                                  await ref.read(currentUserProvider.notifier).updateUserProfile(updatedUser);

                                  if (mounted) {
                                    // Update original values after successful save
                                    setState(() {
                                      _originalName = finalName;
                                      _originalAboutMe = _aboutMeController.text;
                                      _hasChanges = false;
                                    });
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                              child: Container(
                                width: 64,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? ThemeHelper.accentColor().withValues(alpha: 0.8)
                                      : ThemeHelper.accentColor(),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'Save',
                                    style: NarwhalTextStyle(
                                      color: ThemeHelper.white(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomColorPicker extends StatefulWidget {
  final Color initialColor;
  final Color defaultColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onDefaultColorSelected;

  const _CustomColorPicker({
    required this.initialColor,
    required this.defaultColor,
    required this.onColorChanged,
    required this.onDefaultColorSelected,
  });

  @override
  State<_CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<_CustomColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: widget.initialColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateColor() {
    final color = _hsvColor.toColor();
    widget.onColorChanged(color);
    _hexController.text = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _updateFromHex(String hex) {
    try {
      if (hex.length == 6) {
        final color = Color(int.parse('FF$hex', radix: 16));
        setState(() {
          _hsvColor = HSVColor.fromColor(color);
        });
        widget.onColorChanged(color);
      }
    } catch (e) {
      // Invalid hex, ignore
    }
  }

  void _selectPresetColor(Color color) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
    });
    widget.onColorChanged(color);
    _updateColor();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient area (saturation/value picker)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  final saturation = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
                  final value = 1.0 - (localPosition.dy / 120).clamp(0.0, 1.0);

                  setState(() {
                    _hsvColor = _hsvColor.withSaturation(saturation).withValue(value);
                    _updateColor();
                  });
                },
                onTapDown: (details) {
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  final saturation = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
                  final value = 1.0 - (localPosition.dy / 120).clamp(0.0, 1.0);

                  setState(() {
                    _hsvColor = _hsvColor.withSaturation(saturation).withValue(value);
                    _updateColor();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeHelper.white(context),
                        HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ThemeHelper.black(context),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: _hsvColor.saturation * (200 - 16),
                          top: (1.0 - _hsvColor.value) * (120 - 16),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ThemeHelper.white(context),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Hue slider
          Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                final hue = (localPosition.dx / renderBox.size.width * 360).clamp(0.0, 360.0);

                setState(() {
                  _hsvColor = _hsvColor.withHue(hue);
                  _updateColor();
                });
              },
              onTapDown: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                final hue = (localPosition.dx / renderBox.size.width * 360).clamp(0.0, 360.0);

                setState(() {
                  _hsvColor = _hsvColor.withHue(hue);
                  _updateColor();
                });
              },
              child: Stack(
                children: [
                  Positioned(
                    left: (_hsvColor.hue / 360) * (200 - 16),
                    top: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeHelper.white(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Hex input
          SizedBox(
            height: 32,
            child: TextField(
              controller: _hexController,
              decoration: InputDecoration(
                prefixText: '#',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              style: const NarwhalTextStyle(fontFamily: 'monospace', fontSize: 12),
              onChanged: _updateFromHex,
            ),
          ),
          // Color preset squares
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ColorSquare(
                color: widget.defaultColor,
                onTap: () {
                  _selectPresetColor(widget.defaultColor);
                  widget.onDefaultColorSelected();
                },
              ),
              _ColorSquare(
                color: ThemeHelper.red(),
                onTap: () => _selectPresetColor(ThemeHelper.red()),
              ),
              _ColorSquare(
                color: ThemeHelper.green(),
                onTap: () => _selectPresetColor(ThemeHelper.green()),
              ),
              _ColorSquare(
                color: ThemeHelper.blue(),
                onTap: () => _selectPresetColor(ThemeHelper.blue()),
              ),
              _ColorSquare(
                color: ThemeHelper.orange(),
                onTap: () => _selectPresetColor(ThemeHelper.orange()),
              ),
              _ColorSquare(
                color: ThemeHelper.purple(),
                onTap: () => _selectPresetColor(ThemeHelper.purple()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded square color picker widget
class _ColorSquare extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorSquare({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ThemeHelper.neutral300(context),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to show user profile overlay
extension UserProfileOverlayExtension on BuildContext {
  /// Shows a user profile overlay for viewing
  Future<void> showUserProfileOverlay(UserDefinition user) async {
    await showGeneralDialog(
      context: this,
      barrierDismissible: true,
      barrierLabel: 'User Profile',
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserProfileOverlay(user: user, isEditable: false);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// Shows an editable user profile overlay
  Future<void> showEditableUserProfileOverlay(UserDefinition user) async {
    await showGeneralDialog(
      context: this,
      barrierDismissible: true,
      barrierLabel: 'Edit Profile',
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserProfileOverlay(user: user, isEditable: true);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}
