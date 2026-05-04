import 'package:onyxia/export.dart';

class NarwhalSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NarwhalSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      mouseCursor: onChanged != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Opacity(
        opacity: onChanged != null ? 1.0 : 0.4,
        child: Container(
          width: 60,
          height: 32,
          padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
          decoration: BoxDecoration(
            color: value ? ThemeHelper.blue500(context) : ThemeHelper.neutral200(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      value ? 'ON' : 'OFF',
                      style: NarwhalTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: value ? ThemeHelper.white(context) : ThemeHelper.neutral500(context),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ThemeHelper.neutral100(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: ThemeHelper.neutral200(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
