import 'package:onyxia/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified enum for drawer display mode
enum NarwhalDrawerMode { left, right, windowed, fullscreen }

/// Enum for resize handle directions
enum NarwhalDrawerResizeHandle {
  topLeft,
  top,
  topRight,
  left,
  right,
  bottomLeft,
  bottom,
  bottomRight,
  sidebarRight,
  sidebarLeft,
}

/// Configuration data for a resize handle
class NarwhalDrawerResizeHandleConfig {
  final Offset position;
  final double width;
  final double height;
  final MouseCursor cursor;
  final NarwhalDrawerResizeHandle handle;
  final GlobalKey key;

  const NarwhalDrawerResizeHandleConfig({
    required this.position,
    required this.width,
    required this.height,
    required this.cursor,
    required this.handle,
    required this.key,
  });
}

/// Unified data class to hold drawer state for all drawers
class NarwhalDrawerData {
  final Offset position;
  final Size size;
  final NarwhalDrawerMode mode;
  final bool isOpen;

  const NarwhalDrawerData({
    required this.position,
    required this.size,
    this.mode = NarwhalDrawerMode.windowed,
    this.isOpen = false,
  });

  NarwhalDrawerData copyWith({
    Offset? position,
    Size? size,
    NarwhalDrawerMode? mode,
    bool? isOpen,
  }) {
    return NarwhalDrawerData(
      position: position ?? this.position,
      size: size ?? this.size,
      mode: mode ?? this.mode,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

/// Abstract base class for all Narwhal drawers
abstract class NarwhalDrawer extends ConsumerStatefulWidget {
  final String persistenceId;
  final String title;
  final double minWidth;
  final double minHeight;
  final Size defaultWindowSize;
  final double defaultSidebarWidth;
  final Offset? defaultPosition;
  final NarwhalDrawerMode defaultMode;
  final bool allowFullscreen;
  final Duration animationDuration = const Duration(milliseconds: 300);

  const NarwhalDrawer({
    super.key,
    required this.title,
    this.minWidth = 250.0,
    this.minHeight = 300.0,
    this.defaultWindowSize = const Size(450, 470),
    this.defaultSidebarWidth = 400.0,
    this.defaultPosition,
    this.defaultMode = NarwhalDrawerMode.windowed,
    this.allowFullscreen = false,
    required this.persistenceId,
  });

  /// Get the visibility provider for this drawer
  NotifierProvider<VisibilityNotifier, bool> getVisibilityProvider();

  void onClose(WidgetRef ref);
}

/// Base class for drawer visibility notifiers.
/// Subclasses can simply extend this and pass the constructor to a
/// `NotifierProvider<XVisibilityNotifier, bool>`.
class VisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

/// State class for NarwhalDrawer
abstract class NarwhalDrawerState<T extends NarwhalDrawer>
    extends ConsumerState<T> {
  /// Build the header content (buttons, etc.). Implemented by subclasses.
  Widget buildHeader(BuildContext context, WidgetRef ref);

  /// Build the main drawer content. Implemented by subclasses.
  Widget buildBody(BuildContext context, WidgetRef ref);
  // State variables
  bool _isResizing = false;
  bool _isDragging = false;
  Rect? _headerBounds;
  Rect? _buttonsBounds;
  List<Rect> _resizeHandleBounds = [];

  // Previous bounds for change detection
  Rect? _previousHeaderBounds;
  Rect? _previousButtonsBounds;
  List<Rect> _previousResizeHandleBounds = [];
  Offset? _lastPointerPosition;

  // Layout provider reference to avoid unsafe context lookups during disposal
  NarwhalDrawerLayoutProvider? _layoutProvider;

  // Keys for UI elements
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _buttonsKey = GlobalKey();

  // Resize handle keys for windowed mode (8 handles)
  final List<GlobalKey> _resizeHandleKeys = List.generate(
    8,
    (index) => GlobalKey(),
  );
  // Sidebar resize handle key (1 handle)
  final GlobalKey _sidebarResizeKey = GlobalKey();

  // Animation state
  bool _isClosing = false;
  bool _animateSlideIn = false;

  // Position and size state
  late Offset _position;
  late Size _size;

  NarwhalDrawerMode get _mode =>
      _layoutProvider?.getDrawerMode?.call(widget.persistenceId) ??
      widget.defaultMode;

  @override
  void initState() {
    super.initState();

    // Register with layout provider after this frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutProvider = NarwhalDrawerLayoutProvider.of(context);
      _layoutProvider?.registerDrawer?.call(widget.persistenceId, this);

      // Report initial visibility state
      final isVisible = ref.read(widget.getVisibilityProvider());
      _layoutProvider?.onVisibilityUpdate?.call(
        widget.persistenceId,
        isVisible,
      );
    });

    // Initialize with default values first
    _position = widget.defaultPosition ?? const Offset(50, 50);
    _size = widget.defaultWindowSize;

    // Then try to load saved state
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeDrawerState(),
    );
  }

