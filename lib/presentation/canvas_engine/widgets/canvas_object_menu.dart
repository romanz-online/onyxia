import 'package:onyxia/export.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasObjectMenu extends ConsumerStatefulWidget {
  final VoidCallback openTextEditor;
  final VoidCallback closeTextEditor;
  final void Function(CanvasObject) saveTextEditor;

  const CanvasObjectMenu({
    super.key,
    required this.openTextEditor,
    required this.closeTextEditor,
    required this.saveTextEditor,
  });

  @override
  CanvasObjectMenuState createState() => CanvasObjectMenuState();
}

enum CanvasObjectMenuOption {
  mediaSource,
  color,
  stroke,
  shape,
  startArrowTip,
  endArrowTip,
  arrowType,
  textfield,
  none,
}

class CanvasObjectMenuState extends ConsumerState<CanvasObjectMenu> {
  CanvasObjectMenuOption _activeMenuOption = CanvasObjectMenuOption.none;
  List<CanvasObject> _selectedObjects = [];

  static const shapeOptions = [
    CanvasObjectMenuOption.shape,
    CanvasObjectMenuOption.color,
    CanvasObjectMenuOption.stroke,
  ];

  static const imageOptions = [CanvasObjectMenuOption.mediaSource];

  static const textOptions = [CanvasObjectMenuOption.textfield];

  static const arrowOptions = [
    CanvasObjectMenuOption.color,
    CanvasObjectMenuOption.stroke,
    CanvasObjectMenuOption.startArrowTip,
    CanvasObjectMenuOption.endArrowTip,
    CanvasObjectMenuOption.arrowType,
    CanvasObjectMenuOption.textfield,
  ];

  static const brushOptions = [CanvasObjectMenuOption.color];

  static const double menuSpacing = CanvasBounds.gridSpacing * 2.0;
  static const double borderWidth = 1.0;
  static const double buttonBorderRadius = 8.0;
  static const double menuPadding = 6.0;

  static const double iconSize = 32.0;

  @override
  void initState() {
    super.initState();
  }

  void _toggleMenuOption(CanvasObjectMenuOption option) {
    setState(() {
      _activeMenuOption = _activeMenuOption == option
          ? CanvasObjectMenuOption.none
          : option;
    });
  }

  void _closeSubmenu() {
    if (_activeMenuOption == CanvasObjectMenuOption.none) return;
    setState(() => _activeMenuOption = CanvasObjectMenuOption.none);
  }

