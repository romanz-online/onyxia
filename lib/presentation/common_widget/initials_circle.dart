import 'package:onyxia/export.dart';

class InitialsCircle extends StatelessWidget {
  final String name;
  final double size;

  const InitialsCircle({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ThemeHelper.accentColor(),
      ),
      child: Center(
        child: Text(
          name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join(),
          style: NarwhalTextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w500,
            color: ThemeHelper.neutral100(context),
          ),
        ),
      ),
    );
  }
}
