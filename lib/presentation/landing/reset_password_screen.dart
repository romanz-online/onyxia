import 'package:onyxia/export.dart';

/// Lands here after the user clicks the password-recovery link in their email.
/// Supabase establishes a recovery session via the URL fragment before this
/// screen renders; we just collect a new password and call updateUser.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  // TODO: should not be its own screen. integrate this into LandingOverlay

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).updatePassword(password);
      if (!mounted) return;
      context.go(Routes.home);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral100(context),
            border: Border.all(color: ThemeHelper.neutral400(context)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.neutral900(context).withValues(alpha: 0.12),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(10, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set a new password',
                  textAlign: TextAlign.center,
                  style: NarwhalTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral800(context),
                  ),
                ),
                const Gap(20),
                AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: NarwhalModalInputDecoration.create(context,
                            hintText: 'New password'),
                        style: NarwhalTextStyle(fontSize: 13),
                      ),
                      const Gap(8),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: NarwhalModalInputDecoration.create(context,
                            hintText: 'Confirm new password'),
                        style: NarwhalTextStyle(fontSize: 13),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const Gap(8),
                  Text(
                    _errorMessage!,
                    style: NarwhalTextStyle(
                      fontSize: 12,
                      color: ThemeHelper.red600(context),
                    ),
                  ),
                ],
                const Gap(16),
                Center(
                  child: OnyxiaButton(
                    label: _isSubmitting ? '...' : 'Update password',
                    onTap: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
