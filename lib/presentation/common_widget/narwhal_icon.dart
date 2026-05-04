import 'package:onyxia/export.dart';

class NarwhalIcon extends StatelessWidget {
  final NarwhalIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final List<Shadow>? shadows;
  final BlendMode? blendMode;
  final bool safeMode;

  const NarwhalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.shadows,
    this.blendMode,
    this.safeMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size ?? 24.0;
    final Color iconColor = color ?? ThemeHelper.neutral200(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Icons that should render with their original SVG colours in dark mode (no brightening).
    const darkModeFilterExcluded = {
      'assets/icons/RequirementsReq_Default.svg',
      'assets/icons/RequirementsSpec_Default.svg',
      'assets/icons/RequirementsTest_Default.svg',
      'assets/icons/RequirementsUS_Default.svg',
    };

    // In dark mode, safe-mode SVG icons have dark intrinsic colours that disappear
    // on dark surfaces. srcATop blends white over only the opaque SVG pixels —
    // transparent areas stay transparent (icon shape preserved), dark pixels become
    // light, and coloured pixels shift to a lighter/pastel version of their hue.
    final ColorFilter? resolvedFilter = safeMode
        ? (isDarkMode && !darkModeFilterExcluded.contains(icon.path)
            ? ColorFilter.mode(
                Colors.white.withValues(alpha: 0.45),
                BlendMode.srcATop,
              )
            : null)
        : ColorFilter.mode(iconColor, BlendMode.srcIn);

    Widget svgWidget = SvgPicture.asset(
      icon.path,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      colorFilter: resolvedFilter,
      semanticsLabel: semanticLabel,
    );

    if (shadows != null && shadows!.isNotEmpty) {
      svgWidget = Container(
        decoration: BoxDecoration(
          boxShadow: shadows!
              .map((shadow) => BoxShadow(
                    color: shadow.color,
                    offset: shadow.offset,
                    blurRadius: shadow.blurRadius,
                  ))
              .toList(),
        ),
        child: svgWidget,
      );
    }

    if (blendMode != null) {
      svgWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          iconColor,
          blendMode!,
        ),
        child: svgWidget,
      );
    }

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: svgWidget,
    );
  }
}
