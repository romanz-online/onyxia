import 'package:onyxia/export.dart';

class EmailAuthForm extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const EmailAuthForm({super.key, required this.onNavigate});

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final OnyxiaValidatorController _emailBalloon = OnyxiaValidatorController(
    validator: EmailValidationService.validate,
  );
  final OnyxiaValidatorController _passwordBalloon = OnyxiaValidatorController(
    validator: (v) =>
        v.length < 6 ? 'Password must be at least 6 characters.' : null,
  );

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailBalloon.dispose();
    _passwordBalloon.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_emailBalloon.validate(_emailController.text.trim())) {
      _emailFocus.requestFocus();
      return;
    }
    if (!_passwordBalloon.validate(_passwordController.text)) {
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(currentUserProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (e) {
      if (mounted) _emailBalloon.showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        OnyxiaValidator(
          controller: _emailBalloon,
          child: OnyxiaTextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: .emailAddress,
            autofillHints: const [AutofillHints.email],
            hintText: 'Email',
            fontSize: 13,
            onChanged: (_) => _emailBalloon.clear(),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const Gap(8),
        OnyxiaValidator(
          controller: _passwordBalloon,
          child: OnyxiaTextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            hintText: 'Password',
            fontSize: 13,
            onChanged: (_) => _passwordBalloon.clear(),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const Gap(12),
        Center(
          child: OnyxiaButton(
            label: 'Sign in',
            onPressed: _isSubmitting ? null : _submit,
          ),
        ),
        const Gap(8),
        Row(
          mainAxisAlignment: .center,
          spacing: 8,
          children: [
            OnyxiaButton(
              label: 'Create an account',
              onPressed: () => widget.onNavigate(.createAccount),
            ),
            OnyxiaButton(
              label: 'Forgot password?',
              onPressed: () => widget.onNavigate(.forgotPassword),
            ),
          ],
        ),
      ],
    );
  }
}
