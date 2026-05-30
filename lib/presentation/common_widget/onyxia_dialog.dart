import 'package:onyxia/export.dart';

class OnyxiaDialog extends ConsumerStatefulWidget {
  final String? title;
  final Widget? content;
  final double? width;
  final double? height;

  const OnyxiaDialog({
    super.key,
    this.title,
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
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: ThemeHelper.background1(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ThemeHelper.background2(), width: 2),
        ),
        child: Material(
          color: ThemeHelper.background1(),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: widget.width,
            height: widget.height,
            constraints: const BoxConstraints(minWidth: 300),
            color: ThemeHelper.background1(),
            child: Column(
              spacing: 20,
              children: [
                // Header
                if (widget.title != null)
                  Container(
                    padding: .fromLTRB(20, 20, 20, 0),
                    decoration: BoxDecoration(
                      color: ThemeHelper.background1(),
                      borderRadius: .only(
                        topLeft: .circular(20),
                        topRight: .circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: .w400,
                            color: ThemeHelper.foreground1(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      widget.content != null
                          ? widget.content!
                          : const SizedBox(),
                    ],
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
