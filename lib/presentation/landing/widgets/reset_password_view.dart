import 'package:onyxia/export.dart';

class ResetPasswordView extends ConsumerStatefulWidget {
  const ResetPasswordView({super.key});

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirmController.text) {
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 320,
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
                      decoration: NarwhalModalInputDecoration.create(
                        context,
                        hintText: 'New password',
                      ),
                      style: NarwhalTextStyle(fontSize: 13),
                    ),
                    const Gap(8),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: NarwhalModalInputDecoration.create(
                        context,
                        hintText: 'Confirm new password',
                      ),
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
    );
  }
}
