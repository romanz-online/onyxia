import 'package:onyxia/export.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  final void Function(LandingMode) onNavigate;

  const ForgotPasswordView({super.key, required this.onNavigate});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _emailController = TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .sendPasswordResetEmail(email);
      if (mounted) widget.onNavigate(LandingMode.resetSent);
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
                  'Reset password',
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
                    label: _isSubmitting ? '...' : 'Send reset link',
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
