import 'package:onyxia/export.dart';

class InfoMessageView extends StatelessWidget {
  final String title;
  final String message;

  const InfoMessageView({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: .symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Text(
                title,
                textAlign: .center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: .w600,
                  color: ThemeHelper.neutral200(),
                ),
              ),
              Text(
                message,
                textAlign: .center,
                style: TextStyle(fontSize: 13, color: ThemeHelper.neutral300()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
