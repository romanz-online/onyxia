import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/landing/widgets/create_account_view.dart';
import 'package:onyxia/presentation/landing/widgets/forgot_password_view.dart';
import 'package:onyxia/presentation/landing/widgets/info_message_view.dart';
import 'package:onyxia/presentation/landing/widgets/invite_view.dart';
import 'package:onyxia/presentation/landing/widgets/landing_back_button.dart';
import 'package:onyxia/presentation/landing/widgets/pre_auth_view.dart';
import 'package:onyxia/presentation/landing/widgets/reset_password_view.dart';
import 'package:onyxia/presentation/landing/widgets/vaults_view.dart';

enum LandingMode {
  signIn,
  createAccount,
  forgotPassword,
  checkInbox,
  resetSent,
  invite,
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

  // TODO: i should come up with a neater way of resizing that doesn't rely on delta so that if i drag my cursor off screen and the widget gets locked in place, the cursor and widget don't have a huge offset when the cursor returns
  double _width = 600;
  double _height = 400;
  Offset _position = const Offset(400, 400);

  late LandingMode _mode;

  // Invite-mode state.
  Future<Vault?>? _inviteVaultFuture;
  bool _acceptInFlight = false;

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

    if (widget.initialMode == .invite) {
      final destVaultId = _extractVaultId(widget.inviteDestPath ?? '');
      if (destVaultId != null) {
        _inviteVaultFuture = VaultsRepository().get(destVaultId);
      }
      // Already-signed-in case: ref.listen won't fire if there's no state
      // transition, so kick the RPC after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.inviteToken == null) return;
        final user = ref.read(currentUserProvider).value;
        if (user != null && user.isLogged) _acceptInvitation();
      });
    }
  }

  void _setMode(LandingMode mode) {
    setState(() => _mode = mode);
  }

  String? _extractVaultId(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'vault') return segments[1];
    return null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _position = Offset(
        (_position.dx + details.delta.dx).clamp(0, size.width - _width),
        (_position.dy + details.delta.dy).clamp(0, size.height - _height),
      );
    });
  }

  void _onResize(
    DragUpdateDetails d, {
    bool fromTop = false,
    bool fromLeft = false,
    bool fromBottom = false,
    bool fromRight = false,
  }) {
    final viewport = MediaQuery.of(context).size;
    double newWidth = _width;
    double newHeight = _height;
    double newX = _position.dx;
    double newY = _position.dy;

    if (fromRight) {
      newWidth = (_width + d.delta.dx).clamp(
        _minWidth,
        viewport.width - _position.dx,
      );
    } else if (fromLeft) {
      newWidth = (_width - d.delta.dx).clamp(_minWidth, _position.dx + _width);
      newX = _position.dx + (_width - newWidth);
    }

    if (fromBottom) {
      newHeight = (_height + d.delta.dy).clamp(
        _minHeight,
        viewport.height - _position.dy,
      );
    } else if (fromTop) {
      newHeight = (_height - d.delta.dy).clamp(
        _minHeight,
        _position.dy + _height,
      );
      newY = _position.dy + (_height - newHeight);
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
          behavior: HitTestBehavior.opaque,
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

  Future<void> _acceptInvitation() async {
    final token = widget.inviteToken;
    if (token == null || _acceptInFlight) return;
    _acceptInFlight = true;
    try {
      final vaultId =
          await Supabase.instance.client.rpc(
                'accept_vault_invitation',
                params: {'p_token': token},
              )
              as String;
      if (!mounted) return;
      GoRouter.of(context).go('/vault/$vaultId');
    } on PostgrestException catch (e) {
      _acceptInFlight = false;
      throw _humanizeInvitationError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ?? User.initial();

    // Invite-mode: kick the accept RPC on the sign-out→sign-in transition.
    if (widget.initialMode == .invite && widget.inviteToken != null) {
      ref.listen<AsyncValue<User>>(currentUserProvider, (prev, next) {
        final wasLogged = prev?.value?.isLogged ?? false;
        final nowLogged = next.value?.isLogged ?? false;
        if (!wasLogged && nowLogged) _acceptInvitation();
      });
    }

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
                  child: ClipRRect(
                    borderRadius: .circular(8),
                    child: _buildShell(context, user),
                  ),
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

  Widget _buildShell(BuildContext context, User user) {
    final screen = _buildScreen(context, user);
    final showBackButton = _mode != LandingMode.signIn;
    if (!showBackButton) return screen;

    return Stack(
      children: [
        Positioned.fill(child: screen),
        LandingBackButton(onPressed: () => _setMode(LandingMode.signIn)),
      ],
    );
  }

  Widget _buildScreen(BuildContext context, User user) {
    switch (_mode) {
      case LandingMode.invite:
        return InviteView(vaultFuture: _inviteVaultFuture);
      case LandingMode.resetPassword:
        return const ResetPasswordView();
      case LandingMode.createAccount:
        return CreateAccountView(onNavigate: _setMode);
      case LandingMode.forgotPassword:
        return ForgotPasswordView(onNavigate: _setMode);
      case LandingMode.checkInbox:
        return const InfoMessageView(
          title: 'Check your inbox',
          message:
              'Check your inbox to confirm your email, then return here to sign in.',
        );
      case LandingMode.resetSent:
        return const InfoMessageView(
          title: 'Reset link sent',
          message:
              'If an account exists for that email, a reset link is on its way.',
        );
      case LandingMode.signIn:
        if (!user.isLogged) return PreAuthView(onNavigate: _setMode);
        return const VaultsView();
    }
  }
}

Exception _humanizeInvitationError(PostgrestException e) {
  final msg = e.message;
  if (msg.contains('invitation_not_found')) {
    return Exception(
      'This invitation has already been used or does not exist.',
    );
  }
  if (msg.contains('invitation_expired')) {
    return Exception(
      'This invitation has expired. Ask the vault owner for a new one.',
    );
  }
  if (msg.contains('invitation_email_mismatch')) {
    return Exception(
      'This invitation was sent to a different email than the one you signed in with.',
    );
  }
  if (msg.contains('unauthenticated')) {
    return Exception('You need to be signed in to accept an invitation.');
  }
  return Exception('Could not accept invitation: $msg');
}
