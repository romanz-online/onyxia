import 'package:onyxia/export.dart';

class EmailAuthForm extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const EmailAuthForm({super.key, required this.onNavigate});

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address.';
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
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
        OnyxiaTextFormField(
          controller: _emailController,
          keyboardType: .emailAddress,
          autofillHints: const [AutofillHints.email],
          hintText: 'Email',
          fontSize: 13,
          onSubmitted: (_) => _submit(),
        ),
        const Gap(8),
        OnyxiaTextFormField(
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          hintText: 'Password',
          fontSize: 13,
          onSubmitted: (_) => _submit(),
        ),
        if (_errorMessage != null) ...[
          const Gap(8),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 12, color: ThemeHelper.errorColor()),
          ),
        ],
        const Gap(12),
        Center(
          child: OnyxiaButton(
            label: 'Sign in',
            onTap: _isSubmitting ? null : _submit,
          ),
        ),
        const Gap(8),
        Row(
          mainAxisAlignment: .center,
          spacing: 8,
          children: [
            OnyxiaButton(
              label: 'Create an account',
              onTap: () => widget.onNavigate(.createAccount),
            ),
            OnyxiaButton(
              label: 'Forgot password?',
              onTap: () => widget.onNavigate(.forgotPassword),
            ),
          ],
        ),
      ],
    );
  }
}