  @override
  Widget build(BuildContext context) {
    final currentSelected = ref
        .read(canvasObjectsProvider)
        .selectedObjects
        .where((e) => !e.isArtifact)
        .toList();
    if (!listEquals(_selectedObjects, currentSelected)) _closeSubmenu();

    _selectedObjects = currentSelected;

    if (ref.watch(headlessProvider).isVisible || _selectedObjects.isEmpty) {
      return const SizedBox.shrink();
    }

    List<CanvasObjectMenuOption> menuOptions = _getCommonMenuOptions(
      _selectedObjects,
    );

    if (!menuOptions.contains(_activeMenuOption)) {
      _closeSubmenu();
    }

    // Calculate bounds for each object, computing arrow bounds inline
    final List<double> leftBounds = [];
    final List<double> topBounds = [];
    final List<double> rightBounds = [];
    final List<double> bottomBounds = [];

    for (final obj in _selectedObjects) {
      leftBounds.add(obj.topLeft.dx);
      topBounds.add(obj.topLeft.dy);
      rightBounds.add(obj.bottomRight.dx);
      bottomBounds.add(obj.bottomRight.dy);
    }

    final double minX = leftBounds.reduce(math.min);
    final double minY = topBounds.reduce(math.min);
    final double maxX = rightBounds.reduce(math.max);
    final double maxY = bottomBounds.reduce(math.max);

    // Calculate center X and top/bottom Y for the bounding rectangle
    final objectCenterX = (minX + maxX) / 2;
    final objectTopY = minY;
    final objectBottomY = maxY;

    final transform = ref.watch(canvasViewportProvider).value;
    final double scale = transform.getMaxScaleOnAxis();

    // Transform the object's positions from canvas coordinates to screen coordinates
    final objectCenterScreenPoint = MatrixUtils.transformPoint(
      transform,
      Offset(objectCenterX, objectTopY),
    );
    final objectBottomScreenPoint = MatrixUtils.transformPoint(
      transform,
      Offset(objectCenterX, objectBottomY),
    );

    // targetY: desired bottom of main menu when placed above objects
    final targetY =
        objectCenterScreenPoint.dy -
        (CanvasBounds.gridSpacing * scale) -
        menuSpacing;
    // belowTargetY: desired top of main menu when placed below objects
    final belowTargetY =
        objectBottomScreenPoint.dy +
        (CanvasBounds.gridSpacing * scale) +
        menuSpacing;

    // Get viewport dimensions
    final screenSize = MediaQuery.of(context).size;
    final viewportWidth = screenSize.width;
    final viewportHeight = screenSize.height;

    Widget? submenuContent;
    bool? submenuPrefersAbove;
    bool submenuFloatRight = false;

    if (_activeMenuOption != CanvasObjectMenuOption.none) {
      (submenuContent, submenuPrefersAbove) = switch (_activeMenuOption) {
        CanvasObjectMenuOption.color => (_buildColorPalette(), true),
        CanvasObjectMenuOption.stroke => (_buildStrokePalette(), true),
        CanvasObjectMenuOption.shape => (_buildShapePalette(), true),
        CanvasObjectMenuOption.startArrowTip => (
          _buildArrowTipPalette(tipOnRight: false),
          true,
        ),
        CanvasObjectMenuOption.endArrowTip => (
          _buildArrowTipPalette(tipOnRight: true),
          true,
        ),
        CanvasObjectMenuOption.arrowType => (_buildArrowTypePalette(), true),
        _ => throw UnimplementedError(
          'Submenu not implemented for $_activeMenuOption',
        ),
      };
    }

    return CustomMultiChildLayout(
      delegate: _CanvasMenuLayoutDelegate(
        targetX: objectCenterScreenPoint.dx,
        targetY: targetY,
        belowTargetY: belowTargetY,
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
        submenuPrefersAbove: submenuPrefersAbove,
        submenuFloatRight: submenuFloatRight,
      ),
      children: [
        LayoutId(
          id: _CanvasMenuChild.mainMenu,
          child: Consumer(
            key: ValueKey(_selectedObjects.map((o) => o.id).join(',')),
            builder: (context, ref, child) {
              return GridPalette(
                buttons: _buildMenuOptions(menuOptions),
                rows: 1,
                context: context,
              );
            },
          ),
        ),
        if (submenuContent != null)
          LayoutId(id: _CanvasMenuChild.submenu, child: submenuContent),
      ],
    );
  }

  List<CanvasObjectMenuOption> getObjectOptions(CanvasObjectType objectType) =>
      switch (objectType) {
        CanvasObjectType.text => textOptions,
        CanvasObjectType.image => imageOptions,
        CanvasObjectType.arrow => arrowOptions,
        CanvasObjectType.brush => brushOptions,
        _ => shapeOptions,
      };

  List<CanvasObjectMenuOption> _getCommonMenuOptions(
    List<CanvasObject> selectedObjects,
  ) {
    if (selectedObjects.isEmpty) return [];

    final commonOptions = getObjectOptions(selectedObjects.first.type).toSet();
    for (final obj in selectedObjects.skip(1)) {
      commonOptions.retainAll(getObjectOptions(obj.type));
    }

    if (selectedObjects.length != 1) {
      commonOptions.remove(CanvasObjectMenuOption.textfield);
    }

    return commonOptions.toList();
  }

