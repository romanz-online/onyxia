import 'package:onyxia/export.dart';

/// Shown when a user follows an invite link.
///
/// Two entry modes:
/// 1. Legacy `?invite=true` on a vault URL — router redirects here with a
///    `?dest=…` query and the screen waits for sign-in; the router redirects
///    out once they're signed in (handled in router.dart, not here).
/// 2. Token-based invite (`/invite?token=<uuid>`) — the screen calls
///    `accept_vault_invitation` once they're signed in and navigates to the
///    vault returned by the RPC.
class InviteScreen extends ConsumerStatefulWidget {
  final String destinationPath;
  final String? token;

  // TODO: this should not be its own screen, it should just be a different piece of content for the main landing page
  // TODO: integrate this into LandingOverlay

  const InviteScreen({
    super.key,
    required this.destinationPath,
    this.token,
  });

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Future<Vault?>? _vaultFuture;
  bool _acceptInFlight = false;

  String? _extractVaultId(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'vault') {
      return segments[1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
    final vaultId = _extractVaultId(widget.destinationPath);
    if (vaultId != null) {
      _vaultFuture = VaultsRepository().get(vaultId);
    }
    // Already-signed-in case: if the user opens a token link while authed,
    // ref.listen below won't fire (no state transition), so kick off the RPC
    // here after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.token == null) return;
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.isLogged) _acceptInvitation(widget.token!);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvitation(String token) async {
    if (_acceptInFlight) return;
    _acceptInFlight = true;
    final vaultId = await Supabase.instance.client
        .rpc('accept_vault_invitation', params: {'p_token': token}) as String;
    if (!mounted) return;
    GoRouter.of(context).go('/vault/$vaultId');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token != null) {
      ref.listen<AsyncValue<User>>(currentUserProvider, (prev, next) {
        final wasLogged = prev?.value?.isLogged ?? false;
        final nowLogged = next.value?.isLogged ?? false;
        if (!wasLogged && nowLogged) _acceptInvitation(widget.token!);
      });
    }
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 540,
                decoration: BoxDecoration(
                  color: ThemeHelper.neutral100(context),
                  border: Border.all(
                    color: ThemeHelper.neutral400(context),
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.neutral900(context)
                          .withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(10, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 52,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.waves,
                            size: 56,
                          ),
                          Text(
                            ' Narwhal',
                            style: NarwhalTextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Gap(28),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: ThemeHelper.neutral300(context),
                            ),
                            bottom: BorderSide(
                              color: ThemeHelper.neutral300(context),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              FutureBuilder<Vault?>(
                                future: _vaultFuture,
                                builder: (context, snapshot) {
                                  final vaultNme = snapshot.data?.name;
                                  final titleText = vaultNme != null
                                      ? "You've been invited to $vaultNme"
                                      : "You've been invited to a vault.";
                                  return Text(
                                    titleText,
                                    style: NarwhalTextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeHelper.neutral800(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                              const Gap(12),
                              Text(
                                'Sign in with your Google account to join the vault. ',
                                style: NarwhalTextStyle(
                                  fontSize: 14,
                                  color: ThemeHelper.neutral600(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // TODO: generally redo this screen to fit with the rest of the app as it is now
                      const Gap(32),
                      OnyxiaButton(
                        label: 'Sign in with Google',
                        onTap: ref
                            .read(currentUserProvider.notifier)
                            .signInWithGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
