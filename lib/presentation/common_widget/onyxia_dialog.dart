import 'package:onyxia/export.dart';

class OnyxiaDialog extends ConsumerStatefulWidget {
  final String title;
  final Widget? content;
  final double? width;
  final double? height;

  const OnyxiaDialog({
    super.key,
    required this.title,
    this.content,
    this.width = 500.0,
    this.height = 300.0,
  });

  @override
  ConsumerState<OnyxiaDialog> createState() => _OnyxiaDialogState();
}

class _OnyxiaDialogState extends ConsumerState<OnyxiaDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4,
      // TODO: there is a white fringe along the outer pixel edge of the dialog.
      // TODO: cont. Clip.antiAliasWithSaveLayer has helped with it a bit but it's still noticeable and ugly.
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      // TODO: i want to do this:
      /// This requires the 'dot-shorthands' language feature to be enabled.
      /// Try updating your pubspec.yaml to set the minimum SDK constraint to 3.10.0 or higher, and running 'pub get'.
      child: Container(
        width: widget.width,
        height: widget.height,
        constraints: const BoxConstraints(minWidth: 300),
        color: ThemeHelper.neutral100(context),
        child: Column(
          spacing: 20,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: ThemeHelper.neutral100(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: NarwhalTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: ThemeHelper.neutral800(context),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.content != null ? widget.content! : const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
