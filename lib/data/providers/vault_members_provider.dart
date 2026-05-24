import 'package:onyxia/export.dart';
import 'dart:async';

final vaultMembersProvider =
    StreamProvider.autoDispose<List<VaultMember>>((ref) {
  final vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));
  if (vaultId == null) return Stream.value([]);
  return VaultMembersRepository(vaultId: vaultId).getStream();
});

/// A vault member joined with their resolved user record.
typedef VaultMemberWithUser = ({VaultMember member, User user});

/// Streams the selected vault's members alongside their user records. Within
/// a vault context, every userId we care to display belongs to a member, so
/// this replaces the older global `userLookupProvider` / `UserLookupService`.
final vaultMembersWithUsersProvider = StreamNotifierProvider.autoDispose<
    VaultMembersWithUsersNotifier, List<VaultMemberWithUser>>(
  VaultMembersWithUsersNotifier.new,
);

/// O(1) userId → User lookup derived from [vaultMembersWithUsersProvider].
/// For call sites that have a userId and want to render the user — comment
/// pins, avatars, etc.
final vaultMemberUserByIdProvider =
    Provider.autoDispose<Map<String, User>>((ref) {
  final list = ref.watch(vaultMembersWithUsersProvider).value ?? const [];
  return {for (final e in list) e.member.userId: e.user};
});

class VaultMembersWithUsersNotifier
    extends StreamNotifier<List<VaultMemberWithUser>> {
  final Map<String, User> _userCache = {};
  final UsersRepository _users = UsersRepository();

  @override
  Stream<List<VaultMemberWithUser>> build() {
    final controller = StreamController<List<VaultMemberWithUser>>();
    ref.onDispose(controller.close);

    ref.listen<AsyncValue<List<VaultMember>>>(
      vaultMembersProvider,
      (_, next) {
        next.whenData((members) => _process(members, controller));
      },
      fireImmediately: true,
    );

    return controller.stream;
  }

  Future<void> _process(
    List<VaultMember> members,
    StreamController<List<VaultMemberWithUser>> out,
  ) async {
    final missing = members
        .map((m) => m.userId)
        .where((id) => id.isNotEmpty && !_userCache.containsKey(id))
        .toSet()
        .toList();
    if (missing.isNotEmpty) {
      final fetched = await _users.query(field: 'id', whereIn: missing);
      for (final u in fetched) {
        _userCache[u.id] = u;
      }
    }
    if (out.isClosed) return;
    out.add([
      for (final m in members)
        (
          member: m,
          user: _userCache[m.userId] ??
              User(id: m.userId, name: 'Unknown User', email: ''),
        ),
    ]);
  }
}
