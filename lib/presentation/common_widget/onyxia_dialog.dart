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
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        constraints: const BoxConstraints(
          minWidth: 300,
        ),
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(20),
        ),
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
                    style: NarwhalStyles.modalTitleStyle(context),
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
