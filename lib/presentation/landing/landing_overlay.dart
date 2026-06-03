import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/create_account_view.dart';
import 'package:onyxia/presentation/landing/widgets/forgot_password_view.dart';
import 'package:onyxia/presentation/landing/widgets/info_message_view.dart';
import 'package:onyxia/presentation/landing/widgets/landing_back_button.dart';
import 'package:onyxia/presentation/landing/widgets/pre_auth_view.dart';
import 'package:onyxia/presentation/landing/widgets/reset_password_view.dart';
import 'package:onyxia/presentation/landing/widgets/logged_in_view.dart';

enum LandingMode {
  signIn,
  createAccount,
  forgotPassword,
  checkInbox,
  resetSent,
  resetPassword,
}

class LandingOverlay extends ConsumerStatefulWidget {
  final LandingMode initialMode;
  final String? inviteToken;
  final String? inviteDestPath;

  const LandingOverlay({
    super.key,
    this.initialMode = .signIn,
    this.inviteToken,
    this.inviteDestPath,
  });

  @override
  ConsumerState<LandingOverlay> createState() => _LandingOverlayState();
}

class _LandingOverlayState extends ConsumerState<LandingOverlay> {
  static const double _minWidth = 600;
  static const double _minHeight = 400;
  static const double _handleThickness = 6;

  double _width = 600;
  double _height = 400;
  Offset _position = const Offset(400, 400);

  Offset? _moveStartCursor;
  Offset? _moveStartPosition;
  Rect? _resizeStartRect;

  late LandingMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;

    final size =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final logicalSize = size / dpr;
    _position = Offset(
      (logicalSize.width - _width) / 2,
      (logicalSize.height - _height) / 2,
    );
  }

  void _setMode(LandingMode mode) {
    setState(() => _mode = mode);
  }

  void _onPanStart(DragStartDetails d) {
    _moveStartCursor = d.globalPosition;
    _moveStartPosition = _position;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_moveStartCursor == null || _moveStartPosition == null) return;

    final size = MediaQuery.of(context).size;
    final delta = d.globalPosition - _moveStartCursor!;

    setState(() {
      _position = Offset(
        (_moveStartPosition!.dx + delta.dx).clamp(0, size.width - _width),
        (_moveStartPosition!.dy + delta.dy).clamp(0, size.height - _height),
      );
    });
  }

  void _onResizeStart(DragStartDetails d) {
    _resizeStartRect = Rect.fromLTWH(
      _position.dx,
      _position.dy,
      _width,
      _height,
    );
  }

  void _onResize(
    DragUpdateDetails d, {
    bool fromTop = false,
    bool fromLeft = false,
    bool fromBottom = false,
    bool fromRight = false,
  }) {
    if (_resizeStartRect == null) return;

    final viewport = MediaQuery.of(context).size;
    final rect = _resizeStartRect!;
    final cursor = d.globalPosition;

    double newX = rect.left;
    double newY = rect.top;
    double newWidth = rect.width;
    double newHeight = rect.height;

    if (fromRight) {
      newWidth = (cursor.dx - rect.left).clamp(
        _minWidth,
        viewport.width - rect.left,
      );
    } else if (fromLeft) {
      final rawRight = rect.right; // right edge stays fixed
      final rawNewX = cursor.dx.clamp(0.0, rawRight - _minWidth);
      newX = rawNewX;
      newWidth = (rawRight - newX).clamp(_minWidth, rawRight);
    }

    if (fromBottom) {
      newHeight = (cursor.dy - rect.top).clamp(
        _minHeight,
        viewport.height - rect.top,
      );
    } else if (fromTop) {
      final rawBottom = rect.bottom; // bottom edge stays fixed
      final rawNewY = cursor.dy.clamp(0.0, rawBottom - _minHeight);
      newY = rawNewY;
      newHeight = (rawBottom - newY).clamp(_minHeight, rawBottom);
    }

    setState(() {
      _width = newWidth;
      _height = newHeight;
      _position = Offset(newX, newY);
    });
  }

  Widget _resizeHandle({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
    required MouseCursor cursor,
    bool fromTop = false,
    bool fromLeft = false,
    bool fromBottom = false,
    bool fromRight = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: .opaque,
          onPanStart: _onResizeStart,
          onPanUpdate: (d) => _onResize(
            d,
            fromTop: fromTop,
            fromLeft: fromLeft,
            fromBottom: fromBottom,
            fromRight: fromRight,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    final content = userAsync.when(
      loading: () => const Center(child: OnyxiaLoadingIndicator()),
      error: (e, _) => Center(
        child: Text(
          'An unexpected error occurred.',
          style: TextStyle(color: ThemeHelper.error()),
        ),
      ),
      data: (user) => _buildContent(context, user),
    );

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: .opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeHelper.background1(),
                    borderRadius: .circular(8),
                    border: .all(color: ThemeHelper.auxiliary(), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeHelper.foreground1().withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(borderRadius: .circular(8), child: content),
                ),
              ),
            ),
            // Edges
            _resizeHandle(
              left: 0,
              right: 0,
              top: 0,
              height: _handleThickness,
              cursor: SystemMouseCursors.resizeUpDown,
              fromTop: true,
            ),
            _resizeHandle(
              left: 0,
              right: 0,
              bottom: 0,
              height: _handleThickness,
              cursor: SystemMouseCursors.resizeUpDown,
              fromBottom: true,
            ),
            _resizeHandle(
              left: 0,
              top: 0,
              bottom: 0,
              width: _handleThickness,
              cursor: SystemMouseCursors.resizeLeftRight,
              fromLeft: true,
            ),
            _resizeHandle(
              right: 0,
              top: 0,
              bottom: 0,
              width: _handleThickness,
              cursor: SystemMouseCursors.resizeLeftRight,
              fromRight: true,
            ),
            // Corners — slightly larger and stacked on top of edges so they win
            _resizeHandle(
              left: 0,
              top: 0,
              width: _handleThickness * 2,
              height: _handleThickness * 2,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              fromTop: true,
              fromLeft: true,
            ),
            _resizeHandle(
              right: 0,
              top: 0,
              width: _handleThickness * 2,
              height: _handleThickness * 2,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              fromTop: true,
              fromRight: true,
            ),
            _resizeHandle(
              left: 0,
              bottom: 0,
              width: _handleThickness * 2,
              height: _handleThickness * 2,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              fromBottom: true,
              fromLeft: true,
            ),
            _resizeHandle(
              right: 0,
              bottom: 0,
              width: _handleThickness * 2,
              height: _handleThickness * 2,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              fromBottom: true,
              fromRight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    final showBackButton = _mode != .signIn;
    return Stack(
      children: [
        Positioned.fill(child: _buildScreen(context, user)),
        if (showBackButton)
          LandingBackButton(onPressed: () => _setMode(.signIn)),
      ],
    );
  }

  Widget _buildScreen(BuildContext context, User user) => switch (_mode) {
    .resetPassword => const ResetPasswordView(),
    .createAccount => CreateAccountView(onNavigate: _setMode),
    .forgotPassword => ForgotPasswordView(onNavigate: _setMode),
    .checkInbox => const InfoMessageView(
      title: 'Check your inbox',
      message:
          'Check your inbox to confirm your email, then return here to sign in.',
      // TODO: make a customized confirmation email. right now we're using the generic supabase one
    ),
    .resetSent => const InfoMessageView(
      title: 'Reset link sent',
      message:
          'If an account exists for that email, a reset link is on its way.',
    ),
    .signIn =>
      user.isLogged ? const LoggedInView() : PreAuthView(onNavigate: _setMode),
  };
}
