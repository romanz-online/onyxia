import 'package:onyxia/export.dart';

class LandingBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LandingBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: OnyxiaIconButton(
        icon: LucideIcons.arrowLeft,
        onPressed: onPressed,
        tooltip: 'Back',
      ),
    );
  }
}
