import 'package:onyxia/export.dart';

class ArtifactObject extends ConsumerWidget {
  final CanvasObject canvasObject;

  const ArtifactObject({
    super.key,
    required this.canvasObject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(artifactsProvider);
    final notesLoaded = ref.watch(artifactsLoadedProvider);

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
      child: IgnorePointer(
        ignoring: true,
        child: child,
      ),
    );
  }

  Widget _buildIconOnlyView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.neutral400(context),
          width: 1,
        ),
      ),
      child: const Center(
        child: NarwhalIcon(
          NarwhalIcons.placeholder,
          size: 24,
        ),
      ),
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
        color: ThemeHelper.neutral100(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.neutral400(context),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Center(
        child: Text(
          item.title.isEmpty ? 'Untitled' : item.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeHelper.neutral700(context),
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
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
        color: ThemeHelper.neutral100(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.neutral400(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeHelper.neutral200(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              item.title.isEmpty ? 'Untitled' : item.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeHelper.neutral700(context),
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: ThemeHelper.neutral400(context),
          ),

          // Content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: _buildContent(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Artifact item) {
    if (item.type == ArtifactType.note) {
      return MarkdownBody(
        data: item is Note ? item.content : '',
        styleSheet: MarkdownStyleSheet(
          p: NarwhalTextStyle(
            color: ThemeHelper.neutral500(context),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      );
    }

    // For other item types, use plain text as before
    String contentText;
    switch (item.type) {
      case ArtifactType.canvas:
        contentText = 'Canvas content';
        break;
      case ArtifactType.folder:
        contentText = 'Folder content';
        break;
      case ArtifactType.note:
        // This case should not be reached due to the early return above
        contentText = 'Note content';
        break;
    }

    return Text(
      contentText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeHelper.neutral500(context),
            height: 1.4,
          ),
    );
  }

  Widget _buildLoadingView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.neutral400(context),
          width: 1,
        ),
      ),
      child: Center(
        child: NarwhalSpinner(),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NarwhalIcon(
              NarwhalIcons.delete,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Note not found',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
