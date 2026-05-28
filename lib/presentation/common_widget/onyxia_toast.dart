import 'package:onyxia/export.dart';
import 'dart:async';

enum ToastType { success, warning, error, info }

class _ToastEntry {
  final String id;
  final OverlayEntry overlayEntry;
  final Timer timer;
  final Alignment position;
  final GlobalKey<_ToastStackOverlayState> stateKey;
  bool isExiting = false;

  _ToastEntry({
    required this.id,
    required this.overlayEntry,
    required this.timer,
    required this.position,
    required this.stateKey,
  });
}

class OnyxiaToast {
  static final Map<Alignment, List<_ToastEntry>> _toastsByPosition = {};
  static final Map<Alignment, StreamController<void>> _positionControllers = {};
  static int _nextId = 0;

  static String show({
    String? text,
    Widget? child,
    ToastType type = .info,
    Alignment position = .topRight,
    Duration? duration,
    double margin = 16.0,
  }) {
    assert(
      text != null || child != null,
      'Either text or child must be provided',
    );
    assert(
      !(text != null && child != null),
      'Cannot provide both text and child',
    );

    // Errors stay longer so users can read them; other types use 3 s default.
    final effectiveDuration =
        duration ??
        (type == .error
            ? const Duration(seconds: 10)
            : const Duration(seconds: 3));

    // Always log errors to the console so they can be reviewed after dismissal.
    if (type == .error && text != null) {
      debugPrint('[Toast Error] $text');
    }

    final toastId = (_nextId++).toString();

    // Ensure position controller exists
    if (_positionControllers[position] == null) {
      _positionControllers[position] = StreamController<void>.broadcast();
    }

    final stateKey = GlobalKey<_ToastStackOverlayState>();

    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastStackOverlay(
        key: stateKey,
        toastId: toastId,
        text: text,
        type: type,
        position: position,
        margin: margin,
        positionStream: _positionControllers[position]!.stream,
        child: child,
      ),
    );

    final timer = Timer(effectiveDuration, () {
      _startExit(toastId, position);
    });

    final toastEntry = _ToastEntry(
      id: toastId,
      overlayEntry: overlayEntry,
      timer: timer,
      position: position,
      stateKey: stateKey,
    );

    // Add to position list with correct stacking order
    if (_toastsByPosition[position] == null) {
      _toastsByPosition[position] = [];
    }

    // For bottom positions, insert at the beginning (newest at bottom)
    // For top positions, insert at the beginning (newest at top)
    // For center positions, insert at the end (stack downward)
    if (_isBottomPosition(position) || _isTopPosition(position)) {
      _toastsByPosition[position]!.insert(0, toastEntry);
    } else {
      _toastsByPosition[position]!.add(toastEntry);
    }

    final o = navigatorKey.currentState!.overlay!;
    o.insert(overlayEntry);

    // Notify all toasts at this position to update their positions
    _notifyPositionUpdate(position);