  void _initializeDrawerState() async {
    final screenSize = MediaQuery.of(context).size;

    final persistedData = await _loadDrawerState(widget.persistenceId);
    if (persistedData != null && mounted) {
      final persistedMode =
          persistedData['mode'] as NarwhalDrawerMode? ?? widget.defaultMode;

      // Set the mode in the layout provider
      _layoutProvider?.setDrawerMode?.call(widget.persistenceId, persistedMode);

      setState(() {
        _position = persistedData['position'] as Offset;
        _size = persistedData['size'] as Size;

        // If loading in sidebar mode, set animation state and positioning
        if (_mode == NarwhalDrawerMode.left ||
            _mode == NarwhalDrawerMode.right) {
          _animateSlideIn = true;
          if (_mode == NarwhalDrawerMode.left) {
            _position = const Offset(0, 0);
            _size = Size(_size.width, screenSize.height);
          } else {
            _position = Offset(screenSize.width - _size.width, 0);
            _size = Size(_size.width, screenSize.height);
          }
        } else if (_mode == NarwhalDrawerMode.fullscreen) {
          _animateSlideIn = false;
          _position = .zero;
          _size = Size(screenSize.width, screenSize.height);
        }
      });

      // Restore visibility state if drawer was open
      final wasOpen = persistedData['isOpen'] as bool;
      if (wasOpen) {
        ref.read(widget.getVisibilityProvider().notifier).set(true);
      }

      // Report width to layout provider if in sidebar mode
      if (_mode == NarwhalDrawerMode.left || _mode == NarwhalDrawerMode.right) {
        _layoutProvider?.onWidthUpdate?.call(widget.persistenceId, _size.width);
      }

      // Report initial visibility state
      _layoutProvider?.onVisibilityUpdate?.call(widget.persistenceId, wasOpen);

      return; // Exit early if we loaded persisted state
    }

    if (!mounted) return;

    // fallback
    // Set the default mode in the layout provider
    _layoutProvider?.setDrawerMode?.call(
      widget.persistenceId,
      widget.defaultMode,
    );

    setState(() {
      if (widget.defaultPosition != null) {
        _position = widget.defaultPosition!;
      } else {
        // Default to top-right corner
        _position = Offset(
          screenSize.width - 50 - widget.defaultWindowSize.width,
          50,
        );
      }
      _size = widget.defaultWindowSize;
    });
  }