  List<Widget> _buildMenuOptions(List<CanvasObjectMenuOption> options) {
    List<Widget> buttons = [];
    for (final opt in options) {
      switch (opt) {
        case CanvasObjectMenuOption.mediaSource:
          buttons.add(
            OnyxiaIconButton(
              icon: LucideIcons.image,
              onPressed: () async {
                final selectedObjects = ref
                    .read(canvasObjectsProvider)
                    .selectedObjects;
                if (selectedObjects.isNotEmpty) {
                  final selectedObject = selectedObjects[0];
                  String? url = null;
                  if (selectedObject.isImage &&
                      selectedObject.imageProps.imageUrl.isNotEmpty) {
                    url = selectedObject.imageProps.imageUrl;
                  }

                  if (url != null)
                    await launchUrl(
                      Uri.parse(url),
                      webOnlyWindowName: '_blank',
                    );
                }
              },
              isSelected: false,
            ),
          );
          break;
        case CanvasObjectMenuOption.shape:
          final isSelected = _activeMenuOption == opt;
          final icon = switch (_selectedObjects[0].type) {
            CanvasObjectType.rectangle => LucideIcons.square,
            CanvasObjectType.diamond => LucideIcons.diamond,
            CanvasObjectType.oblong => LucideIcons.rectangleHorizontal,
            CanvasObjectType.circle => LucideIcons.circle,
            CanvasObjectType.rhombus => LucideIcons.diamond,
            CanvasObjectType.trapezoid => LucideIcons.pentagon,
            CanvasObjectType.cylinder => LucideIcons.cylinder,
            CanvasObjectType.house => LucideIcons.house,
            CanvasObjectType.reverseHouse => LucideIcons.house,
            _ => LucideIcons.square,
          };

          buttons.add(
            OnyxiaIconButton(
              icon: icon,
              onPressed: () => _toggleMenuOption(opt),
              isSelected: isSelected,
              isPressed: isSelected,
              hasCaret: true,
            ),
          );
          buttons.add(_buildDivider());
          break;
        case CanvasObjectMenuOption.color:
          final isSelected = _activeMenuOption == opt;
          buttons.add(
            Stack(
              alignment: .center,
              children: [
                // Radial gradient shadow layer (beneath button)
                Padding(
                  padding: .only(right: 18),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: .circle,
                      gradient: RadialGradient(
                        colors: [Colors.black, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Button on top
                OnyxiaIconButton(
                  icon: LucideIcons.palette,
                  iconColor: _selectedObjects.isEmpty
                      ? null
                      : _selectedObjects[0].color,
                  onPressed: () => _toggleMenuOption(opt),
                  isSelected: isSelected,
                  isPressed: isSelected,
                  hasCaret: true,
                ),
              ],
            ),
          );
          break;
        case CanvasObjectMenuOption.stroke:
          final isSelected = _activeMenuOption == opt;
          buttons.add(
            OnyxiaIconButton(
              icon: LucideIcons.minus,
              onPressed: () => _toggleMenuOption(opt),
              isSelected: isSelected,
              isPressed: isSelected,
              hasCaret: true,
            ),
          );
          break;
        case CanvasObjectMenuOption.startArrowTip:
          final isSelected = _activeMenuOption == opt;
          final icon = switch (_selectedObjects[0].arrowProps.startTip) {
            .triangle => LucideIcons.arrowLeft,
            .circle => LucideIcons.circle,
            .none => LucideIcons.ban,
          };
          buttons.add(
            OnyxiaIconButton(
              icon: icon,
              onPressed: () => _toggleMenuOption(opt),
              isSelected: isSelected,
              hasCaret: true,
            ),
          );
          break;
        case CanvasObjectMenuOption.endArrowTip:
          final isSelected = _activeMenuOption == opt;
          final icon = switch (_selectedObjects[0].arrowProps.endTip) {
            .triangle => LucideIcons.arrowRight,
            .circle => LucideIcons.circle,
            .none => LucideIcons.ban,
          };
          buttons.add(
            OnyxiaIconButton(
              icon: icon,
              onPressed: () => _toggleMenuOption(opt),
              isSelected: isSelected,
              hasCaret: true,
            ),
          );
          break;
        case CanvasObjectMenuOption.arrowType:
          final isSelected = _activeMenuOption == opt;
          final icon = switch (_selectedObjects[0].arrowProps.arrowType) {
            .segmented => LucideIcons.cornerDownRight,
            .curved => LucideIcons.trendingUp,
          };
          buttons.add(
            OnyxiaIconButton(
              icon: icon,
              onPressed: () => _toggleMenuOption(opt),
              isSelected: isSelected,
              hasCaret: true,
            ),
          );
          break;
        case CanvasObjectMenuOption.textfield:
          final isSelected = ref.watch(canvasTextProvider.notifier).isEditing;
          buttons.add(
            OnyxiaIconButton(
              icon: LucideIcons.type,
              onPressed: () {
                if (isSelected) {
                  widget.closeTextEditor();
                  _closeSubmenu();
                } else {
                  widget.openTextEditor();
                }
              },
              isSelected: isSelected,
            ),
          );
          break;
        case CanvasObjectMenuOption.none:
          break;
      }
    }
    return buttons;
  }

  Widget _buildDivider() =>
      Container(width: 0.5, height: iconSize, color: ThemeHelper.neutral600());

  // SUB-MENUS

  Widget _buildColorPalette() {
    final List<Color> colorPalette = [
      ThemeHelper.neutral100(),
      ThemeHelper.neutral600(),
      NarwhalColors.red800,
      NarwhalColors.orange700,
      NarwhalColors.green700,
      NarwhalColors.blue300,
      NarwhalColors.purple500,
      ThemeHelper.neutral900(),
      ThemeHelper.neutral500(),
      NarwhalColors.red900,
      NarwhalColors.orange800,
      NarwhalColors.green800,
      NarwhalColors.blue600,
      NarwhalColors.purple600,
    ];

    final objectsNotifier = ref.read(canvasObjectsProvider.notifier);

    return GridPalette(
      buttons: colorPalette
          .map(
            (color) => OnyxiaIconButton(
              icon: LucideIcons.palette,
              iconColor: color,
              onPressed: () {
                for (final obj in _selectedObjects) {
                  obj.color = color;
                }
                objectsNotifier.updateObjects(objects: _selectedObjects);
              },
              isSelected: _selectedObjects[0].color == color,
            ),
          )
          .toList(),
      rows: 2,
      context: context,
    );
  }

  Widget _buildStrokePalette() {
    List<Widget> buttons = [
      OnyxiaIconButton(
        icon: LucideIcons.ellipsis,
        onPressed: () {
          for (final obj in _selectedObjects) {
            obj.stroke = .dashed;
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: _selectedObjects[0].stroke == .dashed,
      ),
      OnyxiaIconButton(
        icon: LucideIcons.minus,
        onPressed: () {
          for (final obj in _selectedObjects) {
            obj.stroke = .solid;
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: _selectedObjects[0].stroke == .solid,
      ),
      OnyxiaIconButton(
        icon: LucideIcons.equal,
        onPressed: () {
          for (final obj in _selectedObjects) {
            obj.stroke = .thick;
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: _selectedObjects[0].stroke == .thick,
      ),
    ];

    return GridPalette(buttons: buttons, rows: 1, context: context);
  }

  Widget _buildShapePalette() {
    final List<CanvasObjectType> shapeOptions = [
      CanvasObjectType.rectangle,
      CanvasObjectType.diamond,
      CanvasObjectType.oblong,
      CanvasObjectType.circle,
      CanvasObjectType.rhombus,
      CanvasObjectType.trapezoid,
      CanvasObjectType.cylinder,
      CanvasObjectType.house,
      CanvasObjectType.reverseHouse,
    ];

    final Map<CanvasObjectType, IconData> shapeIcons = {
      CanvasObjectType.rectangle: LucideIcons.square,
      CanvasObjectType.diamond: LucideIcons.diamond,
      CanvasObjectType.oblong: LucideIcons.rectangleHorizontal,
      CanvasObjectType.circle: LucideIcons.circle,
      CanvasObjectType.rhombus: LucideIcons.diamond,
      CanvasObjectType.trapezoid: LucideIcons.pentagon,
      CanvasObjectType.cylinder: LucideIcons.cylinder,
      CanvasObjectType.house: LucideIcons.house,
      CanvasObjectType.reverseHouse: LucideIcons.house,
    };

    List<Widget> buttons = shapeOptions
        .map(
          (shapeType) => OnyxiaIconButton(
            icon: shapeIcons[shapeType]!,
            onPressed: () {
              for (final obj in _selectedObjects) {
                obj.type = shapeType;
              }
              ref
                  .read(canvasObjectsProvider.notifier)
                  .updateObjects(objects: _selectedObjects);
            },
            isSelected: _selectedObjects[0].type == shapeType,
          ),
        )
        .toList();

    return GridPalette(buttons: buttons, rows: 2, context: context);
  }

  Widget _buildArrowTipPalette({required tipOnRight}) {
    ArrowTip selectedTip = tipOnRight
        ? _selectedObjects[0].arrowProps.endTip
        : _selectedObjects[0].arrowProps.startTip;

    List<Widget> buttons = [
      // Circle tip
      OnyxiaIconButton(
        icon: tipOnRight ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
        onPressed: () {
          for (final obj in _selectedObjects) {
            if (tipOnRight) {
              obj.arrowProps.endTip = ArrowTip.circle;
            } else {
              obj.arrowProps.startTip = ArrowTip.circle;
            }
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: selectedTip == ArrowTip.circle,
      ),

      // Triangle tip
      OnyxiaIconButton(
        icon: tipOnRight ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
        onPressed: () {
          for (final obj in _selectedObjects) {
            if (tipOnRight) {
              obj.arrowProps.endTip = ArrowTip.triangle;
            } else {
              obj.arrowProps.startTip = ArrowTip.triangle;
            }
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: selectedTip == ArrowTip.triangle,
      ),

      // No tip
      OnyxiaIconButton(
        icon: LucideIcons.ban,
        onPressed: () {
          for (final obj in _selectedObjects) {
            if (tipOnRight) {
              obj.arrowProps.endTip = ArrowTip.none;
            } else {
              obj.arrowProps.startTip = ArrowTip.none;
            }
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: selectedTip == ArrowTip.none,
      ),
    ];

    return GridPalette(buttons: buttons, rows: 1, context: context);
  }

  Widget _buildArrowTypePalette() {
    ArrowType selectedType = _selectedObjects[0].arrowProps.arrowType;

    List<Widget> buttons = [
      // Segmented type
      OnyxiaIconButton(
        icon: LucideIcons.cornerDownRight,
        onPressed: () {
          for (final obj in _selectedObjects) {
            obj.arrowProps.arrowType = ArrowType.segmented;
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: selectedType == ArrowType.segmented,
      ),

      // Curved type
      OnyxiaIconButton(
        icon: LucideIcons.trendingUp,
        onPressed: () {
          for (final obj in _selectedObjects) {
            obj.arrowProps.arrowType = ArrowType.curved;
          }
          ref
              .read(canvasObjectsProvider.notifier)
              .updateObjects(objects: _selectedObjects);
        },
        isSelected: selectedType == ArrowType.curved,
      ),
    ];

    return GridPalette(buttons: buttons, rows: 1, context: context);
  }
}

/// A widget that arranges buttons in a grid with a specified number of rows.
/// Automatically distributes buttons evenly across rows.
class GridPalette extends StatelessWidget {
  final List<Widget> buttons;
  final int rows;
  final double padding;
  final BuildContext context;

  const GridPalette({
    super.key,
    required this.buttons,
    required this.rows,
    required this.context,
    this.padding = CanvasObjectMenuState.menuPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();

    // Calculate buttons per row
    final int totalButtons = buttons.length;
    final int buttonsPerRow = (totalButtons / rows).ceil();

    // Build rows
    List<Widget> rowWidgets = [];
    for (int i = 0; i < rows; i++) {
      final int startIndex = i * buttonsPerRow;
      final int endIndex = math.min(startIndex + buttonsPerRow, totalButtons);

      if (startIndex < totalButtons) {
        final rowButtons = buttons.sublist(startIndex, endIndex);
        // Wrap each button in padding
        final wrappedButtons = rowButtons
            .map((button) => Padding(padding: .all(6), child: button))
            .toList();
        rowWidgets.add(Row(mainAxisSize: .min, children: wrappedButtons));
      }
    }

    return Material(
      elevation: 2,
      borderRadius: .circular(CanvasObjectMenuState.buttonBorderRadius),
      color: ThemeHelper.neutral800(),
      child: Container(
        decoration: BoxDecoration(
          border: .all(
            color: ThemeHelper.neutral600(),
            width: CanvasObjectMenuState.borderWidth,
          ),
          borderRadius: .circular(CanvasObjectMenuState.buttonBorderRadius),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(minHeight: 54),
              child: Center(
                child: Column(mainAxisSize: .min, children: rowWidgets),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CanvasMenuChild { mainMenu, submenu }

/// Positions the main menu and optional submenu in a single layout pass.
/// The main menu is centered at [targetX], flipping below objects if it
/// won't fit above. The submenu is positioned relative to the actual
/// (measured) main menu bounds — no GlobalKey lag.
class _CanvasMenuLayoutDelegate extends MultiChildLayoutDelegate {
  final double targetX;
  final double targetY;
  final double belowTargetY;
  final double viewportWidth;
  final double viewportHeight;
  final bool? submenuPrefersAbove; // null = no submenu
  final bool submenuFloatRight;

  _CanvasMenuLayoutDelegate({
    required this.targetX,
    required this.targetY,
    required this.belowTargetY,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.submenuPrefersAbove,
    required this.submenuFloatRight,
  });

  static const double _margin = 16.0;
  static const double _gap = 4.0;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout(Size size) {
    // 1. Main menu — measure first to get its actual size
    final mmSize = layoutChild(
      _CanvasMenuChild.mainMenu,
      const BoxConstraints(),
    );
    final double mmAboveTop = targetY - mmSize.height;
    final bool flipped = mmAboveTop < _margin;
    final double mmY = (flipped ? belowTargetY : mmAboveTop).clamp(
      _margin,
      viewportHeight - mmSize.height - _margin,
    );
    final double mmX = (targetX - mmSize.width / 2).clamp(
      _margin,
      viewportWidth - mmSize.width - _margin,
    );
    positionChild(_CanvasMenuChild.mainMenu, Offset(mmX, mmY));

    // 2. Submenu — positioned relative to measured main menu bounds
    if (hasChild(_CanvasMenuChild.submenu)) {
      final smSize = layoutChild(
        _CanvasMenuChild.submenu,
        const BoxConstraints(),
      );

      // X: right-align to main menu's right edge, or center at targetX
      final double smX = submenuFloatRight
          ? (mmX + mmSize.width - smSize.width).clamp(
              _margin,
              viewportWidth - smSize.width - _margin,
            )
          : (targetX - smSize.width / 2).clamp(
              _margin,
              viewportWidth - smSize.width - _margin,
            );

      // Y: above or below main menu
      final double mmBottom = mmY + mmSize.height;
      final double smY;
      if (flipped) {
        smY = mmBottom + _gap;
      } else if (submenuPrefersAbove == true) {
        final double aboveTop = mmY - _gap - smSize.height;
        smY = aboveTop < _margin ? mmBottom + _gap : aboveTop;
      } else {
        smY = mmBottom + _gap;
      }

      positionChild(
        _CanvasMenuChild.submenu,
        Offset(
          smX,
          smY.clamp(_margin, viewportHeight - smSize.height - _margin),
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_CanvasMenuLayoutDelegate old) =>
      targetX != old.targetX ||
      targetY != old.targetY ||
      belowTargetY != old.belowTargetY ||
      viewportWidth != old.viewportWidth ||
      viewportHeight != old.viewportHeight ||
      submenuPrefersAbove != old.submenuPrefersAbove ||
      submenuFloatRight != old.submenuFloatRight;
}
