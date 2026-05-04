import 'package:onyxia/export.dart';
import 'package:onyxia/helpers/safe_right_click_menu_position.dart';
import 'package:onyxia/presentation/screens/canvas/utils/image_drag_data.dart';
import 'canvas_right_click.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'package:web/web.dart' as web;

class CanvasRightClickMenu extends StatefulWidget {
  final bool isMarkup;
  final List<RightClickMenuOption> options;
  final Offset globalPosition;
  final Offset localPosition;
  final WidgetRef ref;
  final CanvasObject? clickedObj;
  final VoidCallback onClose;

  const CanvasRightClickMenu({
    super.key,
    required this.isMarkup,
    required this.options,
    required this.globalPosition,
    required this.localPosition,
    required this.ref,
    required this.clickedObj,
    required this.onClose,
  });

  @override
  State<CanvasRightClickMenu> createState() => _CanvasRightClickMenuState();
}

class _CanvasRightClickMenuState extends State<CanvasRightClickMenu> {
  bool _isSubmenuOpen = false;
  bool _isHoveringArrange = false;
  bool _isHoveringSubmenu = false;
  OverlayEntry? _submenuOverlay;
  Timer? _closeTimer;
  Timer? _hoverDelayTimer;
  OverlayEntry? _importSubmenuOverlay;
  Timer? _importCloseTimer;
  Timer? _importHoverDelayTimer;
  Offset _actualMenuPosition = Offset.zero;
  String _hoveredItemId = ''; // Track which regular item is hovered
  final List<RightClickMenuOption> _arrangeOptions = [
    RightClickMenuOption.bringForward,
    RightClickMenuOption.bringToFront,
    RightClickMenuOption.sendBackward,
    RightClickMenuOption.sendToBack,
  ];

  @override
  void initState() {
    super.initState();
    // Menu is created directly in build() - no need for overlay creation
  }

  void _showSubmenu() {
    if (_submenuOverlay != null) return;

    final screenSize = MediaQuery.of(context).size;

    // Get the actual position of the main menu from the build method
    final actualMenuPosition = _actualMenuPosition;

    // Calculate submenu dimensions properly
    final submenuHeight = (_arrangeOptions.length * 38.0) + 16.0; // Account for padding
    final submenuWidth = 200.0;
    final arrangeOffset = _getArrangeItemOffset();

    // Calculate initial submenu position (to the right of main menu)
    double submenuTop = actualMenuPosition.dy + arrangeOffset;
    double submenuLeft = actualMenuPosition.dx + 220 + 2; // Main menu width + gap

    // Check if submenu goes off-screen vertically
    if (submenuTop + submenuHeight > screenSize.height - 16) {
      // Try positioning above the arrange item
      submenuTop = actualMenuPosition.dy + arrangeOffset - submenuHeight;

      // If still off-screen, position at bottom of screen
      if (submenuTop < 16) {
        submenuTop = screenSize.height - submenuHeight - 16;
      }
    }

    // Check if submenu goes off-screen horizontally
    if (submenuLeft + submenuWidth > screenSize.width - 16) {
      // Position submenu to the left of main menu
      submenuLeft = actualMenuPosition.dx - submenuWidth - 2;

      // If still off-screen on the left, clamp to screen edge
      if (submenuLeft < 16) {
        submenuLeft = 16;
      }
    }

    final submenuPosition = Offset(submenuLeft, submenuTop);

    _submenuOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: submenuPosition.dx,
        top: submenuPosition.dy,
        child: MouseRegion(
          onEnter: (_) {
            _closeTimer?.cancel();
            if (mounted) {
              setState(() {
                _isHoveringSubmenu = true;
                _isSubmenuOpen = true;
              });
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() {
                _isHoveringSubmenu = false;
              });
              _checkAndCloseSubmenu();
            }
          },
          child: _SubmenuWidget(
            arrangeOptions: _arrangeOptions,
            onItemTap: _handleSubmenuItemTap,
            isOptionEnabled: _isOptionEnabled,
            ref: widget.ref,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_submenuOverlay!);
  }

  void _closeSubmenu() {
    _submenuOverlay?.remove();
    _submenuOverlay = null;
  }

  void _closeImportSubmenu() {
    _importSubmenuOverlay?.remove();
    _importSubmenuOverlay = null;
  }

  void _handleMenuItemTap(RightClickMenuOption option) {
    if (option == RightClickMenuOption.arrange) {
      // Don't handle clicks on submenu parents - hover-only
      return;
    } else {
      // Handle regular menu item
      _handleMenuAction(option);
      widget.onClose();
    }
  }