    return toastId;
  }

  /// Show a toast with a live progress bar.
  /// Pass the returned [ValueNotifier<double>] values from 0.0 to 1.0.
  /// Call [hideById] with the returned ID when done.
  static ({String id, ValueNotifier<double> progress}) showProgress({
    required String label,
    Alignment position = .topRight,
  }) {
    final progress = ValueNotifier<double>(0.0);
    final id = show(
      child: _ProgressToastContent(label: label, progress: progress),
      type: .info,
      duration: const Duration(days: 365),
      position: position,
    );
    return (id: id, progress: progress);
  }

  /// Dismiss a specific toast by its ID (returned from [show] / [showProgress]).
  static void hideById(String toastId) {
    for (final position in _toastsByPosition.keys.toList()) {
      final toasts = _toastsByPosition[position];
      if (toasts == null) continue;
      if (toasts.any((t) => t.id == toastId)) {
        _startExit(toastId, position);
        return;
      }
    }
  }

  static void _startExit(String toastId, Alignment position) {
    final toasts = _toastsByPosition[position];
    if (toasts == null) return;
    final idx = toasts.indexWhere((t) => t.id == toastId);
    if (idx == -1) return;

    final toast = toasts[idx];
    if (toast.isExiting) return;
    toast.isExiting = true;
    toast.timer.cancel();

    final state = toast.stateKey.currentState;
    if (state == null) {
      _removeToast(toastId, position);
      return;
    }
    state.playExit().whenComplete(() => _removeToast(toastId, position));
  }

  static void _removeToast(String toastId, Alignment position) {
    final toasts = _toastsByPosition[position];
    if (toasts == null) return;

    final toastIndex = toasts.indexWhere((toast) => toast.id == toastId);
    if (toastIndex == -1) return;

    final toast = toasts[toastIndex];
    toast.timer.cancel();
    toast.overlayEntry.remove();
    toasts.removeAt(toastIndex);

    if (toasts.isEmpty) {
      _toastsByPosition.remove(position);
      _positionControllers[position]?.close();
      _positionControllers.remove(position);
    } else {
      // Notify remaining toasts to update their positions
      _notifyPositionUpdate(position);
    }
  }

  static void _notifyPositionUpdate(Alignment position) {
    _positionControllers[position]?.add(null);
  }

  static bool _isBottomPosition(Alignment position) {
    return position == .bottomLeft ||
        position == .bottomCenter ||
        position == .bottomRight;
  }

  static bool _isTopPosition(Alignment position) {
    return position == .topLeft ||
        position == .topCenter ||
        position == .topRight;
  }

  static void hideAll() {
    for (final toasts in _toastsByPosition.values) {
      for (final toast in toasts) {
        toast.timer.cancel();
        toast.overlayEntry.remove();
      }
    }
    _toastsByPosition.clear();

    for (final controller in _positionControllers.values) {
      controller.close();
    }
    _positionControllers.clear();
  }
}

class _ToastStackOverlay extends StatefulWidget {
  final String toastId;
  final String? text;
  final Widget? child;
  final ToastType type;
  final Alignment position;
  final double margin;
  final Stream<void> positionStream;

  const _ToastStackOverlay({
    super.key,
    required this.toastId,
    this.text,
    this.child,
    required this.type,
    required this.position,
    required this.margin,
    required this.positionStream,
  });

  @override
  State<_ToastStackOverlay> createState() => _ToastStackOverlayState();
}

