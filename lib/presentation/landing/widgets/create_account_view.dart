import 'package:onyxia/export.dart';

class CreateAccountView extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const CreateAccountView({super.key, required this.onNavigate});

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
  // TODO: check if the email here is validated the same way as in EmailValidationService. use EmailValidationService to keep things consistent and also use a speech balloon here to show errors. potentially do the same for the email auth form widget
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address.';
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
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
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) widget.onNavigate(.checkInbox);
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
        padding: .symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 320,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  'Create account',
                  textAlign: .center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: .w600,
                    color: ThemeHelper.foreground1(),
                  ),
                ),
                const Gap(20),
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
                  autofillHints: const [AutofillHints.newPassword],
                  hintText: 'Password',
                  fontSize: 13,
                  onSubmitted: (_) => _submit(),
                ),
                const Gap(8),
                OnyxiaTextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  hintText: 'Confirm password',
                  fontSize: 13,
                  onSubmitted: (_) => _submit(),
                ),
                if (_errorMessage != null) ...[
                  const Gap(8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 12, color: ThemeHelper.error()),
                  ),
                ],
                const Gap(16),
                Center(
                  child: OnyxiaButton(
                    label: 'Create account',
                    onPressed: _isSubmitting ? null : _submit,
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
