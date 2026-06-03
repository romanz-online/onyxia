import 'package:onyxia/export.dart';

/// Drives a [OnyxiaValidator]: owns the link between the trigger and the
/// follower, the overlay controller, and the current error message. Either
/// feed it a [validator] and call [validate], or push messages directly with
/// [showError] when the validation logic lives at the call site.
class OnyxiaValidatorController extends ChangeNotifier {
  OnyxiaValidatorController({this.validator});

  /// Optional validator returning an error message (or null when valid).
  final String? Function(String value)? validator;

  final LayerLink link = LayerLink();
  final OverlayPortalController overlay = OverlayPortalController();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Runs [validator] against [value], shows/hides the balloon accordingly,
  /// and returns true when the value is valid.
  bool validate(String value) {
    assert(validator != null, 'validate() requires a validator');
    final msg = validator?.call(value);
    showError(msg);
    return msg == null;
  }

  /// Shows the balloon with [message], or hides it when [message] is null.
  void showError(String? message) {
    _errorMessage = message;
    if (message == null) {
      overlay.hide();
    } else {
      overlay.show();
    }
    notifyListeners();
  }

  /// Hides the balloon and clears its message.
  void clear() => showError(null);
}

/// A reusable error speech balloon that follows its [child] (typically a text
/// field). Configurable like [OnyxiaTooltip]; show/hide and message are driven
/// by a [OnyxiaValidatorController].
class OnyxiaValidator extends StatelessWidget {
  const OnyxiaValidator({
    super.key,
    required this.controller,
    required this.child,
    this.color,
    this.textStyle,
    this.offset = const Offset(0, 9),
    this.nipHeight = 8,
    this.borderRadius = 6,
  });

  final OnyxiaValidatorController controller;
  final Widget child;

  /// Balloon background. Defaults to [ThemeHelper.error].
  final Color? color;

  /// Message text style. Defaults to a bold 14px on [ThemeHelper.foreground1].
  final TextStyle? textStyle;

  /// Follower offset relative to the trigger's bottom-center.
  final Offset offset;
  final double nipHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: controller.overlay,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: controller.link,
        targetAnchor: .bottomCenter,
        followerAnchor: .topCenter,
        offset: offset,
        child: Align(
          alignment: .topCenter,
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: SpeechBalloon(
                nipLocation: .top,
                color: color ?? ThemeHelper.error(),
                borderRadius: borderRadius,
                nipHeight: nipHeight,
                width: .infinity,
                height: .infinity,
                child: Center(
                  child: Padding(
                    padding: .symmetric(vertical: 5, horizontal: 12),
                    // Rebuilds on message change so the text updates even while
                    // the overlay is already shown.
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => Text(
                        controller.errorMessage ?? '',
                        style:
                            textStyle ??
                            TextStyle(
                              fontSize: 14,
                              color: ThemeHelper.foreground1(),
                              fontWeight: .w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(link: controller.link, child: child),
    );
  }
}
