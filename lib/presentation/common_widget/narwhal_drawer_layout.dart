import 'package:flutter/material.dart';
import 'package:onyxia/presentation/common_widget/narwhal_drawer.dart';
import 'package:onyxia/helpers/theme_helper.dart';

/// Callback function types for drawer events
typedef OnDrawerDragStart =
    void Function(String drawerId, Offset position, Size size);
typedef OnDrawerDragUpdate =
    void Function(String drawerId, Offset position, Size size);
typedef OnDrawerDragEnd =
    void Function(String drawerId, Offset position, Size size);
typedef OnDrawerModeChangeRequest =
    void Function(
      String drawerId,
      NarwhalDrawerMode mode,
      Offset position,
      Size size,
    );
typedef OnDrawerWidthUpdate = void Function(String drawerId, double width);
typedef OnDrawerVisibilityUpdate =
    void Function(String drawerId, bool isVisible);

/// InheritedWidget that provides drawer layout callbacks to descendant drawers
class NarwhalDrawerLayoutProvider extends InheritedWidget {
  final double snapThreshold;
  final double snapHintWidth;
  final OnDrawerDragStart? onDragStart;
  final OnDrawerDragUpdate? onDragUpdate;
  final OnDrawerDragEnd? onDragEnd;
  final OnDrawerModeChangeRequest? onModeChangeRequest;
  final OnDrawerWidthUpdate? onWidthUpdate;
  final OnDrawerVisibilityUpdate? onVisibilityUpdate;

  // Registration methods for drawer states
  final void Function(String drawerId, NarwhalDrawerState state)?
  registerDrawer;
  final void Function(String drawerId)? unregisterDrawer;
  final NarwhalDrawerState? Function(String drawerId)? getDrawerState;

  // Mode management methods
  final NarwhalDrawerMode Function(String drawerId)? getDrawerMode;
  final void Function(String drawerId, NarwhalDrawerMode mode)? setDrawerMode;

  const NarwhalDrawerLayoutProvider({
    super.key,
    required super.child,
    this.snapThreshold = 50.0,
    this.snapHintWidth = 400.0,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onModeChangeRequest,
    this.onWidthUpdate,
    this.onVisibilityUpdate,
    this.registerDrawer,
    this.unregisterDrawer,
    this.getDrawerState,
    this.getDrawerMode,
    this.setDrawerMode,
  });

  /// Access the nearest NarwhalDrawerLayoutProvider up the widget tree
  static NarwhalDrawerLayoutProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NarwhalDrawerLayoutProvider>();

  @override
  bool updateShouldNotify(NarwhalDrawerLayoutProvider oldWidget) {
    return snapThreshold != oldWidget.snapThreshold ||
        snapHintWidth != oldWidget.snapHintWidth ||
        onDragStart != oldWidget.onDragStart ||
        onDragUpdate != oldWidget.onDragUpdate ||
        onDragEnd != oldWidget.onDragEnd ||
        onModeChangeRequest != oldWidget.onModeChangeRequest ||
        onWidthUpdate != oldWidget.onWidthUpdate ||
        onVisibilityUpdate != oldWidget.onVisibilityUpdate ||
        registerDrawer != oldWidget.registerDrawer ||
        unregisterDrawer != oldWidget.unregisterDrawer ||
        getDrawerState != oldWidget.getDrawerState ||
        getDrawerMode != oldWidget.getDrawerMode ||
        setDrawerMode != oldWidget.setDrawerMode;
  }
}

/// A layout widget that manages multiple NarwhalDrawer widgets with centralized snap functionality
///
/// This widget provides centralized snap hint detection and display for all drawers,
/// coordinating their positioning and mode transitions through InheritedWidget communication.
///
/// Drawers automatically gain access to snap functionality when placed inside this layout.
/// No constructor changes needed - communication happens through the widget tree.
///
/// Example usage:
/// ```dart
/// NarwhalDrawerLayout(
///   content: MyCanvasWidget(),
///   drawers: [
///     const TreeDrawer(),
///     const EditorDrawer(),
///   ],
/// )
/// ```
class NarwhalDrawerLayout extends StatefulWidget {
  final Widget content;
  final List<NarwhalDrawer> drawers;
  final double snapThreshold;
  final double snapHintWidth;

  const NarwhalDrawerLayout({
    super.key,
    required this.content,
    required this.drawers,
    this.snapThreshold = 50.0,
    this.snapHintWidth = 400.0,
  });

