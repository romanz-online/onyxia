import 'package:onyxia/export.dart';

/// Shown when a user follows an invite link (`?invite=true` in the URL).
/// Welcomes them, waits for Google sign-in, then navigates to [destinationPath]
/// once their account is active (pending flag cleared by reconciliation).
class InviteScreen extends ConsumerStatefulWidget {
  final String destinationPath;

  const InviteScreen({super.key, required this.destinationPath});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Future<Project?>? _projectFuture;

  String? _extractProjectId(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'project') {
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
    final projectId = _extractProjectId(widget.destinationPath);
    if (projectId != null) {
      _projectFuture = ProjectsRepository().get(projectId);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          NarwhalIcon(
                            NarwhalIcons.narwhalLogo,
                            size: 56,
                            safeMode: true,
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
                              FutureBuilder<Project?>(
                                future: _projectFuture,
                                builder: (context, snapshot) {
                                  final projectName = snapshot.data?.name;
                                  final titleText = projectName != null
                                      ? "You've been invited to $projectName"
                                      : "You've been invited to a project on Narwhal";
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
                                'Sign in with your Google account to join the project. '
                                'You can fill in your profile details once you\'re in.',
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
