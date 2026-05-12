import 'package:onyxia/export.dart';
import 'package:onyxia/helpers/safe_right_click_menu_position.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'dart:async';
import 'package:web/web.dart' as web;

class RightClickMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<RightClickMenuItem>? submenu;
  final bool dividerBefore;

  const RightClickMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.submenu,
    this.dividerBefore = false,
  });

  bool get enabled => onTap != null || submenu != null;
  bool get hasSubmenu => submenu != null;
}

OverlayEntry? _activeMenuOverlay;

void _closeAllMenus() {
  if (_activeMenuOverlay != null) {
    _activeMenuOverlay!.remove();
    _activeMenuOverlay!.dispose();
    _activeMenuOverlay = null;
  }
}

void canvasRightClick(
  BuildContext context,
  bool isMarkup,
  Offset globalPosition,
  Offset localPosition,
  WidgetRef ref, {
  CanvasObject? clickedObj,
}) {
  _closeAllMenus();

  final List<RightClickMenuItem> items;
  if (clickedObj == null) {
    items = _whitespaceItems(ref, isMarkup, localPosition);
  } else {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(clickedObj)) {
      ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
      ref.read(canvasObjectsProvider.notifier).selectObject(clickedObj);
    }
    items = _objectItems(ref, isMarkup, localPosition, clickedObj);
  }

  _activeMenuOverlay = OverlayEntry(
    builder: (_) => CanvasRightClickMenu(
      items: items,
      globalPosition: globalPosition,
      onClose: _closeAllMenus,
    ),
  );
  Overlay.of(context).insert(_activeMenuOverlay!);
}

List<RightClickMenuItem> _whitespaceItems(
  WidgetRef ref,
  bool isMarkup,
  Offset position,
) {
  final snapToGrid = ref.read(canvasSettingsProvider(Setting.snapToGrid));
  final showMinimap = ref.read(canvasSettingsProvider(Setting.showMinimap));
  final showToolbar = ref.read(canvasSettingsProvider(Setting.showToolbar));

  return [
    RightClickMenuItem(
      label: 'Add Comment',
      icon: Icons.comment,
      onTap: () => _addComment(ref, position, null),
    ),
    if (isMarkup)
      RightClickMenuItem(
        label: 'Add Pin',
        icon: Icons.track_changes,
        onTap: () => _addArtifact(ref, position, null, isMarkup),
      ),
    if (!isMarkup)
      RightClickMenuItem(
        label: 'Paste',
        icon: Icons.content_paste,
        onTap: () => _paste(ref, position),
        dividerBefore: true,
      ),
    if (!isMarkup)
      RightClickMenuItem(
        label: 'Turn ${snapToGrid ? 'off' : 'on'} snap to grid',
        icon: Icons.grid_on,
        onTap: () => _toggleSetting(ref, Setting.snapToGrid),
        dividerBefore: true,
      ),
    RightClickMenuItem(
      label: '${showMinimap ? 'Hide' : 'Show'} mini-map',
      icon: Icons.map,
      onTap: () => _toggleSetting(ref, Setting.showMinimap),
    ),
    if (!isMarkup)
      RightClickMenuItem(
        label: '${showToolbar ? 'Hide' : 'Show'} toolbar',
        icon: Icons.build,
        onTap: () => _toggleSetting(ref, Setting.showToolbar),
      ),
    RightClickMenuItem(
      label: 'Get link to diagram',
      icon: Icons.link,
      onTap: _copyDiagramLink,
    ),
  ];
}

