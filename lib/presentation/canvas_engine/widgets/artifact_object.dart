import 'package:onyxia/export.dart';

class ArtifactObject extends ConsumerWidget {
  final CanvasObject canvasObject;

  const ArtifactObject({super.key, required this.canvasObject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(artifactsProvider);
    final notesLoaded = notesAsync.hasValue;
    final notes = notesAsync.value ?? const <Artifact>[];

    // Find the note by artifactId from the canvas object
    final String artifactId = canvasObject.artifactProps.artifactId;
    final note = notes.firstWhereOrNull((req) => req.id == artifactId);

    final size = canvasObject.getDimensions();

    // Handle loading state
    if (!notesLoaded) {
      return _buildLoadingView(context, size.width, size.height);
    }

    // Handle error state - note not found
    if (note == null) {
      return _buildErrorView(context, size.width, size.height);
    }

    // Determine layout based on available space and wrap with positioning
    Widget child;
    if (size.height < 64 && size.width < 64) {
      child = _buildIconOnlyView(context, size.width, size.height);
    } else if (size.height < 64) {
      child = _buildHeaderOnlyView(context, size.width, size.height, note);
    } else {
      child = _buildFullView(context, size.width, size.height, note);
    }

    return Positioned(
      left: canvasObject.topLeft.dx,
      top: canvasObject.topLeft.dy,
      child: IgnorePointer(ignoring: true, child: child),
    );
  }

  Widget _buildIconOnlyView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        borderRadius: .circular(8),
        border: .all(color: ThemeHelper.auxiliary(), width: 1),
      ),
      child: const Center(child: Icon(LucideIcons.square, size: 24)),
    );
  }

  Widget _buildHeaderOnlyView(
    BuildContext context,
    double width,
    double height,
    Artifact item,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        borderRadius: .circular(8),
        border: .all(color: ThemeHelper.auxiliary(), width: 1),
      ),
      padding: .symmetric(horizontal: 12, vertical: 8),
      child: Center(
        child: Text(
          item.name.isEmpty ? 'Untitled' : item.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: .w500,
            color: ThemeHelper.foreground1(),
          ),
          overflow: .ellipsis,
          maxLines: 1,
          textAlign: .center,
        ),
      ),
    );
  }

  Widget _buildFullView(
    BuildContext context,
    double width,
    double height,
    Artifact item,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        borderRadius: .circular(8),
        border: .all(color: ThemeHelper.auxiliary(), width: 1),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          // Header area
          Container(
            padding: .symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeHelper.background2(),
              borderRadius: .only(
                topLeft: .circular(7),
                topRight: .circular(7),
              ),
            ),
            child: Text(
              item.name.isEmpty ? 'Untitled' : item.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: .w600,
                color: ThemeHelper.foreground1(),
              ),
              overflow: .ellipsis,
              maxLines: 2,
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: ThemeHelper.auxiliary()),

          // Content area
          Expanded(
            child: Container(
              padding: .all(12),
              child: SingleChildScrollView(child: _buildContent(context, item)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Artifact item) {
    if (item.type == .note) {
      return Text(
        item is NoteArtifact ? item.content : '',
        style: TextStyle(
          color: ThemeHelper.foreground2(),
          fontSize: 12,
          height: 1.4,
        ),
      );
    }

    // For other item types, use plain text as before
    String contentText;
    switch (item.type) {
      case .canvas:
        contentText = 'Canvas content';
        break;
      case .folder:
        contentText = 'Folder content';
        break;
      case .note:
        // This case should not be reached due to the early return above
        contentText = 'Note content';
        break;
      case .image:
        contentText = 'Image content';
        break;
    }

    return Text(
      contentText,
      style: TextStyle(
        fontSize: 10,
        fontWeight: .w600,
        color: ThemeHelper.foreground2(),
        height: 1.4,
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        borderRadius: .circular(8),
        border: .all(color: ThemeHelper.auxiliary(), width: 1),
      ),
      child: Center(child: OnyxiaLoadingIndicator()),
    );
  }

  Widget _buildErrorView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.background1(),
        borderRadius: .circular(8),
        border: .all(color: Colors.red.withValues(alpha: 0.5), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(LucideIcons.trash2, color: Colors.red, size: 24),
            const Gap(8),
            Text(
              'Note not found',
              style: TextStyle(
                fontSize: 10,
                fontWeight: .w500,
                color: Colors.red,
              ),
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}
