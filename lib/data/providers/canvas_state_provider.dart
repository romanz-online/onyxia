import 'package:onyxia/export.dart';

class CanvasState {
  final CanvasModel? canvas;
  final List<CanvasObject> objects;
  final List<Pin> pins;
  final List<Comment> comments;

  const CanvasState({
    this.canvas,
    this.objects = const [],
    this.pins = const [],
    this.comments = const [],
  });

  CanvasState copyWith({
    CanvasModel? canvas,
    List<CanvasObject>? objects,
    List<Pin>? pins,
    List<Comment>? comments,
  }) {
    return CanvasState(
      canvas: canvas ?? this.canvas,
      objects: objects ?? this.objects,
      pins: pins ?? this.pins,
      comments: comments ?? this.comments,
    );
  }
}

class CanvasNotifier extends StateNotifier<AsyncValue<CanvasState>> {
  final String projectId;
  final CanvasModel _canvas;
  final Ref ref;

  CanvasObjectsRepository? _objectsRepo;
  PinsRepository? _pinsRepo;
  CommentsRepository? _commentsRepo;

  StreamSubscription? _objectsSub;
  StreamSubscription? _pinsSub;
  StreamSubscription? _commentsSub;

  List<CanvasObject> _objects = [];
  List<Pin> _pins = [];
  List<Comment> _comments = [];

  CanvasNotifier({required this.projectId, required CanvasModel canvas, required this.ref})
      : _canvas = canvas,
        super(const AsyncValue.loading()) {
    if (projectId.isEmpty) {
      state = const AsyncValue.data(CanvasState());
      return;
    }
    _objectsRepo = CanvasObjectsRepository(projectId: projectId, canvasId: canvas.id);
    _pinsRepo = PinsRepository(projectId: projectId, canvasId: canvas.id);
    _commentsRepo = CommentsRepository(projectId: projectId);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        _objectsRepo!.getCanvasObjectsStream().first,
        _pinsRepo!.getPinsStream().first,
        _commentsRepo!.watchComments(targetId: _canvas.title).first,
      ]);

      _objects = (results[0] as CanvasObjects).objects;
      _pins = (results[1] as Pins).pins;
      _comments = results[2] as List<Comment>;

      if (mounted) {
        state = AsyncValue.data(CanvasState(
          canvas: _canvas,
          objects: _objects,
          pins: _pins,
          comments: _comments,
        ));
        _setupListeners();
      }
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  void _setupListeners() {
    _objectsSub = _objectsRepo?.getCanvasObjectsStream().listen((data) {
      _objects = data.objects;
      final current = state.value;
      if (mounted && current != null) {
        state = AsyncData(current.copyWith(objects: _objects));
      }
    });

    _pinsSub = _pinsRepo?.getPinsStream().listen((data) {
      _pins = data.pins;
      final current = state.value;
      if (mounted && current != null) {
        state = AsyncData(current.copyWith(pins: _pins));
      }
    });

    _commentsSub = _commentsRepo?.watchComments(targetId: _canvas.title).listen((data) {
      _comments = data;
      final current = state.value;
      if (mounted && current != null) {
        state = AsyncData(current.copyWith(comments: _comments));
      }
    });
  }

  @override
  void dispose() {
    _objectsSub?.cancel();
    _pinsSub?.cancel();
    _commentsSub?.cancel();
    super.dispose();
  }
}

/// Creates a CanvasNotifier for the currently selected CanvasModel item.
final selectedCanvasStateProvider =
    StateNotifierProvider.autoDispose<CanvasNotifier, AsyncValue<CanvasState>>((ref) {
  final item = ref.watch(selectedArtifactProvider);
  final projectId = ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  final authState = ref.watch(authProvider);

  if (item is! CanvasModel || projectId.isEmpty || authState.value == null) {
    return CanvasNotifier(projectId: '', canvas: CanvasModel(), ref: ref);
  }

  return CanvasNotifier(projectId: projectId, canvas: item, ref: ref);
});

/// Creates a CanvasNotifier for the folder child preview panel.
final selectedFolderChildCanvasStateProvider =
    StateNotifierProvider.autoDispose<CanvasNotifier, AsyncValue<CanvasState>>((ref) {
  final item = ref.watch(selectedFolderChildArtifactProvider);
  final projectId = ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  final authState = ref.watch(authProvider);

  if (item is! CanvasModel || projectId.isEmpty || authState.value == null) {
    return CanvasNotifier(projectId: '', canvas: CanvasModel(), ref: ref);
  }

  return CanvasNotifier(projectId: projectId, canvas: item, ref: ref);
});