  @override
  void dispose() {
    // Unregister from layout provider using stored reference
    _layoutProvider?.unregisterDrawer?.call(widget.persistenceId);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(widget.getVisibilityProvider());

    // Listen for visibility changes to trigger animations and save persistence
    ref.listen(widget.getVisibilityProvider(), (previous, next) {
      // Report visibility changes to layout provider
      _layoutProvider?.onVisibilityUpdate?.call(widget.persistenceId, next);

      if (previous != null && previous == true && next == false) {
        // Closing
        if ((_mode == NarwhalDrawerMode.left ||
            _mode == NarwhalDrawerMode.right)) {
          // Sidebar mode - animate close
          setState(() {
            _isClosing = true;
            _animateSlideIn = false;
          });

          // After animation, allow removal from tree
          Future.delayed(widget.animationDuration, () {
            if (mounted) {
              setState(() {
                _isClosing = false;
              });
            }
          });
        } else {
          // Windowed mode - instant hide
          setState(() {
            _isClosing = false;
            _animateSlideIn = false;
          });
        }

        widget.onClose(ref);

        _saveDrawerState(widget.persistenceId, false);
      } else if (previous != null && previous == false && next == true) {
        // Opening
        if ((_mode == NarwhalDrawerMode.left ||
            _mode == NarwhalDrawerMode.right)) {
          // Sidebar mode - start offscreen, then animate in
          setState(() {
            _animateSlideIn = false;
          });
          // Trigger slide-in animation on next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _animateSlideIn = true;
              });
              _scheduleBoundsRecaptureAfterAnimation();
            }
          });
        } else {
          // Windowed mode - no animation
          setState(() {
            _animateSlideIn = false;
          });
        }

        _saveDrawerState(widget.persistenceId, true);
      }
    });

    if (!isVisible && !_isClosing) return const SizedBox.shrink();

    // Capture bounds after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureBounds());

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: Stack(
        children: [
          // Main drawer
          _buildDrawer(_mode, _position, _size),
        ],
      ),
    );
  }

  Widget _buildDrawer(NarwhalDrawerMode mode, Offset position, Size size) =>
      switch (mode) {
        NarwhalDrawerMode.windowed => _buildWindow(position, size),
        NarwhalDrawerMode.left => _buildSidebar(size),
        NarwhalDrawerMode.right => _buildSidebar(size),
        NarwhalDrawerMode.fullscreen => _buildFullscreen(),
      };

  Widget _buildWindow(Offset position, Size size) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Stack(
        children: [
          Material(
            elevation: 6,
            borderRadius: .circular(12),
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: ThemeHelper.neutral200(context),
                borderRadius: .circular(12),
              ),
              child: ClipRRect(
                borderRadius: .circular(12),
                child: Column(
                  children: [
                    _buildDraggableHeader(),
                    Expanded(
                      child: Container(
                        color: ThemeHelper.neutral200(context),
                        child: buildBody(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add resize handles (only in windowed mode)
          ..._buildWindowedResizeHandles(size),
        ],
      ),
    );
  }

  Widget _buildSidebar(Size size) {
    // For right sidebars, use right positioning to avoid animation conflicts during resize
    if (_mode == NarwhalDrawerMode.left) {
      // Left sidebar: use left positioning
      final double leftPosition = (_isClosing || !_animateSlideIn)
          ? -size.width
          : 0;

      return AnimatedPositioned(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        left: leftPosition,
        top: 0,
        bottom: 0,
        child: _buildSidebarContent(size),
      );
    } else if (_mode == NarwhalDrawerMode.right) {
      // Right sidebar: use right positioning to stay anchored
      final double rightPosition = (_isClosing || !_animateSlideIn)
          ? -size.width
          : 0;

      return AnimatedPositioned(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        right: rightPosition,
        top: 0,
        bottom: 0,
        child: _buildSidebarContent(size),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSidebarContent(Size size) {
    if (_mode == NarwhalDrawerMode.windowed) return const SizedBox.shrink();

    return Stack(
      children: [
        Material(
          elevation: 4,
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: ThemeHelper.neutral200(context),
              border: _mode == NarwhalDrawerMode.left
                  ? Border(
                      right: BorderSide(
                        color: ThemeHelper.neutral400(context),
                        width: 1,
                      ),
                    )
                  : Border(
                      left: BorderSide(
                        color: ThemeHelper.neutral400(context),
                        width: 1,
                      ),
                    ),
            ),
            child: Column(
              children: [
                _buildDraggableHeader(),
                Expanded(child: buildBody(context, ref)),
              ],
            ),
          ),
        ),
        // resize handle for sidebar mode
        ..._buildSidebarResizeHandles(size),
      ],
    );
  }

  Widget _buildFullscreen() {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 4,
        child: Container(
          color: ThemeHelper.neutral200(context),
          child: Column(
            children: [
              _buildDraggableHeader(),
              Expanded(child: buildBody(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableHeader() {
    return Container(
      key: _headerKey,
      height: 44,
      padding: .symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeHelper.neutral200(context),
        border: Border(
          bottom: BorderSide(color: ThemeHelper.neutral400(context), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(widget.title, style: NarwhalTextStyle(fontSize: 17)),
          Container(key: _buttonsKey, child: buildHeader(context, ref)),
        ],
      ),
    );
  }

  bool _boundsChanged(Rect? newBounds, Rect? previousBounds) {
    if (newBounds == null && previousBounds == null) return false;
    if (newBounds == null || previousBounds == null) return true;
    return newBounds != previousBounds;
  }

  bool _boundsListChanged(List<Rect> newBounds, List<Rect> previousBounds) {
    if (newBounds.length != previousBounds.length) return true;
    for (int i = 0; i < newBounds.length; i++) {
      if (newBounds[i] != previousBounds[i]) return true;
    }
    return false;
  }

  bool _isPointerOverResizeHandle(Offset position) {
    for (final bounds in _resizeHandleBounds) {
      if (bounds.contains(position)) return true;
    }
    return false;
  }

  void _captureBounds() {
    if (!mounted) return;

    // Capture header bounds
    final RenderBox? headerRenderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (headerRenderBox != null && headerRenderBox.hasSize) {
      final offset = headerRenderBox.localToGlobal(.zero);
      final bounds = offset & headerRenderBox.size;

      if (_boundsChanged(bounds, _previousHeaderBounds)) {
        setState(() {
          _headerBounds = bounds;
        });
        _previousHeaderBounds = bounds;
      }
    } else {
      if (_previousHeaderBounds != null) {
        setState(() {
          _headerBounds = null;
        });
        _previousHeaderBounds = null;
      }
    }

    // Capture button bounds
    final RenderBox? buttonsRenderBox =
        _buttonsKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonsRenderBox != null && buttonsRenderBox.hasSize) {
      final bounds =
          buttonsRenderBox.localToGlobal(.zero) & buttonsRenderBox.size;

      if (_boundsChanged(bounds, _previousButtonsBounds)) {
        setState(() {
          _buttonsBounds = bounds;
        });
        _previousButtonsBounds = bounds;
      }
    } else {
      if (_previousButtonsBounds != null) {
        setState(() {
          _buttonsBounds = null;
        });
        _previousButtonsBounds = null;
      }
    }

    // Capture resize handle bounds
    final List<Rect> newResizeHandleBounds = [];

    if (_mode == NarwhalDrawerMode.windowed) {
      // Capture windowed resize handle bounds (8 handles)
      for (int i = 0; i < _resizeHandleKeys.length; i++) {
        final RenderBox? renderBox =
            _resizeHandleKeys[i].currentContext?.findRenderObject()
                as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final offset = renderBox.localToGlobal(.zero);
          newResizeHandleBounds.add(offset & renderBox.size);
        }
      }
    } else if (_mode == NarwhalDrawerMode.left ||
        _mode == NarwhalDrawerMode.right) {
      // Capture sidebar resize handle bounds (1 handle)
      final RenderBox? renderBox =
          _sidebarResizeKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        newResizeHandleBounds.add(
          renderBox.localToGlobal(.zero) & renderBox.size,
        );
      }
    }

    if (_boundsListChanged(
      newResizeHandleBounds,
      _previousResizeHandleBounds,
    )) {
      setState(() {
        _resizeHandleBounds = newResizeHandleBounds;
      });
      _previousResizeHandleBounds = List.from(newResizeHandleBounds);
    }
  }

  void _scheduleBoundsRecaptureAfterAnimation() {
    Future.delayed(
      widget.animationDuration + const Duration(milliseconds: 50),
      () {
        if (mounted &&
            (_mode == NarwhalDrawerMode.left ||
                _mode == NarwhalDrawerMode.right)) {
          _captureBounds();
        }
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isResizing ||
        _headerBounds == null ||
        !_headerBounds!.contains(event.position)) {
      return;
    }

    if (_buttonsBounds != null && _buttonsBounds!.contains(event.position)) {
      // Don't start dragging if clicking on buttons
      return;
    }

    if (_isPointerOverResizeHandle(event.position)) {
      // Don't start dragging if clicking on resize handles
      return;
    }

    setState(() {
      _isDragging = true;
      _lastPointerPosition = event.position;
    });

    _layoutProvider?.onDragStart?.call(widget.persistenceId, _position, _size);

    // If starting from a non-windowed mode, immediately pop out to windowed mode
    if (_mode != NarwhalDrawerMode.windowed) {
      _transitionToWindowed(event.position);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDragging || _lastPointerPosition == null) return;

    final delta = event.position - _lastPointerPosition!;
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _position = Offset(
        (_position.dx + delta.dx).clamp(0.0, screenSize.width - _size.width),
        (_position.dy + delta.dy).clamp(0.0, screenSize.height - _size.height),
      );
      _lastPointerPosition = event.position;

      _layoutProvider?.onDragUpdate?.call(
        widget.persistenceId,
        _position,
        _size,
      );
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _lastPointerPosition = null;
    });

    _layoutProvider?.onDragEnd?.call(widget.persistenceId, _position, _size);

    _saveDrawerState(
      widget.persistenceId,
      ref.read(widget.getVisibilityProvider()),
    );
  }

  void _transitionToWindowed(Offset? mousePosition) {
    if (_mode == NarwhalDrawerMode.windowed) return;

    final screenSize = MediaQuery.of(context).size;
    final newWindowSize = widget.defaultWindowSize;

    // Set the mode through the layout provider
    _layoutProvider?.setDrawerMode?.call(
      widget.persistenceId,
      NarwhalDrawerMode.windowed,
    );

    setState(() {
      if (mousePosition != null && _mode == NarwhalDrawerMode.fullscreen) {
        // From fullscreen: center window under cursor, keeping header under pointer
        final windowX = (mousePosition.dx - newWindowSize.width / 2).clamp(
          0.0,
          screenSize.width - newWindowSize.width,
        );
        final windowY =
            (mousePosition.dy - 22.0) // 22 = half header height
                .clamp(0.0, screenSize.height - newWindowSize.height);
        _position = Offset(windowX, windowY);
      } else if (mousePosition != null) {
        // From sidebar: calculate cursor's position relative to sidebar width
        final cursorXInSidebar = _mode == NarwhalDrawerMode.left
            ? mousePosition.dx
            : screenSize.width - mousePosition.dx;

        final percentageAcross = cursorXInSidebar / _size.width;

        // Calculate offset based on percentage applied to new window width
        final offsetX = percentageAcross * newWindowSize.width;

        // Position window at cursor minus offset
        final windowX = (mousePosition.dx - offsetX).clamp(
          0.0,
          screenSize.width - newWindowSize.width,
        );

        _position = Offset(windowX, 24.0); // 24px from top
      } else {
        // Fallback to default position
        _position =
            widget.defaultPosition ??
            Offset(screenSize.width - 24 - newWindowSize.width, 24);
      }

      _size = newWindowSize;
      _animateSlideIn = false;
      _isClosing = false;
    });

    _saveDrawerState(
      widget.persistenceId,
      ref.read(widget.getVisibilityProvider()),
    );
  }

  // Resize handle builders
  List<Widget> _buildWindowedResizeHandles(Size size) {
    const handleSize = 10.0;
    const edgeHandleThickness = 5.0;
    final horizontalSize = Size(
      size.width - (2 * handleSize),
      edgeHandleThickness,
    );
    final verticalSize = Size(
      edgeHandleThickness,
      size.height - (2 * handleSize),
    );

    return [
      // Corner handles
      NarwhalDrawerResizeHandleConfig(
        position: const Offset(0, 0),
        width: handleSize,
        height: handleSize,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        handle: NarwhalDrawerResizeHandle.topLeft,
        key: _resizeHandleKeys[0],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(size.width - handleSize, 0),
        width: handleSize,
        height: handleSize,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        handle: NarwhalDrawerResizeHandle.topRight,
        key: _resizeHandleKeys[1],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(0, size.height - handleSize),
        width: handleSize,
        height: handleSize,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        handle: NarwhalDrawerResizeHandle.bottomLeft,
        key: _resizeHandleKeys[2],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(size.width - handleSize, size.height - handleSize),
        width: handleSize,
        height: handleSize,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        handle: NarwhalDrawerResizeHandle.bottomRight,
        key: _resizeHandleKeys[3],
      ),
      // Edge handles
      NarwhalDrawerResizeHandleConfig(
        position: Offset(handleSize, 0),
        width: horizontalSize.width,
        height: horizontalSize.height,
        cursor: SystemMouseCursors.resizeUpDown,
        handle: NarwhalDrawerResizeHandle.top,
        key: _resizeHandleKeys[4],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(handleSize, size.height - edgeHandleThickness),
        width: horizontalSize.width,
        height: horizontalSize.height,
        cursor: SystemMouseCursors.resizeUpDown,
        handle: NarwhalDrawerResizeHandle.bottom,
        key: _resizeHandleKeys[5],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(0, handleSize),
        width: verticalSize.width,
        height: verticalSize.height,
        cursor: SystemMouseCursors.resizeLeftRight,
        handle: NarwhalDrawerResizeHandle.left,
        key: _resizeHandleKeys[6],
      ),
      NarwhalDrawerResizeHandleConfig(
        position: Offset(size.width - edgeHandleThickness, handleSize),
        width: verticalSize.width,
        height: verticalSize.height,
        cursor: SystemMouseCursors.resizeLeftRight,
        handle: NarwhalDrawerResizeHandle.right,
        key: _resizeHandleKeys[7],
      ),
    ].map((config) => _buildResizeHandle(config)).toList();
  }

  List<Widget> _buildSidebarResizeHandles(Size size) {
    if (_mode == NarwhalDrawerMode.windowed) return [];

    const double edgeHandleThickness = 5.0;

    return [
      NarwhalDrawerResizeHandleConfig(
        position: _mode == NarwhalDrawerMode.left
            ? Offset(
                size.width - edgeHandleThickness,
                0,
              ) // Right edge for left sidebar
            : Offset(-edgeHandleThickness, 0), // Left edge for right sidebar
        width: edgeHandleThickness * 2,
        height: size.height,
        cursor: SystemMouseCursors.resizeLeftRight,
        handle: _mode == NarwhalDrawerMode.left
            ? NarwhalDrawerResizeHandle.sidebarRight
            : NarwhalDrawerResizeHandle.sidebarLeft,
        key: _sidebarResizeKey,
      ),
    ].map((config) => _buildResizeHandle(config)).toList();
  }

  Widget _buildResizeHandle(NarwhalDrawerResizeHandleConfig config) {
    return Positioned(
      left: config.position.dx,
      top: config.position.dy,
      child: MouseRegion(
        cursor: config.cursor,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isResizing = true;
            });
          },
          onPanUpdate: (details) => _handleResize(details, config.handle),
          onPanEnd: (details) {
            setState(() {
              _isResizing = false;
            });
            _saveDrawerState(
              widget.persistenceId,
              ref.read(widget.getVisibilityProvider()),
            );
          },
          child: Container(
            key: config.key,
            width: config.width,
            height: config.height,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  void _handleResize(
    DragUpdateDetails details,
    NarwhalDrawerResizeHandle handle,
  ) {
    final screenSize = MediaQuery.of(context).size;

    final maxWidth = screenSize.width * 0.8;
    final maxHeight = screenSize.height * 0.8;

    double newWidth = _size.width;
    double newHeight = _size.height;
    Offset newPosition = _position;

    // Apply resize based on handle
    switch (handle) {
      // Corner handles
      case NarwhalDrawerResizeHandle.topLeft:
        newWidth = (_size.width - details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        newHeight = (_size.height - details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        newPosition = Offset(
          _position.dx + (_size.width - newWidth),
          _position.dy + (_size.height - newHeight),
        );
        break;
      case NarwhalDrawerResizeHandle.topRight:
        newWidth = (_size.width + details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        newHeight = (_size.height - details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        newPosition = Offset(
          _position.dx,
          _position.dy + (_size.height - newHeight),
        );
        break;
      case NarwhalDrawerResizeHandle.bottomLeft:
        newWidth = (_size.width - details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        newHeight = (_size.height + details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        newPosition = Offset(
          _position.dx + (_size.width - newWidth),
          _position.dy,
        );
        break;
      case NarwhalDrawerResizeHandle.bottomRight:
        newWidth = (_size.width + details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        newHeight = (_size.height + details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        break;

      // Edge handles
      case NarwhalDrawerResizeHandle.top:
        newHeight = (_size.height - details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        newPosition = Offset(
          _position.dx,
          _position.dy + (_size.height - newHeight),
        );
        break;
      case NarwhalDrawerResizeHandle.bottom:
        newHeight = (_size.height + details.delta.dy).clamp(
          widget.minHeight,
          maxHeight,
        );
        break;
      case NarwhalDrawerResizeHandle.left:
        newWidth = (_size.width - details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        newPosition = Offset(
          _position.dx + (_size.width - newWidth),
          _position.dy,
        );
        break;
      case NarwhalDrawerResizeHandle.right:
        newWidth = (_size.width + details.delta.dx).clamp(
          widget.minWidth,
          maxWidth,
        );
        break;

      // Sidebar resize
      case NarwhalDrawerResizeHandle.sidebarRight:
        // This is the right edge handle of a left sidebar
        newWidth = (_size.width + details.delta.dx).clamp(
          widget.minWidth,
          screenSize.width * 0.5,
        );
        // Position stays at left edge (0) for left sidebar mode
        newPosition = const Offset(0, 0);
        break;
      case NarwhalDrawerResizeHandle.sidebarLeft:
        // This is the left edge handle of a right sidebar
        newWidth = (_size.width - details.delta.dx).clamp(
          widget.minWidth,
          screenSize.width * 0.5,
        );
        // Right sidebar is anchored to right edge - no position change needed
        newPosition = _position;
        break;
    }

    // Ensure position stays within screen bounds (except for sidebar mode)
    if (handle != NarwhalDrawerResizeHandle.sidebarLeft &&
        handle != NarwhalDrawerResizeHandle.sidebarRight) {
      newPosition = Offset(
        newPosition.dx.clamp(0.0, screenSize.width - newWidth),
        newPosition.dy.clamp(0.0, screenSize.height - newHeight),
      );
    }

    // Update state
    setState(() {
      _size = Size(newWidth, newHeight);
      _position = newPosition;
    });

    // Report width changes to layout provider if in sidebar mode
    if (_mode == NarwhalDrawerMode.left || _mode == NarwhalDrawerMode.right) {
      _layoutProvider?.onWidthUpdate?.call(widget.persistenceId, newWidth);
    }
  }

  /// Save drawer state to SharedPreferences
  Future<void> _saveDrawerState(String id, bool isOpen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("${id}_position_x", _position.dx);
      await prefs.setDouble("${id}_position_y", _position.dy);
      await prefs.setDouble("${id}_size_width", _size.width);
      await prefs.setDouble("${id}_size_height", _size.height);
      await prefs.setString("${id}_mode", _mode.name);
      await prefs.setBool("${id}_is_open", isOpen);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load drawer state from SharedPreferences
  Future<Map<String, dynamic>?> _loadDrawerState(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final positionX = prefs.getDouble("${id}_position_x");
      final positionY = prefs.getDouble("${id}_position_y");
      final sizeWidth = prefs.getDouble("${id}_size_width");
      final sizeHeight = prefs.getDouble("${id}_size_height");
      final modeString = prefs.getString("${id}_mode");
      final isOpen = prefs.getBool("${id}_is_open") ?? false;

      if (positionX != null &&
          positionY != null &&
          sizeWidth != null &&
          sizeHeight != null) {
        final mode = NarwhalDrawerMode.values.firstWhere(
          (e) => e.name == modeString,
          orElse: () => NarwhalDrawerMode.windowed,
        );

        return {
          'position': Offset(positionX, positionY),
          'size': Size(sizeWidth, sizeHeight),
          'mode': mode,
          'isOpen': isOpen,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Public method for layout to force a mode transition (called by layout after snap detection)
  void transitionToMode(NarwhalDrawerMode mode, Offset position, Size size) {
    // Mode is already set by the layout provider, just update position/size and animation
    setState(() {
      _position = position;
      _size = size;
      _animateSlideIn = true;
      _isClosing = false;
    });

    // Report width changes to layout provider if in sidebar mode
    if (mode == NarwhalDrawerMode.left || mode == NarwhalDrawerMode.right) {
      _layoutProvider?.onWidthUpdate?.call(widget.persistenceId, size.width);
    }

    _scheduleBoundsRecaptureAfterAnimation();
    _saveDrawerState(
      widget.persistenceId,
      ref.read(widget.getVisibilityProvider()),
    );
  }
}
