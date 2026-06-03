import 'package:onyxia/export.dart';

class CreateAccountView extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const CreateAccountView({super.key, required this.onNavigate});

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final OnyxiaValidatorController _emailValidator = OnyxiaValidatorController(
    validator: EmailValidationService.validate,
  );
  final OnyxiaValidatorController _passwordValidator =
      OnyxiaValidatorController(
        validator: (v) =>
            v.length < 6 ? 'Password must be at least 6 characters.' : null,
      );
  late final OnyxiaValidatorController _confirmValidator =
      OnyxiaValidatorController(
        validator: (v) =>
            v != _passwordController.text ? 'Passwords do not match.' : null,
      );

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailValidator.dispose();
    _passwordValidator.dispose();
    _confirmValidator.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_emailValidator.validate(_emailController.text.trim())) {
      _emailFocus.requestFocus();
      return;
    }
    if (!_passwordValidator.validate(_passwordController.text)) {
      _passwordFocus.requestFocus();
      return;
    }
    if (!_confirmValidator.validate(_confirmPasswordController.text)) {
      _confirmFocus.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(currentUserProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) widget.onNavigate(.checkInbox);
    } on AuthException catch (e) {
      if (mounted) _emailValidator.showError(e.message);
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
                OnyxiaValidator(
                  controller: _emailValidator,
                  child: OnyxiaTextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: .emailAddress,
                    autofillHints: const [AutofillHints.email],
                    hintText: 'Email',
                    fontSize: 13,
                    onChanged: (_) => _emailValidator.clear(),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const Gap(8),
                OnyxiaValidator(
                  controller: _passwordValidator,
                  child: OnyxiaTextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    hintText: 'Password',
                    fontSize: 13,
                    onChanged: (_) => _passwordValidator.clear(),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const Gap(8),
                OnyxiaValidator(
                  controller: _confirmValidator,
                  child: OnyxiaTextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmFocus,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    hintText: 'Confirm password',
                    fontSize: 13,
                    onChanged: (_) => _confirmValidator.clear(),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
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