List<RightClickMenuItem> _objectItems(
  WidgetRef ref,
  bool isMarkup,
  Offset position,
  CanvasObject clickedObj,
) {
  final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
  final canMoveBackward = objectsNotifier.canMoveBackward(clickedObj);
  final canMoveForward = objectsNotifier.canMoveForward(clickedObj);

  return [
    RightClickMenuItem(
      label: 'Add Comment',
      icon: Icons.comment,
      onTap: () => _addComment(ref, position, clickedObj),
    ),
    RightClickMenuItem(
      label: 'Add Pin',
      icon: Icons.track_changes,
      onTap: () => _addArtifact(ref, position, clickedObj, isMarkup),
    ),
    RightClickMenuItem(
      label: 'Cut',
      icon: Icons.content_cut,
      onTap: () => _cut(ref),
      dividerBefore: true,
    ),
    RightClickMenuItem(
      label: 'Copy',
      icon: Icons.content_copy,
      onTap: () => _copy(ref),
    ),
    RightClickMenuItem(
      label: 'Delete',
      icon: Icons.delete_outline,
      onTap: () => _delete(ref),
    ),
    RightClickMenuItem(
      label: 'Arrange',
      icon: Icons.layers,
      dividerBefore: true,
      submenu: [
        RightClickMenuItem(
          label: 'Bring Forward',
          icon: Icons.keyboard_arrow_up,
          onTap: canMoveForward
              ? () => _moveObjects(ref, clickedObj, _MoveDirection.forward)
              : null,
        ),
        RightClickMenuItem(
          label: 'Bring to Front',
          icon: Icons.keyboard_double_arrow_up,
          onTap: canMoveForward
              ? () => _moveObjects(ref, clickedObj, _MoveDirection.toFront)
              : null,
        ),
        RightClickMenuItem(
          label: 'Send Backward',
          icon: Icons.keyboard_arrow_down,
          onTap: canMoveBackward
              ? () => _moveObjects(ref, clickedObj, _MoveDirection.backward)
              : null,
        ),
        RightClickMenuItem(
          label: 'Send to Back',
          icon: Icons.keyboard_double_arrow_down,
          onTap: canMoveBackward
              ? () => _moveObjects(ref, clickedObj, _MoveDirection.toBack)
              : null,
        ),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Action handlers
// ---------------------------------------------------------------------------

Future<void> _addComment(
  WidgetRef ref,
  Offset position,
  CanvasObject? targetObject,
) =>
    CanvasInteractionService.createComment(
      ref: ref,
      position: position,
      targetObject: targetObject,
    );

void _addArtifact(
  WidgetRef ref,
  Offset position,
  CanvasObject? targetObject,
  bool isMarkup,
) {
  if (targetObject == null && !isMarkup) return;
  CanvasInteractionService.createPin(
    ref: ref,
    position: position,
    item: null,
    targetObject: targetObject,
  );
}

Future<void> _paste(WidgetRef ref, Offset position) async {
  final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
  final pasted = await CanvasClipboardService.paste(
    targetPosition: position,
    ref: ref,
  );
  objectsNotifier.addObjects(ref, pasted.$1);
  objectsNotifier.clearSelectedObjects();
  ref.read(pinsProvider.notifier).addPins(ref, pasted.$2);
}

Future<void> _cut(WidgetRef ref) async {
  final selected = ref.read(canvasObjectsProvider).selectedObjects;
  await CanvasClipboardService.copy(objects: selected);
  ref.read(canvasObjectsProvider.notifier).deleteObjects(ref, selected);
}

Future<void> _copy(WidgetRef ref) async {
  final selected = ref.read(canvasObjectsProvider).selectedObjects;
  await CanvasClipboardService.copy(objects: selected);
}

void _delete(WidgetRef ref) {
  final selected = ref.read(canvasObjectsProvider).selectedObjects;
  ref.read(canvasObjectsProvider.notifier).deleteObjects(ref, selected);
}

void _toggleSetting(WidgetRef ref, Setting setting) {
  ref.read(canvasSettingsProvider(setting).notifier).update((state) => !state);
}

void _copyDiagramLink() {
  Clipboard.setData(ClipboardData(text: web.window.location.href));
  NarwhalToast.show(
    text: 'Link copied to clipboard',
    type: ToastType.success,
  );
}

enum _MoveDirection { forward, backward, toFront, toBack }

void _moveObjects(
  WidgetRef ref,
  CanvasObject clickedObj,
  _MoveDirection direction,
) {
  final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
  final selected = ref.read(canvasObjectsProvider).selectedObjects;
  final targets = selected.isNotEmpty ? selected : [clickedObj];

  for (final obj in targets) {
    switch (direction) {
      case _MoveDirection.forward:
        objectsNotifier.moveObjectForward(ref, obj);
        break;
      case _MoveDirection.backward:
        objectsNotifier.moveObjectBackward(ref, obj);
        break;
      case _MoveDirection.toFront:
        objectsNotifier.moveObjectToFront(ref, obj);
        break;
      case _MoveDirection.toBack:
        objectsNotifier.moveObjectToBack(ref, obj);
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

const double _menuWidth = 220;
const double _submenuWidth = 200;
const double _itemHeight = 40;
const double _itemRowHeight = 42; // item + 2px vertical margin
const double _submenuItemHeight = 36;
const double _submenuItemRowHeight = 38;
const double _dividerSlot = 9; // 1px line + 8px vertical margin
const double _menuVerticalPadding = 16; // 8px top + 8px bottom
const Duration _submenuOpenDelay = Duration(milliseconds: 200);
const Duration _submenuCloseDelay = Duration(milliseconds: 150);

class CanvasRightClickMenu extends StatefulWidget {
  final List<RightClickMenuItem> items;
  final Offset globalPosition;
  final VoidCallback onClose;

  const CanvasRightClickMenu({
    super.key,
    required this.items,
    required this.globalPosition,
    required this.onClose,
  });

  @override
  State<CanvasRightClickMenu> createState() => _CanvasRightClickMenuState();
}

class _CanvasRightClickMenuState extends State<CanvasRightClickMenu> {
  int _hoveredIndex = -1;
  int _submenuParentIndex = -1;
  bool _hoveringSubmenu = false;
  OverlayEntry? _submenuOverlay;
  Timer? _openDelay;
  Timer? _closeDelay;
  Offset _menuPosition = Offset.zero;

  @override
  void dispose() {
    _openDelay?.cancel();
    _closeDelay?.cancel();
    _closeSubmenu();
    super.dispose();
  }

  double _menuHeight(List<RightClickMenuItem> items) {
    final dividerCount = items.where((i) => i.dividerBefore).length;
    return items.length * _itemRowHeight +
        dividerCount * _dividerSlot +
        _menuVerticalPadding;
  }

  double _itemOffsetY(int index) {
    double offset = 8;
    for (int i = 0; i < index; i++) {
      if (widget.items[i].dividerBefore) offset += _dividerSlot;
      offset += _itemRowHeight;
    }
    if (widget.items[index].dividerBefore) offset += _dividerSlot;
    return offset;
  }

  void _onHoverItem(int index, bool entering) {
    if (!mounted) return;
    final item = widget.items[index];

    if (entering) {
      setState(() => _hoveredIndex = index);
      if (item.hasSubmenu) {
        _closeDelay?.cancel();
        _openDelay?.cancel();
        _openDelay = Timer(_submenuOpenDelay, () {
          if (!mounted) return;
          if (_hoveredIndex == index) _openSubmenu(index);
        });
      } else {
        _scheduleSubmenuClose();
      }
    } else {
      setState(() {
        if (_hoveredIndex == index) _hoveredIndex = -1;
      });
      if (item.hasSubmenu) {
        _openDelay?.cancel();
        _scheduleSubmenuClose();
      }
    }
  }

  void _openSubmenu(int index) {
    _closeSubmenu();
    final item = widget.items[index];
    if (item.submenu == null) return;

    final screen = MediaQuery.of(context).size;
    final submenuHeight =
        item.submenu!.length * _submenuItemRowHeight + _menuVerticalPadding;
    final anchorY = _menuPosition.dy + _itemOffsetY(index);

    double top = anchorY;
    if (top + submenuHeight > screen.height - 16) {
      top = anchorY - submenuHeight;
      if (top < 16) top = screen.height - submenuHeight - 16;
    }

    double left = _menuPosition.dx + _menuWidth + 2;
    if (left + _submenuWidth > screen.width - 16) {
      left = _menuPosition.dx - _submenuWidth - 2;
      if (left < 16) left = 16;
    }

    setState(() => _submenuParentIndex = index);

    _submenuOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: MouseRegion(
          onEnter: (_) {
            _closeDelay?.cancel();
            if (!mounted) return;
            setState(() => _hoveringSubmenu = true);
          },
          onExit: (_) {
            if (!mounted) return;
            setState(() => _hoveringSubmenu = false);
            _scheduleSubmenuClose();
          },
          child: _SubmenuPanel(
            items: item.submenu!,
            onItemTap: (subItem) {
              subItem.onTap?.call();
              widget.onClose();
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_submenuOverlay!);
  }

  void _closeSubmenu() {
    _submenuOverlay?.remove();
    _submenuOverlay = null;
    if (mounted) setState(() => _submenuParentIndex = -1);
  }

  void _scheduleSubmenuClose() {
    _closeDelay?.cancel();
    _closeDelay = Timer(_submenuCloseDelay, () {
      if (!mounted) return;
      final parentStillHovered =
          _submenuParentIndex >= 0 && _hoveredIndex == _submenuParentIndex;
      if (!parentStillHovered && !_hoveringSubmenu) _closeSubmenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    _menuPosition = SafeMenuPosition.calculateSafePosition(
      preferredPosition: widget.globalPosition,
      menuSize: Size(_menuWidth, _menuHeight(widget.items)),
      screenSize: screen,
      padding: 16.0,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onClose,
            child: const SizedBox(),
          ),
        ),
        Positioned(
          left: _menuPosition.dx,
          top: _menuPosition.dy,
          child: _MenuPanel(
            width: _menuWidth,
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (widget.items[i].dividerBefore) const _MenuDivider(),
                _MenuRow(
                  item: widget.items[i],
                  highlighted: _hoveredIndex == i || _submenuParentIndex == i,
                  showChevron: widget.items[i].hasSubmenu,
                  itemHeight: _itemHeight,
                  onEnter: () => _onHoverItem(i, true),
                  onExit: () => _onHoverItem(i, false),
                  onTap: widget.items[i].hasSubmenu
                      ? null
                      : () {
                          widget.items[i].onTap?.call();
                          widget.onClose();
                        },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmenuPanel extends StatefulWidget {
  final List<RightClickMenuItem> items;
  final ValueChanged<RightClickMenuItem> onItemTap;

  const _SubmenuPanel({required this.items, required this.onItemTap});

  @override
  State<_SubmenuPanel> createState() => _SubmenuPanelState();
}

class _SubmenuPanelState extends State<_SubmenuPanel> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return _MenuPanel(
      width: _submenuWidth,
      children: [
        for (int i = 0; i < widget.items.length; i++)
          _MenuRow(
            item: widget.items[i],
            highlighted: _hoveredIndex == i && widget.items[i].enabled,
            showChevron: false,
            itemHeight: _submenuItemHeight,
            onEnter: () {
              if (widget.items[i].enabled && mounted) {
                setState(() => _hoveredIndex = i);
              }
            },
            onExit: () {
              if (mounted) setState(() => _hoveredIndex = -1);
            },
            onTap: widget.items[i].enabled
                ? () => widget.onItemTap(widget.items[i])
                : null,
          ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final double width;
  final List<Widget> children;

  const _MenuPanel({required this.width, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: ThemeHelper.black(context).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
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
            children: children,
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeHelper.neutral500(context).withValues(alpha: 0.2),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final RightClickMenuItem item;
  final bool highlighted;
  final bool showChevron;
  final double itemHeight;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.item,
    required this.highlighted,
    required this.showChevron,
    required this.itemHeight,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = item.enabled
        ? ThemeHelper.neutral700(context)
        : ThemeHelper.neutral500(context);

    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: highlighted
                ? ThemeHelper.neutral300(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: textColor),
                  const Gap(8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: NarwhalTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (showChevron)
                  Icon(Icons.chevron_right, size: 18, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
