import 'package:onyxia/export.dart';

class _PendingActionBar extends StatelessWidget {
  final String label;
  final List<Widget> actions;

  const _PendingActionBar({required this.label, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ThemeHelper.neutral100(context),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.neutral900(context).withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
            border:
                Border.all(color: ThemeHelper.neutral200(context), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                label,
                style: NarwhalTextStyle(
                  fontSize: 14,
                  color: ThemeHelper.black(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class NotifyChangesBar extends StatelessWidget {
  final VoidCallback onNotify;
  final VoidCallback onCancel;

  const NotifyChangesBar(
      {super.key, required this.onNotify, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return _PendingActionBar(
      label: 'Notify users of your changes?',
      actions: [
        OnyxiaButton(label: 'Cancel', onTap: onCancel),
        OnyxiaButton(label: 'Notify', onTap: onNotify),
      ],
    );
  }
}

class SaveChangesBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const SaveChangesBar({
    super.key,
    required this.isSaving,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return _PendingActionBar(
      label: 'You\'ve made changes.',
      actions: [
        OnyxiaButton(label: 'Reset', onTap: onReset),
        OnyxiaButton(label: 'Save', onTap: onSave),
      ],
    );
  }
}
