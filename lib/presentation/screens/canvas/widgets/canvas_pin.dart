import 'package:onyxia/export.dart';
import '../providers/providers.dart';

class CanvasPin extends ConsumerStatefulWidget {
  final Pin pin;
  final CanvasObject? canvasObject;
  final Offset position;
  final TransformationController transformationController;

  const CanvasPin({
    super.key,
    required this.pin,
    this.canvasObject,
    required this.transformationController,
    required this.position,
  });

  @override
  ConsumerState<CanvasPin> createState() => _CanvasPinState();
}

class _CanvasPinState extends ConsumerState<CanvasPin>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _paddingAnimation;
  String? _lastNoteName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _widthAnimation = Tween<double>(
      begin: 36.0,
      end: 360.0, // Will be updated dynamically
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _heightAnimation = Tween<double>(
      begin: 36.0,
      end: 44.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _paddingAnimation = Tween<double>(
      begin: 4.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  void _updateWidthAnimation(String text, BuildContext context) {
    final double targetWidth = _calculateRequiredWidth(text, context);

    _widthAnimation = Tween<double>(
      begin: 36.0,
      end: targetWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get isExpanded =>
      ref.read(expandedPinProvider.notifier).isExpanded(widget.pin.id);

  double _calculateRequiredWidth(String text, BuildContext context) {
    if (text.isEmpty) {
      text = 'Untitled';
    }

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: NarwhalTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeHelper.neutral900(context),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final double iconWidth = 24.0; // icon width
    final double iconPadding = 8.0 * 2; // left and right padding around icon
    final double textLeftPadding = 4.0; // left padding for text
    final double textRightPadding = 20.0; // right padding for text

    final double totalWidth = iconPadding +
        iconWidth +
        textLeftPadding +
        textPainter.width +
        textRightPadding;

    return totalWidth.clamp(36.0, 360.0);
  }

  void _handleHoverEnter() {
    if (!isExpanded) {
      _animationController.forward();
    }
  }

  void _handleHoverExit() {
    if (!isExpanded) {
      _animationController.reverse();
    }
  }

  void _onTap(Artifact item) {
    if (isExpanded) {
      ref.read(expandedPinProvider.notifier).collapsePin();
      _handleHoverExit();
    } else {
      _animationController
          .reset(); // Instantly reset to collapsed state without animation
      ref.read(expandedPinProvider.notifier).expandPin(widget.pin);
      ref.read(selectedArtifactProvider.notifier).state = item;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final double scale =
          widget.transformationController.value.getMaxScaleOnAxis();
      final notes = ref.watch(artifactsProvider);
      final notesLoaded = ref.watch(artifactsLoadedProvider);
      final note = notes.firstWhereOrNull(
        (req) => req.id == widget.pin.artifactId,
      );

      // Handle new pins with empty artifactId - use placeholder note
      final effectiveNote =
          note ?? (widget.pin.artifactId.isEmpty ? Note(name: '') : null);

      // Loading state - show spinner while notes are loading
      if (!notesLoaded && effectiveNote == null) {
        return const SizedBox.shrink();
      }

      // Error state - note doesn't exist after loading is complete
      if (notesLoaded &&
          effectiveNote == null &&
          widget.pin.artifactId.isNotEmpty) {
        return const SizedBox.shrink();
      }

      // Should never happen, but safety check
      if (effectiveNote == null) return const SizedBox.shrink();

      if (_lastNoteName != effectiveNote.name) {
        _lastNoteName = effectiveNote.name;
        // Use WidgetsBinding to update animation after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateWidthAnimation(effectiveNote.name, context);
        });
      }

      final Color backgroundColor = ThemeHelper.neutral100(context);
      final Color outerBorderColor = ThemeHelper.neutral400(context);
      final Color selectionColor = ThemeHelper.blue500(context);

      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // For collapsed state, anchor from bottom-left during hover animation
          final heightDelta = _heightAnimation.value - 36.0;

          // Position container so pin's bottom-left stays at widget.position (accounting for zoom)
          final containerTop = widget.position.dy - heightDelta - 24;
          final containerLeft = widget.position.dx;
          final widgetWidth = _widthAnimation.value / scale;
          final widgetHeight = _heightAnimation.value / scale;

          return Positioned(
            top: containerTop,
            left: containerLeft,
            width: widgetWidth * scale,
            height: widgetHeight * scale,
            child: Transform.scale(
              alignment: Alignment.topLeft,
              scale: 1 / scale,
              child: MouseRegion(
                onEnter: (_) => _handleHoverEnter(),
                onExit: (_) => _handleHoverExit(),
                child: GestureDetector(
                  onTap: () => _onTap(effectiveNote),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: _widthAnimation.value,
                        height: _heightAnimation.value,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isExpanded ? selectionColor : outerBorderColor,
                            width: isExpanded ? 2.0 : 1.5,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(8),
                            topRight: const Radius.circular(8),
                            bottomRight: const Radius.circular(8),
                            bottomLeft: const Radius.circular(1),
                          ),
                          color: backgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: outerBorderColor.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: _paddingAnimation.value +
                                    (isExpanded ? 0.0 : 0.5),
                                right: _paddingAnimation.value,
                                top: _paddingAnimation.value,
                                bottom: _paddingAnimation.value,
                              ),
                              child: const NarwhalIcon(NarwhalIcons.edit,
                                  safeMode: true),
                            ),
                            if (_widthAnimation.value > 36)
                              Expanded(
                                child: Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12, left: 4),
                                    child: Text(
                                      effectiveNote.name.isNotEmpty
                                          ? effectiveNote.name
                                          : 'Untitled',
                                      style: NarwhalTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ThemeHelper.neutral900(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
