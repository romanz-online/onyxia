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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: NarwhalTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.neutral800(context),
                ),
              ),
              const Gap(16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: NarwhalTextStyle(
                  fontSize: 13,
                  color: ThemeHelper.neutral700(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
