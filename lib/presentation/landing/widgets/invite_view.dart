import 'package:onyxia/export.dart';

class InviteView extends ConsumerWidget {
  final Future<Vault?>? vaultFuture;

  const InviteView({super.key, required this.vaultFuture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'Onyxia',
              style: NarwhalTextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.neutral700(context),
              ),
            ),
            FutureBuilder<Vault?>(
              future: vaultFuture,
              builder: (context, snapshot) {
                final vaultName = snapshot.data?.name;
                final titleText = vaultName != null
                    ? "You've been invited to $vaultName"
                    : "You've been invited to a vault.";
                return Text(
                  titleText,
                  style: NarwhalTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral800(context),
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            Text(
              'Invitations expire 14 days after being sent.',
              style: NarwhalTextStyle(
                fontSize: 13,
                color: ThemeHelper.neutral600(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
