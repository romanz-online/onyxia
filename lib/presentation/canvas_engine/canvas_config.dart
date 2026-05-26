import 'package:onyxia/export.dart';
import 'providers/tool_mode_provider.dart';

enum ArtifactCanvasDisplay with NarwhalEnum { pin, object }

class CanvasConfig {
  final bool allowArtifactsOnBackground;
  final ArtifactCanvasDisplay artifactDisplay;
  final bool allowFileDrops;
  final CanvasType canvasType;
  final List<ToolMode?> toolbar;
  final ArrowType defaultArrowType;
  final bool allowPasting;

  const CanvasConfig({
    required this.allowArtifactsOnBackground,
    required this.artifactDisplay,
    required this.allowFileDrops,
    required this.canvasType,
    required this.toolbar,
    required this.defaultArrowType,
    required this.allowPasting,
  });

  factory CanvasConfig.fromType(CanvasType type) => switch (type) {
    .whiteboard => CanvasConfig.whiteboard(),
    .markup => CanvasConfig.markup(),
    .flow => CanvasConfig.flow(),
  };

  factory CanvasConfig.whiteboard() {
    return const CanvasConfig(
      allowArtifactsOnBackground: false,
      artifactDisplay: .pin,
      allowFileDrops: true,
      canvasType: .whiteboard,
      defaultArrowType: .segmented,
      allowPasting: true,
      toolbar: [
        .pointer,
        .pan,
        null,
        .rectangle,
        .diamond,
        .oblong,
        .circle,
        .rhombus,
        .trapezoid,
        .cylinder,
        .house,
        .reverseHouse,
        .arrow,
        null,
        .image,
        .text,
        null,
        .brush,
        null,
        .comment,
        .artifact,
      ],
    );
  }

  factory CanvasConfig.markup() {
    return const CanvasConfig(
      allowArtifactsOnBackground: true,
      artifactDisplay: .pin,
      allowFileDrops: false,
      canvasType: .markup,
      defaultArrowType: .curved,
      allowPasting: false,
      toolbar: [.pointer, .pan, null, .comment, .artifact],
    );
  }

  factory CanvasConfig.flow() {
    return const CanvasConfig(
      allowArtifactsOnBackground: false,
      artifactDisplay: .object,
      allowFileDrops: true,
      canvasType: .flow,
      defaultArrowType: .curved,
      allowPasting: false,
      toolbar: [.pointer],
    );
  }
}
