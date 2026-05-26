import 'package:onyxia/export.dart';

/// A Material-based CustomPaint wrapper that ensures consistent color rendering
/// across different Flutter widgets by using Material's color system instead
/// of direct Canvas painting for backgrounds.
///
/// This solves the problem where CustomPaint and Material widgets render colors
/// differently due to different color spaces, blending modes, and rendering pipelines.
class NarwhalPaint extends StatelessWidget {
  final Color? backgroundColor;
  final CustomPainter? painter;
  final Size? size;
  final Widget? child;

  const NarwhalPaint({
    super.key,
    this.backgroundColor,
    this.painter,
    this.size,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      type: .canvas,
      child: painter != null
          ? CustomPaint(painter: painter, size: size ?? Size.zero, child: child)
          : child,
    );
  }
}

/// A CustomPainter that integrates with NarwhalPaint to provide consistent
/// color rendering. Background colors should be handled by the NarwhalPaint
/// wrapper rather than painted directly on the canvas.
///
/// This abstract class provides convenience methods for theme-aware painting
/// and encourages best practices for consistent color rendering.
abstract class NarwhalPainter extends CustomPainter {
  final BuildContext context;

  NarwhalPainter(this.context);

  /// Override this method to implement your painting logic.
  /// Do not paint background colors here - use NarwhalPaint.backgroundColor instead.
  @override
  void paint(Canvas canvas, Size size);

  /// Convenience method to get theme-aware colors
  Color getThemeColor(Color Function(BuildContext) colorProvider) {
    return colorProvider(context);
  }

  /// Convenience method for creating Paint objects with theme colors
  Paint createThemePaint(
    Color Function(BuildContext) colorProvider, {
    double? strokeWidth,
    StrokeCap? strokeCap,
    PaintingStyle? style,
  }) {
    return Paint()
      ..color = getThemeColor(colorProvider)
      ..strokeWidth = strokeWidth ?? 1.0
      ..strokeCap = strokeCap ?? .butt
      ..style = style ?? .fill;
  }
}
