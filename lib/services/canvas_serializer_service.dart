import 'package:onyxia/export.dart';

class CanvasSerializerService extends Serializer<CanvasModel> {
  @override
  final String projectId;
  final String canvasId;
  final ArtifactsRepository repository;
  final CommentsRepository commentsRepository;
  final PinsRepository pinsRepository;
  final CanvasObjectsRepository canvasObjectsRepository;

  CanvasSerializerService({
    required this.projectId,
    required this.canvasId,
    required this.repository,
    CommentsRepository? commentsRepository,
  })  : commentsRepository =
            commentsRepository ?? CommentsRepository(projectId: projectId),
        pinsRepository = PinsRepository(
          projectId: projectId,
          canvasId: canvasId,
        ),
        canvasObjectsRepository = CanvasObjectsRepository(
          projectId: projectId,
          canvasId: canvasId,
        );

  @override
  String get itemId => canvasId;

  @override
  ArtifactType get itemType => ArtifactType.canvas;

  @override
  Future<Map<String, dynamic>> serialize() async {
    final stream = await repository.getCanvasesStream().first;
    final data = stream.firstWhere(
      (canvas) => canvas.id == canvasId,
      orElse: () => throw Exception('Canvas not found'),
    );

    final objectsStream =
        await canvasObjectsRepository.getCanvasObjectsStream().first;
    final objects = objectsStream.objects;

    // Fetch canvas comments using new canvas comments repository
    final commentsStream =
        await commentsRepository.watchComments(targetId: canvasId).first;

    final pinsStream = await pinsRepository.getPinsStream().first;
    final pins = pinsStream.pins;

    final serializedData = {
      'exportDate': TimestampService.getFixedLengthTimestamp(),
      'canvas': data.toMap(),
      'objects': objects.map((obj) => obj.toMap()).toList(),
      'comments': commentsStream.map((comment) => comment.toMap()).toList(),
      'pins': pins.map((pin) => pin.toMap()).toList(),
    };

    return serializedData;
  }

  @override
  Future<void> deserialize(Map<String, dynamic> data) async {
    _validateData(data);

    // Update canvas metadata (including imageUrl if present)
    if (data.containsKey('canvas')) {
      final canvasData = Map<String, dynamic>.from(data['canvas']);

      // Fetch current canvas data to get the latest state
      final canvas = (await repository.getCanvasesStream().first).first;

      // Update canvas title if present
      if (canvasData.containsKey('title')) {
        final updatedCanvas = canvas.copyWith(title: canvasData['title']);
        await repository.update(updatedCanvas);
      }

      // Update canvas imageUrl if present
      if (canvasData.containsKey('imageUrl') &&
          canvasData['imageUrl'] != null) {
        final updatedCanvas = canvas.copyWith(imageUrl: canvasData['imageUrl']);
        await repository.update(updatedCanvas);
      }
    }

    // Get current objects from the canvas to delete them
    final objectsStream = canvasObjectsRepository.getCanvasObjectsStream();
    final currentObjects = await objectsStream.first;

    // Delete all existing objects if any exist
    if (currentObjects.objects.isNotEmpty) {
      await canvasObjectsRepository.deleteMultiple(currentObjects.objects);
    }

    // Delete all existing comments if any exist
    await _deleteExistingComments();

    await _deleteExistingPins();

    final newObjects = List<Map<String, dynamic>>.from(data['objects'])
        .map((e) => CanvasObject.fromMap(e))
        .toList();

    // Import the new objects to the existing canvas
    await _importObjects(newObjects, canvasId);

    // Import comments if they exist in the data
    if (data.containsKey('comments')) {
      final newComments = List<Map<String, dynamic>>.from(data['comments'])
          .map((e) => Comment.fromMap(e))
          .toList();
      await _importComments(newComments);
    }
  }

  void _validateData(Map<String, dynamic> data) {
    if (data.isEmpty ||
        !data.containsKey('canvas') ||
        !data.containsKey('objects')) {
      throw FormatException('Missing required data. Data: $data');
    }
  }

  Future<void> _importObjects(
    List<CanvasObject> objects,
    String newCanvasId,
  ) async {
    // Sort objects by layer for proper stacking
    objects.sort((a, b) => a.layer.compareTo(b.layer));

    // Import all objects
    if (objects.isNotEmpty) {
      await canvasObjectsRepository.add(objects);
    }
  }

  Future<void> _deleteExistingComments() async {
    try {
      // Get all canvas comments
      final commentsStream =
          await commentsRepository.watchComments(targetId: canvasId).first;

      // Delete each comment
      for (final comment in commentsStream) {
        await commentsRepository.delete(comment.id);
      }
    } catch (e) {
      debugPrint(
          '_deleteExistingComments: Error deleting existing comments: $e');
      // Continue with import even if deletion fails
    }
  }

  Future<void> _deleteExistingPins() async {
    try {
      final pinsStream = await pinsRepository.getPinsStream().first;

      // Delete every pin
      if (pinsStream.pins.isNotEmpty) {
        await pinsRepository.deleteMultiple(pinsStream.pins);
      }
    } catch (e) {
      debugPrint('Error deleting existing pins: $e');
      // Continue with import even if deletion fails
    }
  }

  Future<void> _importComments(List<Comment> commentsData) async {
    try {
      for (final comment in commentsData) {
        // Handle sub-comments with new IDs
        final List<SubComment> newSubComments = [];
        for (final subComment in comment.subComments) {
          final newSubComment = SubComment(
            id: const Uuid().v4(),
            text: subComment.text,
            authorId: subComment.authorId,
            createdAt: subComment.createdAt,
          );
          newSubComments.add(newSubComment);
        }

        // Create a new comment with new ID and proper canvas targeting
        final newComment = Comment(
          id: const Uuid().v4(),
          text: comment.text,
          position: comment.position,
          color: comment.color,
          subComments: newSubComments,
          authorId: comment.authorId,
          createdAt: comment.createdAt,
          pinnedObjectId: comment.pinnedObjectId,
        );

        await commentsRepository.add([newComment]);
      }
    } catch (e) {
      debugPrint('_importComments: Error importing comments: $e');
      // Continue with import process
    }
  }
}
