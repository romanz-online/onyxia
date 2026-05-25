import 'package:onyxia/export.dart';

class CreateAccountView extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const CreateAccountView({super.key, required this.onNavigate});

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
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
      await ref.read(currentUserProvider.notifier).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) widget.onNavigate(LandingMode.checkInbox);
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
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create account',
                  textAlign: TextAlign.center,
                  style: NarwhalTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral800(context),
                  ),
                ),
                const Gap(20),
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
                const Gap(8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: NarwhalModalInputDecoration.create(
                    context,
                    hintText: 'Password',
                  ),
                  style: NarwhalTextStyle(fontSize: 13),
                  onSubmitted: (_) => _submit(),
                ),
                const Gap(8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: NarwhalModalInputDecoration.create(
                    context,
                    hintText: 'Confirm password',
                  ),
                  style: NarwhalTextStyle(fontSize: 13),
                  onSubmitted: (_) => _submit(),
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
                    label: _isSubmitting ? '...' : 'Create account',
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
