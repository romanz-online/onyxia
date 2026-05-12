import 'package:onyxia/export.dart';

enum _AuthMode { signIn, signUp, forgotPassword, checkInbox, resetSent }

class EmailAuthForm extends ConsumerStatefulWidget {
  const EmailAuthForm({super.key});

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String? _validateInputs() {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address.';

    if (_mode == _AuthMode.forgotPassword) return null;

    final password = _passwordController.text;
    if (password.length < 6) return 'Password must be at least 6 characters.';

    if (_mode == _AuthMode.signUp &&
        _passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final notifier = ref.read(currentUserProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await notifier.signInWithEmail(email: email, password: password);
          break;
        case _AuthMode.signUp:
          await notifier.signUpWithEmail(email: email, password: password);
          if (mounted) _setMode(_AuthMode.checkInbox);
          break;
        case _AuthMode.forgotPassword:
          await notifier.sendPasswordResetEmail(email);
          if (mounted) _setMode(_AuthMode.resetSent);
          break;
        case _AuthMode.checkInbox:
        case _AuthMode.resetSent:
          break;
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _AuthMode.checkInbox || _mode == _AuthMode.resetSent) {
      return _buildInfoState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: NarwhalModalInputDecoration.create(
            context,
            hintText: 'Email',
          ),
          style: NarwhalTextStyle(fontSize: 13),
          onSubmitted: (_) => _submit(),
        ),
        if (_mode != _AuthMode.forgotPassword) ...[
          const Gap(8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: _mode == _AuthMode.signUp
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            decoration: NarwhalModalInputDecoration.create(context,
                hintText: 'Password'),
            style: NarwhalTextStyle(fontSize: 13),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (_mode == _AuthMode.signUp) ...[
          const Gap(8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: NarwhalModalInputDecoration.create(context,
                hintText: 'Confirm password'),
            style: NarwhalTextStyle(fontSize: 13),
            onSubmitted: (_) => _submit(),
          ),
        ],
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
        const Gap(12),
        Center(
          child: OnyxiaButton(
            label: _isSubmitting ? '...' : _primaryLabel(),
            onTap: _isSubmitting ? null : _submit,
          ),
        ),
        const Gap(8),
        _buildModeToggles(context),
        const Gap(12),
        _buildDivider(context),
        const Gap(12),
        Center(
          child: OnyxiaButton(
            label: 'Sign in with Google',
            onTap: ref.read(currentUserProvider.notifier).signInWithGoogle,
          ),
        ),
      ],
    );
  }

  String _primaryLabel() {
    switch (_mode) {
      case _AuthMode.signIn:
        return 'Sign in';
      case _AuthMode.signUp:
        return 'Create account';
      case _AuthMode.forgotPassword:
        return 'Send reset link';
      case _AuthMode.checkInbox:
      case _AuthMode.resetSent:
        return '';
    }
  }

  Widget _buildModeToggles(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        if (_mode == _AuthMode.signIn) ...[
          OnyxiaButton(
            label: 'Create an account',
            onTap: () => _setMode(_AuthMode.signUp),
          ),
          OnyxiaButton(
            label: 'Forgot password?',
            onTap: () => _setMode(_AuthMode.forgotPassword),
          ),
        ] else
          OnyxiaButton(
            label: 'Back to sign in',
            onTap: () => _setMode(_AuthMode.signIn),
          ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final color = ThemeHelper.neutral300(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or',
            style: NarwhalTextStyle(
              fontSize: 11,
              color: ThemeHelper.neutral500(context),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: color)),
      ],
    );
  }

  Widget _buildInfoState(BuildContext context) {
    final message = _mode == _AuthMode.checkInbox
        ? 'Check your inbox to confirm your email, then return here to sign in.'
        : 'If an account exists for that email, a reset link is on its way.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: NarwhalTextStyle(
            fontSize: 13,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        Center(
          child: OnyxiaButton(
            label: 'Back to sign in',
            onTap: () => _setMode(_AuthMode.signIn),
          ),
        ),
      ],
    );
  }
}