  @override
  State<NarwhalDrawerLayout> createState() => _NarwhalDrawerLayoutState();
}

class _NarwhalDrawerLayoutState extends State<NarwhalDrawerLayout> {
  // Snap hint state
  bool _showLeftSnapHint = false;
  bool _showRightSnapHint = false;
  bool _showTopSnapHint = false;

  // Registry to store drawer states directly
  final Map<String, NarwhalDrawerState> _registeredDrawers = {};

  // Centralized mode tracking for all drawers
  final Map<String, NarwhalDrawerMode> _drawerModes = {};

  // Track actual drawer widths for layout calculations
  final Map<String, double> _drawerWidths = {};

  // Track drawer visibility states for margin calculations
  final Map<String, bool> _drawerVisibilities = {};

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return NarwhalDrawerLayoutProvider(
      snapThreshold: widget.snapThreshold,
      snapHintWidth: widget.snapHintWidth,
      onDragStart: _onDrawerDragStart,
      onDragUpdate: _onDrawerDragUpdate,
      onDragEnd: _onDrawerDragEnd,
      onModeChangeRequest: _onDrawerModeChangeRequest,
      onWidthUpdate: _onDrawerWidthUpdate,
      onVisibilityUpdate: _onDrawerVisibilityUpdate,
      registerDrawer: _registerDrawer,
      unregisterDrawer: _unregisterDrawer,
      getDrawerState: _getDrawerState,
      getDrawerMode: _getDrawerMode,
      setDrawerMode: _setDrawerMode,
      child: Stack(
        children: [
          _buildAdaptiveContent(),
          // Render drawers directly (no wrapper needed)
          ...widget.drawers,
          // Centralized snap hint overlays
          if (_showLeftSnapHint) _buildLeftSnapHint(screenSize),
          if (_showRightSnapHint) _buildRightSnapHint(screenSize),
          if (_showTopSnapHint) _buildTopSnapHint(),
        ],
      ),
    );
  }

  /// Register a drawer state for direct access
  void _registerDrawer(String drawerId, NarwhalDrawerState state) {
    _registeredDrawers[drawerId] = state;
  }

  /// Unregister a drawer state when it's disposed
  void _unregisterDrawer(String drawerId) {
    _registeredDrawers.remove(drawerId);
  }

  /// Get a registered drawer state
  NarwhalDrawerState? _getDrawerState(String drawerId) {
    return _registeredDrawers[drawerId];
  }

  /// Get the current mode for a drawer
  NarwhalDrawerMode _getDrawerMode(String drawerId) {
    // Return the stored mode, or default to windowed if not set
    return _drawerModes[drawerId] ?? NarwhalDrawerMode.windowed;
  }

  /// Set the mode for a drawer with exclusive sidebar enforcement
  void _setDrawerMode(String drawerId, NarwhalDrawerMode mode) {
    final currentMode = _drawerModes[drawerId];

    // If mode hasn't changed, no need to update
    if (currentMode == mode) return;

    // Enforce exclusive sidebar rule: only one drawer can be in left/right mode
    if (mode == NarwhalDrawerMode.left || mode == NarwhalDrawerMode.right) {
      // Find any other drawer currently in the same sidebar mode and move it to windowed
      final conflictingDrawers = _drawerModes.entries
          .where((entry) => entry.key != drawerId && entry.value == mode)
          .toList();

      for (final entry in conflictingDrawers) {
        final conflictingDrawerId = entry.key;
        final conflictingDrawerState = _registeredDrawers[conflictingDrawerId];

        // Set the conflicting drawer to windowed mode
        _drawerModes[conflictingDrawerId] = NarwhalDrawerMode.windowed;
        // Remove width tracking for windowed drawers (they don't affect layout)
        _drawerWidths.remove(conflictingDrawerId);

        // If the conflicting drawer state is available, transition it
        if (conflictingDrawerState != null) {
          final conflictingDrawer = widget.drawers.firstWhere(
            (d) => d.persistenceId == conflictingDrawerId,
            orElse: () =>
                throw StateError('Drawer $conflictingDrawerId not found'),
          );

          // Position based on which side the drawer was previously on
          late Offset newPosition;
          const double margin = 50.0;

          switch (entry.value) {
            // entry.value is the conflicting drawer's current mode
            case NarwhalDrawerMode.left:
              // Was on left side, position on left with margin
              newPosition = const Offset(margin, margin);
              break;
            case NarwhalDrawerMode.right:
              // Was on right side, position on right with margin
              newPosition = Offset(
                MediaQuery.of(context).size.width -
                    conflictingDrawer.defaultWindowSize.width -
                    margin,
                margin,
              );
              break;
            case NarwhalDrawerMode.windowed:
              // Edge case: was already windowed, use default behavior
              newPosition =
                  conflictingDrawer.defaultPosition ?? const Offset(100, 100);
              break;
            case NarwhalDrawerMode.fullscreen:
              // Was fullscreen, move to windowed at top-left with margin
              newPosition = const Offset(margin, margin);
              break;
          }

          final newSize = conflictingDrawer.defaultWindowSize;

          conflictingDrawerState.transitionToMode(
            NarwhalDrawerMode.windowed,
            newPosition,
            newSize,
          );
        }
      }
    }

    // Set the new mode for this drawer
    _drawerModes[drawerId] = mode;

    // Notify any listening drawers that the mode has changed
    setState(() {
      // This will cause the InheritedWidget to notify dependents
    });
  }

  /// Handles when a drawer starts being dragged
  void _onDrawerDragStart(String drawerId, Offset position, Size size) {
    // Drawer drag started - no immediate action needed
    // The snap hints will be shown during drag updates
  }

  /// Handles drawer position updates during drag
  void _onDrawerDragUpdate(String drawerId, Offset position, Size size) {
    final screenSize = MediaQuery.of(context).size;
    final drawerAllowsFullscreen = widget.drawers
        .firstWhere(
          (d) => d.persistenceId == drawerId,
          orElse: () => widget.drawers.first,
        )
        .allowFullscreen;
    final inTopZone = drawerAllowsFullscreen && _isInTopSnapZone(position);

    setState(() {
      _showTopSnapHint = inTopZone;
      _showLeftSnapHint = !inTopZone && _isInLeftSnapZone(position);
      _showRightSnapHint =
          !inTopZone && _isInRightSnapZone(position, size, screenSize);
    });
  }

  /// Handles when a drawer drag ends - checks for snap zones
  void _onDrawerDragEnd(String drawerId, Offset position, Size size) {
    final screenSize = MediaQuery.of(context).size;
    final drawerAllowsFullscreen = widget.drawers
        .firstWhere(
          (d) => d.persistenceId == drawerId,
          orElse: () => widget.drawers.first,
        )
        .allowFullscreen;

    setState(() {
      _showLeftSnapHint = false;
      _showRightSnapHint = false;
      _showTopSnapHint = false;
    });

    // Top snap takes priority; only available if the drawer opts in
    if (drawerAllowsFullscreen && _isInTopSnapZone(position)) {
      _transitionDrawerToFullscreen(drawerId, screenSize);
    } else if (_isInLeftSnapZone(position)) {
      _transitionDrawerToSidebar(drawerId, NarwhalDrawerMode.left, screenSize);
    } else if (_isInRightSnapZone(position, size, screenSize)) {
      _transitionDrawerToSidebar(drawerId, NarwhalDrawerMode.right, screenSize);
    }
  }

  /// Handles mode change requests from drawers
  void _onDrawerModeChangeRequest(
    String drawerId,
    NarwhalDrawerMode mode,
    Offset position,
    Size size,
  ) {
    final screenSize = MediaQuery.of(context).size;
    _transitionDrawerToSidebar(drawerId, mode, screenSize);
  }

  /// Handles drawer width updates
  void _onDrawerWidthUpdate(String drawerId, double width) {
    setState(() {
      _drawerWidths[drawerId] = width;
    });
  }

  /// Handles drawer visibility updates
  void _onDrawerVisibilityUpdate(String drawerId, bool isVisible) {
    setState(() {
      _drawerVisibilities[drawerId] = isVisible;
    });
  }

  /// Build content with adaptive margins based on sidebar drawer widths and visibility
  Widget _buildAdaptiveContent() {
    double leftMargin = 0;
    double rightMargin = 0;

    // Calculate margins based on actual sidebar drawer widths and visibility
    // Note: Only one drawer can be on each side due to exclusive sidebar enforcement
    _drawerModes.forEach((drawerId, mode) {
      final width = _drawerWidths[drawerId] ?? 0;
      final isVisible = _drawerVisibilities[drawerId] ?? false;

      // Only apply margin if drawer is in sidebar mode AND visible
      if (isVisible && mode == NarwhalDrawerMode.left) {
        leftMargin = width;
      } else if (isVisible && mode == NarwhalDrawerMode.right) {
        rightMargin = width;
      }
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      margin: .only(left: leftMargin, right: rightMargin),
      child: widget.content,
    );
  }

  /// Checks if position is in left snap zone
  bool _isInLeftSnapZone(Offset position) => position.dx < widget.snapThreshold;

  /// Checks if position is in right snap zone
  bool _isInRightSnapZone(Offset position, Size drawerSize, Size screenSize) =>
      position.dx + drawerSize.width > screenSize.width - widget.snapThreshold;

  /// Checks if position is in top snap zone
  bool _isInTopSnapZone(Offset position) => position.dy < 2;

  /// Transitions a drawer to fullscreen mode (fills the entire parent Stack)
  void _transitionDrawerToFullscreen(String drawerId, Size screenSize) {
    final drawerState = _registeredDrawers[drawerId];
    if (drawerState == null) return;

    _setDrawerMode(drawerId, NarwhalDrawerMode.fullscreen);
    _drawerWidths.remove(drawerId);

    drawerState.transitionToMode(
      NarwhalDrawerMode.fullscreen,
      .zero,
      screenSize,
    );
  }

  /// Transitions a drawer to sidebar mode
  void _transitionDrawerToSidebar(
    String drawerId,
    NarwhalDrawerMode mode,
    Size screenSize,
  ) {
    final drawerState = _registeredDrawers[drawerId];
    if (drawerState == null) return;

    final drawer = widget.drawers.firstWhere(
      (d) => d.persistenceId == drawerId,
      orElse: () => throw StateError('Drawer $drawerId not found'),
    );

    // Use centralized mode management to set the mode (includes exclusive logic)
    _setDrawerMode(drawerId, mode);

    late Offset newPosition;
    late Size newSize;

    switch (mode) {
      case NarwhalDrawerMode.left:
        newPosition = const Offset(0, 0);
        newSize = Size(drawer.defaultSidebarWidth, screenSize.height);
        // Track the sidebar width for layout calculations
        _drawerWidths[drawerId] = drawer.defaultSidebarWidth;
        break;
      case NarwhalDrawerMode.right:
        newPosition = Offset(screenSize.width - drawer.defaultSidebarWidth, 0);
        newSize = Size(drawer.defaultSidebarWidth, screenSize.height);
        // Track the sidebar width for layout calculations
        _drawerWidths[drawerId] = drawer.defaultSidebarWidth;
        break;
      case NarwhalDrawerMode.windowed:
        newPosition = drawer.defaultPosition ?? const Offset(100, 100);
        newSize = drawer.defaultWindowSize;
        // Remove width tracking for windowed drawers (they don't affect layout)
        _drawerWidths.remove(drawerId);
        break;
      case NarwhalDrawerMode.fullscreen:
        _transitionDrawerToFullscreen(drawerId, screenSize);
        return;
    }

    // Call the drawer's transition method
    drawerState.transitionToMode(mode, newPosition, newSize);
  }

  /// Builds the left snap hint overlay
  Widget _buildLeftSnapHint(Size screenSize) {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: widget.snapHintWidth,
        height: screenSize.height,
        decoration: BoxDecoration(
          color: ThemeHelper.blue400(context).withValues(alpha: 0.5),
          border: Border(
            right: BorderSide(color: ThemeHelper.blue400(context), width: 1),
          ),
        ),
      ),
    );
  }

  /// Builds the top snap hint overlay (full-parent coverage for fullscreen snap)
  Widget _buildTopSnapHint() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.blue400(context).withValues(alpha: 0.5),
          border: .all(color: ThemeHelper.blue400(context), width: 1),
        ),
      ),
    );
  }

  /// Builds the right snap hint overlay
  Widget _buildRightSnapHint(Size screenSize) {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: widget.snapHintWidth,
        height: screenSize.height,
        decoration: BoxDecoration(
          color: ThemeHelper.blue400(context).withValues(alpha: 0.5),
          border: Border(
            left: BorderSide(color: ThemeHelper.blue400(context), width: 1),
          ),
        ),
      ),
    );
  }
}
