import 'package:onyxia/export.dart';

class InviteView extends ConsumerWidget {
  final Future<Vault?>? vaultFuture;

  const InviteView({super.key, required this.vaultFuture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: .symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            Text(
              'Onyxia',
              style: TextStyle(
                fontSize: 32,
                fontWeight: .bold,
                color: ThemeHelper.neutral300(),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: .w600,
                    color: ThemeHelper.neutral200(),
                  ),
                  textAlign: .center,
                );
              },
            ),
            Text(
              'Invitations expire 14 days after being sent.',
              style: TextStyle(fontSize: 13, color: ThemeHelper.neutral400()),
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}