class _ToastStackOverlayState extends State<_ToastStackOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _positionController;
  late AnimationController _exitController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _positionAnimation;
  late Animation<double> _exitFadeAnimation;
  late Animation<Offset> _exitSlideAnimation;
  bool _isExiting = false;

  StreamSubscription<void>? _positionSubscription;
  double _currentStackOffset = 0;
  double _targetStackOffset = 0;

  static const double toastHeight =
      64.0; // Approximate toast height with padding

  @override
  void initState() {
    super.initState();

    // Entry animation controller
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Position animation controller for smooth repositioning
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Exit animation controller — faster than entry.
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: _getSlideOffset(),
      end: .zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _positionController, curve: Curves.easeInOut),
    );

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _exitSlideAnimation = Tween<Offset>(
      begin: .zero,
      end: _getSlideOffset(),
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // Listen to position updates
    _positionSubscription = widget.positionStream.listen((_) {
      _updatePosition();
    });

    _entryController.forward();
    _updatePosition(); // Initial position calculation
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _entryController.dispose();
    _positionController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> playExit() {
    if (_isExiting)
      return _exitController.forward().orCancel.catchError((_) {});
    _isExiting = true;
    return _exitController.forward();
  }

  void _updatePosition() {
    if (_isExiting) return;
    final newStackOffset = _getStackOffset();
    if (newStackOffset != _targetStackOffset) {
      _currentStackOffset = _targetStackOffset;
      _targetStackOffset = newStackOffset;

      _positionController.reset();
      _positionController.forward();
    }
  }

  Offset _getSlideOffset() {
    switch (widget.position) {
      case .topLeft:
      case .topCenter:
      case .topRight:
        return const Offset(0, -1);
      case .bottomLeft:
      case .bottomCenter:
      case .bottomRight:
        return const Offset(0, 1);
      case .centerLeft:
        return const Offset(-1, 0);
      case .centerRight:
        return const Offset(1, 0);
      case .center:
        return const Offset(0, -0.1);
      default:
        return .zero;
    }
  }

  double _getStackOffset() {
    // Calculate the current stack index based on existing toasts
    final toasts = OnyxiaToast._toastsByPosition[widget.position] ?? [];
    final currentIndex = toasts.indexWhere(
      (toast) => toast.id == widget.toastId,
    );

    if (currentIndex == -1) return 0;

    final stackOffset = (toastHeight + 8.0) * currentIndex;

    // Adjust offset direction based on position
    switch (widget.position) {
      case .topLeft:
      case .topCenter:
      case .topRight:
      // For top positions: index 0 = top (newest), higher indices move down
      case .centerLeft:
      case .center:
      case .centerRight:
        // For center positions: stack downward
        return stackOffset; // Stack downward from top
      case .bottomLeft:
      case .bottomCenter:
      case .bottomRight:
        // For bottom positions: index 0 = bottom (newest), higher indices move up
        return -stackOffset; // Stack upward from bottom (negative offset)
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryController,
        _positionController,
        _exitController,
      ]),
      builder: (context, child) {
        // Interpolate between current and target stack offsets
        final interpolatedOffset =
            _currentStackOffset +
            (_targetStackOffset - _currentStackOffset) *
                _positionAnimation.value;

        return Positioned.fill(
          child: Align(
            alignment: widget.position,
            child: Transform.translate(
              offset: Offset(0, interpolatedOffset),
              child: Container(
                margin: .all(widget.margin),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _exitFadeAnimation,
                      child: SlideTransition(
                        position: _exitSlideAnimation,
                        child: GestureDetector(
                          behavior: .opaque,
                          onTap: () => OnyxiaToast._startExit(
                            widget.toastId,
                            widget.position,
                          ),
                          child: _ToastWidget(
                            text: widget.text,
                            type: widget.type,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToastWidget extends StatelessWidget {
  final String? text;
  final Widget? child;
  final ToastType type;

  const _ToastWidget({this.text, this.child, required this.type});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: .circular(8),
      color: _getBackgroundColor(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 400),
        padding: .symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: child != null ? .max : .min,
          spacing: 12,
          children: [
            Icon(_getIcon(), color: _getIconColor(context), size: 20),
            if (child != null)
              Expanded(child: child!)
            else
              Flexible(
                child: Text(
                  text!,
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 14,
                    fontWeight: .w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) => switch (type) {
    .success => NarwhalColors.green900,
    .warning => ThemeHelper.amber(),
    .error => ThemeHelper.errorColor(),
    .info => ThemeHelper.neutral400(),
  };

  Color _getTextColor(BuildContext context) => switch (type) {
    .success => ThemeHelper.neutral300(),
    .warning => ThemeHelper.neutral100(),
    .error => ThemeHelper.black(),
    .info => ThemeHelper.neutral800(),
  };

  Color _getIconColor(BuildContext context) => switch (type) {
    .success => NarwhalColors.green300,
    .warning => ThemeHelper.neutral100(),
    .error => ThemeHelper.black(),
    .info => ThemeHelper.accentColor(),
  };

  IconData _getIcon() => switch (type) {
    .success => LucideIcons.circleCheck,
    .warning => LucideIcons.triangleAlert,
    .error => LucideIcons.circleX,
    .info => LucideIcons.info,
  };
}

/// Content widget used inside upload progress toasts.
/// Updates live via a [ValueNotifier<double>] (0.0–1.0).
class _ProgressToastContent extends StatelessWidget {
  final String label;
  final ValueNotifier<double> progress;

  const _ProgressToastContent({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, value, _) {
        final safeValue = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
        final percent = (safeValue * 100).toInt();
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              spacing: 8,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: ThemeHelper.neutral800(),
                      fontSize: 14,
                      fontWeight: .w500,
                    ),
                    overflow: .ellipsis,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: ThemeHelper.neutral600(),
                    fontSize: 12,
                    fontWeight: .w400,
                  ),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: .circular(4),
              child: LinearProgressIndicator(
                value: safeValue > 0 ? safeValue : null,
                minHeight: 4,
                backgroundColor: ThemeHelper.neutral500(),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeHelper.accentColor(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
