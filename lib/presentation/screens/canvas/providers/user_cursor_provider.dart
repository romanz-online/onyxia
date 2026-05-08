import 'package:onyxia/export.dart';
import 'objects_provider.dart';

final canvasMousePressedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final cursorIconOverrideProvider =
    StateNotifierProvider.autoDispose<CursorIconOverrideNotifier, MouseCursor?>(
        (ref) {
  return CursorIconOverrideNotifier();
});

class CursorIconOverrideNotifier extends StateNotifier<MouseCursor?> {
  CursorIconOverrideNotifier() : super(null);

  void setCursor(MouseCursor? cursor) {
    if (cursor != state) {
      state = cursor;
    }
  }
}

final usersCursorProvider =
    StateNotifierProvider.autoDispose<UserCursorNotifier, List<UserCursor>>(
        (ref) {
  final projectId = ref.watch(projectsProvider).selectedProject.id;
  final currentUserId = ref.watch(currentUserProvider).id;
  final currentUserEmail = ref.watch(currentUserProvider).email;
  final canvasId = ref.watch(currentCanvasProvider.select((c) => c?.id ?? ''));

  return UserCursorNotifier(
    CanvasCursorsRepository(projectId: projectId, canvasId: canvasId),
    canvasId,
    currentUserId,
    currentUserEmail,
  );
});

class UserCursorNotifier extends StateNotifier<List<UserCursor>> {
  final CanvasCursorsRepository canvasCursorsRepository;
  final String canvasId;
  final String currentUserId;
  final String currentUserEmail;
  Color? _currentUserColor;
  StreamSubscription? _cursorSubscription;

  DateTime _lastUpdateTime = DateTime.now();
  Timer? _throttleTimer;
  Offset? _pendingPosition;
  // Track the latest cursor position for drag and drop operations
  Offset _latestPosition = Offset.zero;

  UserCursorNotifier(
    this.canvasCursorsRepository,
    this.canvasId,
    this.currentUserId,
    this.currentUserEmail,
  ) : super([]) {
    if (!mounted) return;
    _init();
    // Generate a dummy user ID
    _currentUserColor = RandomColor.getRandomFromId(
        currentUserId); // Default color for current user
  }

  void _cancelSubscriptions() {
    _cursorSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _init() {
    if (canvasId.isEmpty) return;

    // Listen for cursor updates from Firestore
    _cursorSubscription = canvasCursorsRepository
        .getCursorsStream(currentUserId, currentUserEmail)
        .listen((cursors) {
      if (mounted) state = cursors.cast<UserCursor>();
    });
  }

  void updateMyCursor(Offset position) {
    _pendingPosition = position;
    // Always update the latest position
    _latestPosition = position;

    final now = DateTime.now();
    if (now.difference(_lastUpdateTime).inMilliseconds >= 1000) {
      _doUpdate(position);
      return;
    }

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      final timeToWait = 1000 - now.difference(_lastUpdateTime).inMilliseconds;
      _throttleTimer = Timer(Duration(milliseconds: timeToWait), () {
        if (mounted && _pendingPosition != null) _doUpdate(_pendingPosition!);
      });
    }
  }

  void _doUpdate(Offset position) {
    if (_pendingPosition != null) {
      canvasCursorsRepository.add(UserCursor(
        userId: currentUserId,
        userEmail: currentUserEmail,
        position: position,
        color: _currentUserColor!,
      ));
      _lastUpdateTime = DateTime.now();
      _pendingPosition = null;
    }
  }

  void removeMyCursor() {
    // Cancel any pending updates
    _throttleTimer?.cancel();
    _pendingPosition = null;

    // Remove current user's cursor when they leave
    canvasCursorsRepository.delete(currentUserId);
  }

  /// Get the latest cursor position for drag and drop operations
  /// Returns the most recently tracked cursor position or null if none available
  Offset? getLatestPosition() {
    // First try: If we have a pending position, use that (most up-to-date)
    if (_pendingPosition != null) {
      return _pendingPosition;
    }

    // Second try: Use the latest known position from tracking updates
    if (_latestPosition != Offset.zero) {
      return _latestPosition;
    }

    // Nothing available
    return null;
  }
}
