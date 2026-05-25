import 'package:onyxia/export.dart';

class ImportProgressView extends StatelessWidget {
  final int done;
  final int total;

  const ImportProgressView({
    super.key,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? null : done / total;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text(
          'Importing $done / $total files',
          style: NarwhalTextStyle(
            fontSize: 14,
            color: ThemeHelper.neutral700(context),
          ),
        ),
        LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: ThemeHelper.neutral200(context),
          valueColor: AlwaysStoppedAnimation<Color>(
            ThemeHelper.blue500(context),
          ),
        ),
        Text(
          "Please don't close this window until the import is complete.",
          style: NarwhalTextStyle(
            fontSize: 12,
            color: ThemeHelper.neutral500(context),
          ),
        ),
      ],
    );
  }
}
