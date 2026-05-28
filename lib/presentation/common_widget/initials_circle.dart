import 'package:onyxia/export.dart';

// TODO: consider assigning people a random avatar (maybe let them switch it out, maybe not) from flutter_boring_avatars it's nice because there's no stupid image management that needs to happen

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
        shape: .circle,
        color: ThemeHelper.accentColor(),
      ),
      child: Center(
        child: Text(
          name.trim().isEmpty
              ? '?'
              : name
                    .trim()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((p) => p[0].toUpperCase())
                    .join(),
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: .w500,
            color: ThemeHelper.neutral900(context),
          ),
        ),
      ),
    );
  }
}
