import 'package:onyxia/export.dart';

class ImageEditorView extends StatelessWidget {
  final ImageArtifact artifact;
  const ImageEditorView({required this.artifact, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin = ((constraints.maxWidth - 800.0) / 2).clamp(
          0.0,
          double.infinity,
        );
        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: .symmetric(horizontal: horizontalMargin),
                child: Center(
                  child: Image.network(
                    artifact.downloadUrl,
                    fit: .scaleDown,
                    loadingBuilder: (ctx, child, progress) =>
                        progress == null ? child : OnyxiaLoadingIndicator(),
                    errorBuilder: (ctx, err, _) => Text(
                      'Failed to load image',
                      style: TextStyle(color: ThemeHelper.foreground1()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
