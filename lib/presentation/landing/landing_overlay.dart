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
  static const double _width = 600;
  static const double _height = 400;

  Offset _position = const Offset(100, 100);
  bool _positionInitialized = false;

  late LandingMode _mode;

  // Invite-mode state.
  Future<Vault?>? _inviteVaultFuture;
  bool _acceptInFlight = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _positionInitialized) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        _position = Offset(
          (size.width - _width) / 2,
          (size.height - _height) / 2,
        );
        _positionInitialized = true;
      });
    });

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

    // TODO: this widget should be resizeable

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        behavior: .opaque,
        onPanUpdate: _onPanUpdate,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral900(),
            borderRadius: .circular(8),
            border: .all(color: ThemeHelper.neutral700(), width: 2),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.neutral100().withValues(alpha: 0.15),
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