  void _onArrangeHover(bool isHovering) {
    if (mounted) {
      setState(() {
        _isHoveringArrange = isHovering;
      });

      if (isHovering) {
        _hoverDelayTimer?.cancel();
        _closeTimer?.cancel();

        // Add small delay before opening submenu for better UX
        _hoverDelayTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted && _isHoveringArrange) {
            setState(() {
              _isSubmenuOpen = true;
            });
            _showSubmenu();
          }
        });
      } else {
        _hoverDelayTimer?.cancel();
        _checkAndCloseSubmenu();
      }
    }
  }

  void _checkAndCloseSubmenu() {
    // Cancel any existing timer
    _closeTimer?.cancel();

    // Only close if not hovering either Arrange or submenu
    if (!_isHoveringArrange && !_isHoveringSubmenu) {
      // Add small delay to allow moving cursor between elements
      _closeTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted && !_isHoveringArrange && !_isHoveringSubmenu) {
          setState(() {
            _isSubmenuOpen = false;
          });
          _closeSubmenu();
        }
      });
    }
  }

  // Calculate the Y offset where the Arrange item appears in the menu
  double _getArrangeItemOffset() {
    double offset = 8; // Top padding of menu container
    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];

      // Add divider height if needed
      if (_shouldAddDivider(option, i > 0 ? widget.options[i - 1] : null)) {
        offset += 9; // Divider height + margins
      }

      if (option == RightClickMenuOption.arrange) {
        return offset;
      }

      offset += 42; // Menu item height including margins
    }
    return 0;
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _hoverDelayTimer?.cancel();
    _closeSubmenu();
    _importCloseTimer?.cancel();
    _importHoverDelayTimer?.cancel();
    _closeImportSubmenu();
    super.dispose();
  }

  void _handleSubmenuItemTap(RightClickMenuOption option) {
    _handleMenuAction(option);
    widget.onClose();
  }

  void _handleMenuAction(RightClickMenuOption option) async {
    // Reuse existing logic from canvas_right_click.dart
    await _handleMenuItemTapInternal(
      widget.isMarkup,
      option,
      widget.localPosition,
      context,
      widget.ref,
      widget.clickedObj,
    );
  }

  // Copy of the _handleMenuItemTap function from canvas_right_click.dart
  Future<void> _handleMenuItemTapInternal(
    bool isMarkup,
    RightClickMenuOption option,
    Offset position,
    BuildContext context,
    WidgetRef ref,
    CanvasObject? clickedObj,
  ) async {
    final canvasId = ref.read(currentCanvasProvider)?.id ?? '';
    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    switch (option) {
      case RightClickMenuOption.addComment:
        await CanvasInteractionService.createComment(
          ref: ref,
          position: position,
          targetObject: clickedObj,
        );
        break;
      case RightClickMenuOption.addArtifact:
        try {
          if (clickedObj != null || isMarkup) {
            CanvasInteractionService.createPin(
              ref: ref,
              position: position,
              item: null,
              targetObject: clickedObj,
            );
          }
        } catch (e) {
          debugPrint(e.toString());
          rethrow;
        }
        break;
      case RightClickMenuOption.paste:
        final pasted = await CanvasClipboardService.paste(
          targetPosition: position,
          ref: ref,
        );
        objectsNotifier.addObjects(ref, pasted.$1);
        objectsNotifier.clearSelectedObjects();
        ref.read(pinsProvider.notifier).addPins(ref, pasted.$2);
        break;
      case RightClickMenuOption.cut:
        await CanvasClipboardService.copy(objects: selectedObjects);
        objectsNotifier.deleteObjects(ref, selectedObjects);
        break;
      case RightClickMenuOption.copy:
        await CanvasClipboardService.copy(objects: selectedObjects);
        break;
      case RightClickMenuOption.delete:
        objectsNotifier.deleteObjects(ref, selectedObjects);
        break;
      case RightClickMenuOption.snapToGrid:
        ref.read(canvasSettingsProvider(Setting.snapToGrid).notifier).update((state) => !state);
        break;
      case RightClickMenuOption.showMinimap:
        ref.read(canvasSettingsProvider(Setting.showMinimap).notifier).update((state) => !state);
        break;
      case RightClickMenuOption.showToolbar:
        ref.read(canvasSettingsProvider(Setting.showToolbar).notifier).update((state) => !state);
        break;
      case RightClickMenuOption.importImage:
        await _handleImportImage(ref, position, canvasId);
        break;
      case RightClickMenuOption.getDiagramLink:
        Clipboard.setData(ClipboardData(text: _getCurrentCanvasUrl()));
        NarwhalToast.show(
          text: 'Link copied to clipboard',
          type: ToastType.success,
        );
        break;
      case RightClickMenuOption.arrange:
        // This case should not be called directly
        break;
      case RightClickMenuOption.sendBackward:
        _moveObjectsBack1(ref, clickedObj);
        break;
      case RightClickMenuOption.sendToBack:
        _sendObjectsToBack(ref, clickedObj);
        break;
      case RightClickMenuOption.bringForward:
        _moveObjectsForward1(ref, clickedObj);
        break;
      case RightClickMenuOption.bringToFront:
        _bringObjectsToFront(ref, clickedObj);
        break;
    }
  }

  Future<void> _handleImportImage(WidgetRef ref, Offset position, String canvasId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;

        // Get image data from web bytes
        if (file.bytes == null) {
          NarwhalToast.show(
            text: 'Failed to read image data',
            type: ToastType.error,
          );
          return;
        }
        final Uint8List bytes = file.bytes!;
        final fileName = file.name;

        // Get current project info
        final projectId = ref.read(projectsProvider).selectedProject.id;
        final userName = ref.read(currentUserProvider).name;

        // Upload using ImageService
        final imageUrl = await ImageService.uploadImage(
          bytes,
          fileName,
          userName: userName,
          projectId: projectId,
          canvasId: canvasId,
        );

        final imageId = DateTime.now().millisecondsSinceEpoch.toString();
        await CanvasInteractionService.insertImage(
          ref: ref,
          data: ImageDragData(
            imageId: imageId,
            imageUrl: imageUrl,
            imageTitle: '${file.name}-${imageId}',
          ),
          canvasPosition: position,
        );
      }
    } catch (e) {
      NarwhalToast.show(
        text: 'Failed to upload image: $e',
        type: ToastType.error,
      );
    }
  }

  void _moveObjectsBack1(WidgetRef ref, CanvasObject? clickedObj) {
    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    final objectsToMove =
        selectedObjects.isNotEmpty ? selectedObjects : (clickedObj != null ? [clickedObj] : <CanvasObject>[]);

    for (final obj in objectsToMove) {
      objectsNotifier.moveObjectBackward(ref, obj);
    }
  }

  void _sendObjectsToBack(WidgetRef ref, CanvasObject? clickedObj) {
    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    final objectsToMove =
        selectedObjects.isNotEmpty ? selectedObjects : (clickedObj != null ? [clickedObj] : <CanvasObject>[]);

    for (final obj in objectsToMove) {
      objectsNotifier.moveObjectToBack(ref, obj);
    }
  }

  void _moveObjectsForward1(WidgetRef ref, CanvasObject? clickedObj) {
    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    final objectsToMove =
        selectedObjects.isNotEmpty ? selectedObjects : (clickedObj != null ? [clickedObj] : <CanvasObject>[]);

    for (final obj in objectsToMove) {
      objectsNotifier.moveObjectForward(ref, obj);
    }
  }

  void _bringObjectsToFront(WidgetRef ref, CanvasObject? clickedObj) {
    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
    final selectedObjects = ref.read(canvasObjectsProvider).selectedObjects;

    final objectsToMove =
        selectedObjects.isNotEmpty ? selectedObjects : (clickedObj != null ? [clickedObj] : <CanvasObject>[]);

    for (final obj in objectsToMove) {
      objectsNotifier.moveObjectToFront(ref, obj);
    }
  }

  String _getCurrentCanvasUrl() {
    return web.window.location.href;
  }

  Widget _buildMenuContent() {
    return Material(
      elevation: 12,
      shadowColor: ThemeHelper.black(context).withValues(alpha: 0.15),
      //color: ThemeHelper.white(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildMenuItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];

    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];

      if (_shouldAddDivider(option, i > 0 ? widget.options[i - 1] : null)) {
        items.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
          ),
        ));
      }

      items.add(_buildMenuItem(option));
    }

    return items;
  }

  Widget _buildMenuItem(RightClickMenuOption option) {
    if (option == RightClickMenuOption.arrange) {
      // Special hover-based menu item for Arrange
      return MouseRegion(
        onEnter: (_) => _onArrangeHover(true),
        onExit: (_) => _onArrangeHover(false),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _isSubmenuOpen || _isHoveringArrange ? ThemeHelper.neutral300(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: ThemeHelper.neutral700(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMenuItemText(option),
                    style: NarwhalTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.neutral700(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: ThemeHelper.neutral700(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular clickable menu item with hover effect
    final itemId = option.toString();
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() {
            _hoveredItemId = itemId;
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() {
            _hoveredItemId = '';
          });
        }
      },
      child: GestureDetector(
        onTap: () => _handleMenuItemTap(option),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _hoveredItemId == itemId ? ThemeHelper.neutral300(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _getMenuItemIcon(option),
                  size: 16,
                  color: ThemeHelper.neutral700(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMenuItemText(option),
                    style: NarwhalTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.neutral700(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOptionEnabled(RightClickMenuOption option) {
    if (widget.clickedObj == null) return false;

    final objectsNotifier = widget.ref.read(canvasObjectsProvider.notifier);

    switch (option) {
      case RightClickMenuOption.sendBackward:
      case RightClickMenuOption.sendToBack:
        return objectsNotifier.canMoveBackward(widget.clickedObj!);
      case RightClickMenuOption.bringForward:
      case RightClickMenuOption.bringToFront:
        return objectsNotifier.canMoveForward(widget.clickedObj!);
      default:
        return true;
    }
  }

  bool _shouldAddDivider(RightClickMenuOption current, RightClickMenuOption? previous) {
    const dividerBefore = {
      RightClickMenuOption.paste,
      RightClickMenuOption.cut,
      RightClickMenuOption.snapToGrid,
      RightClickMenuOption.arrange,
    };

    return dividerBefore.contains(current);
  }

  String _getMenuItemText(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.addComment:
        return 'Add Comment';
      case RightClickMenuOption.addArtifact:
        return 'Add Pin';
      case RightClickMenuOption.paste:
        return 'Paste';
      case RightClickMenuOption.cut:
        return 'Cut';
      case RightClickMenuOption.copy:
        return 'Copy';
      case RightClickMenuOption.delete:
        return 'Delete';
      case RightClickMenuOption.snapToGrid:
        final snapToGrid = widget.ref.watch(canvasSettingsProvider(Setting.snapToGrid));
        return 'Turn ${snapToGrid ? 'off' : 'on'} snap to grid';
      case RightClickMenuOption.showMinimap:
        final showMinimap = widget.ref.watch(canvasSettingsProvider(Setting.showMinimap));
        return '${showMinimap ? 'Hide' : 'Show'} mini-map';
      case RightClickMenuOption.showToolbar:
        final showToolbar = widget.ref.watch(canvasSettingsProvider(Setting.showToolbar));
        return '${showToolbar ? 'Hide' : 'Show'} toolbar';
      case RightClickMenuOption.importImage:
        return 'Image';
      case RightClickMenuOption.getDiagramLink:
        return 'Get link to diagram';
      case RightClickMenuOption.arrange:
        return 'Arrange';
      default:
        return '';
    }
  }

  IconData _getMenuItemIcon(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.addComment:
        return Icons.comment;
      case RightClickMenuOption.addArtifact:
        return Icons.track_changes;
      case RightClickMenuOption.paste:
        return Icons.content_paste;
      case RightClickMenuOption.cut:
        return Icons.content_cut;
      case RightClickMenuOption.copy:
        return Icons.content_copy;
      case RightClickMenuOption.delete:
        return Icons.delete_outline;
      case RightClickMenuOption.snapToGrid:
        return Icons.grid_on;
      case RightClickMenuOption.showMinimap:
        return Icons.map;
      case RightClickMenuOption.showToolbar:
        return Icons.build;
      case RightClickMenuOption.importImage:
        return Icons.image;
      case RightClickMenuOption.getDiagramLink:
        return Icons.link;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the menu content directly since we're already in an overlay
    final screenSize = MediaQuery.of(context).size;

    // Calculate actual menu height including dividers and padding
    int dividerCount = 0;
    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (_shouldAddDivider(option, i > 0 ? widget.options[i - 1] : null)) {
        dividerCount++;
      }
    }

    final estimatedMenuHeight = (widget.options.length * 42.0) + // Menu items (40px + 2px margin)
        (dividerCount * 9.0) + // Dividers (1px + 4px margin each)
        16.0; // Top/bottom padding

    final safePosition = SafeMenuPosition.calculateSafePosition(
      preferredPosition: widget.globalPosition,
      menuSize: Size(220, estimatedMenuHeight), // Updated width and height
      screenSize: screenSize,
      padding: 16.0, // Increased padding for better visibility
    );

    // Store the actual menu position for submenu positioning
    _actualMenuPosition = safePosition;

    return Stack(
      children: [
        // Simple background for left click detection only
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Only handle left clicks to close menu
              widget.onClose();
            },
            // NO onSecondaryTap - let right clicks pass through completely
            child: Container(),
          ),
        ),
        // Main menu
        Positioned(
          left: safePosition.dx,
          top: safePosition.dy,
          child: _buildMenuContent(),
        ),
      ],
    );
  }
}

/// Separate stateful widget for submenu to handle its own hover state
class _SubmenuWidget extends StatefulWidget {
  final List<RightClickMenuOption> arrangeOptions;
  final Function(RightClickMenuOption) onItemTap;
  final bool Function(RightClickMenuOption) isOptionEnabled;
  final WidgetRef ref;

  const _SubmenuWidget({
    required this.arrangeOptions,
    required this.onItemTap,
    required this.isOptionEnabled,
    required this.ref,
  });

  @override
  State<_SubmenuWidget> createState() => _SubmenuWidgetState();
}

class _SubmenuWidgetState extends State<_SubmenuWidget> {
  String _hoveredSubmenuItemId = '';

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: ThemeHelper.black(context).withValues(alpha: 0.15),
      color: ThemeHelper.white(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.arrangeOptions.map((option) => _buildSubmenuItem(option)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuItem(RightClickMenuOption option) {
    bool isEnabled = widget.isOptionEnabled(option);
    final itemId = option.toString();

    return MouseRegion(
      onEnter: (_) {
        if (mounted && isEnabled) {
          setState(() {
            _hoveredSubmenuItemId = itemId;
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() {
            _hoveredSubmenuItemId = '';
          });
        }
      },
      child: GestureDetector(
        onTap: isEnabled ? () => widget.onItemTap(option) : null,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _hoveredSubmenuItemId == itemId && isEnabled ? ThemeHelper.neutral300(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _getSubmenuIcon(option),
                  size: 14,
                  color: isEnabled ? ThemeHelper.neutral700(context) : ThemeHelper.neutral500(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSubmenuItemText(option),
                    style: NarwhalTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? ThemeHelper.neutral700(context) : ThemeHelper.neutral500(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSubmenuIcon(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.sendBackward:
        return Icons.keyboard_arrow_down;
      case RightClickMenuOption.sendToBack:
        return Icons.keyboard_double_arrow_down;
      case RightClickMenuOption.bringForward:
        return Icons.keyboard_arrow_up;
      case RightClickMenuOption.bringToFront:
        return Icons.keyboard_double_arrow_up;
      default:
        return Icons.circle;
    }
  }

  String _getSubmenuItemText(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.sendBackward:
        return 'Send Backward';
      case RightClickMenuOption.sendToBack:
        return 'Send to Back';
      case RightClickMenuOption.bringForward:
        return 'Bring Forward';
      case RightClickMenuOption.bringToFront:
        return 'Bring to Front';
      default:
        return '';
    }
  }
}

/// Submenu widget for Import options (Video, Audio, Image)
class _ImportSubmenuWidget extends StatefulWidget {
  final List<RightClickMenuOption> importOptions;
  final Function(RightClickMenuOption) onItemTap;
  final WidgetRef ref;

  const _ImportSubmenuWidget({
    required this.importOptions,
    required this.onItemTap,
    required this.ref,
  });

  @override
  State<_ImportSubmenuWidget> createState() => _ImportSubmenuWidgetState();
}

class _ImportSubmenuWidgetState extends State<_ImportSubmenuWidget> {
  String _hoveredItemId = '';

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: ThemeHelper.black(context).withValues(alpha: 0.15),
      color: ThemeHelper.white(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.importOptions.map(_buildItem).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(RightClickMenuOption option) {
    final itemId = option.toString();
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemId = itemId),
      onExit: (_) => setState(() => _hoveredItemId = ''),
      child: GestureDetector(
        onTap: () => widget.onItemTap(option),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _hoveredItemId == itemId ? ThemeHelper.neutral300(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(_getIcon(option), size: 14, color: ThemeHelper.neutral700(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getText(option),
                    style: NarwhalTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.neutral700(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.importImage:
        return Icons.image;
      default:
        return Icons.circle;
    }
  }

  String _getText(RightClickMenuOption option) {
    switch (option) {
      case RightClickMenuOption.importImage:
        return 'Image';
      default:
        return '';
    }
  }
}
