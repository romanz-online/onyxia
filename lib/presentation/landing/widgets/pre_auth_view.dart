import 'package:onyxia/export.dart';

class PreAuthView extends StatelessWidget {
  final void Function(LandingMode) onNavigate;

  const PreAuthView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Text(
              'Onyxia',
              style: NarwhalTextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.neutral700(context),
              ),
            ),
            SizedBox(
              width: 320,
              child: AutofillGroup(
                child: EmailAuthForm(onNavigate: onNavigate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
