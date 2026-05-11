import 'package:onyxia/export.dart';
import 'providers/tool_mode_provider.dart';

enum ArtifactCanvasDisplay with NarwhalEnum {
  pin,
  object,
}

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
        CanvasType.whiteboard => CanvasConfig.whiteboard(),
        CanvasType.markup => CanvasConfig.markup(),
        CanvasType.flow => CanvasConfig.flow(),
      };

  factory CanvasConfig.whiteboard() {
    return const CanvasConfig(
      allowArtifactsOnBackground: false,
      artifactDisplay: ArtifactCanvasDisplay.pin,
      allowFileDrops: true,
      canvasType: CanvasType.whiteboard,
      defaultArrowType: ArrowType.segmented,
      allowPasting: true,
      toolbar: [
        ToolMode.pointer,
        ToolMode.pan,
        null,
        ToolMode.rectangle,
        ToolMode.diamond,
        ToolMode.oblong,
        ToolMode.circle,
        ToolMode.rhombus,
        ToolMode.trapezoid,
        ToolMode.cylinder,
        ToolMode.house,
        ToolMode.reverseHouse,
        ToolMode.arrow,
        null,
        ToolMode.image,
        ToolMode.text,
        null,
        ToolMode.brush,
        null,
        ToolMode.comment,
        ToolMode.artifact,
      ],
    );
  }

  factory CanvasConfig.markup() {
    return const CanvasConfig(
      allowArtifactsOnBackground: true,
      artifactDisplay: ArtifactCanvasDisplay.pin,
      allowFileDrops: false,
      canvasType: CanvasType.markup,
      defaultArrowType: ArrowType.curved,
      allowPasting: false,
      toolbar: [
        ToolMode.pointer,
        ToolMode.pan,
        null,
        ToolMode.comment,
        ToolMode.artifact,
      ],
    );
  }

  factory CanvasConfig.flow() {
    return const CanvasConfig(
      allowArtifactsOnBackground: false,
      artifactDisplay: ArtifactCanvasDisplay.object,
      allowFileDrops: true,
      canvasType: CanvasType.flow,
      defaultArrowType: ArrowType.curved,
      allowPasting: false,
      toolbar: [
        ToolMode.pointer,
      ],
    );
  }
}
