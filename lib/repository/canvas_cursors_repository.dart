import 'package:onyxia/export.dart';

/// Cursor presence for collaborative canvas editing. Backed by a Supabase
/// Realtime broadcast channel — cursors are NOT persisted to a database table.
/// Phase B intentionally omits a `canvas_cursors` table because cursor
/// movements fire too often to write-through Postgres.
class CanvasCursorsRepository {
  final String projectId;
  final String canvasId;
  RealtimeChannel? _channel;

  /// Broadcast doesn't echo a sender's own messages back to them, so this is
  /// always false. Kept for compatibility with consumers that read it.
  final bool isLocalUpdate = false;

  CanvasCursorsRepository({
    required this.projectId,
    required this.canvasId,
  });

  String get _channelName => 'cursors:$projectId:$canvasId';

  RealtimeChannel _getOrCreateChannel() {
    return _channel ??= Supabase.instance.client.channel(_channelName);
  }

  /// Stream of other users' cursors (excludes the current user).
  Stream<List<UserCursor>> getCursorsStream(
    String currentUserId, [
    String? currentUserEmail,
  ]) {
    final channel = _getOrCreateChannel();
    final controller = StreamController<List<UserCursor>>.broadcast();
    final cursors = <String, UserCursor>{};

    channel.onBroadcast(
      event: 'cursor',
      callback: (payload) {
        try {
          final cursor = UserCursor.fromMap(Map<String, dynamic>.from(payload));
          if (cursor.userId == currentUserId) return;
          cursors[cursor.userId] = cursor;
          controller.add(cursors.values.toList());
        } catch (e) {
          debugPrint('Error decoding cursor broadcast: $e');
        }
      },
    );
    channel.onBroadcast(
      event: 'cursor-remove',
      callback: (payload) {
        final userId = payload['userId'] as String?;
        if (userId == null) return;
        if (cursors.remove(userId) != null) {
          controller.add(cursors.values.toList());
        }
      },
    );
    channel.subscribe();

    controller.onCancel = () async {
      await Supabase.instance.client.removeChannel(channel);
      _channel = null;
    };
    return controller.stream;
  }

  /// Broadcast this user's cursor position. Signature matches the legacy
  /// repository's `add(item)` so callers don't change.
  Future<void> add(UserCursor cursor, {bool suppressStream = true}) async {
    final channel = _getOrCreateChannel();
    channel.subscribe();
    await channel.sendBroadcastMessage(event: 'cursor', payload: cursor.toMap());
  }

  /// Broadcast a "remove this cursor" event. Other clients drop the entry on
  /// receipt. Signature matches the legacy `delete(id)` so callers don't change.
  Future<void> delete(dynamic item) async {
    final String userId = item is String ? item : (item as UserCursor).userId;
    final channel = _getOrCreateChannel();
    channel.subscribe();
    await channel.sendBroadcastMessage(event: 'cursor-remove', payload: {'userId': userId});
  }
}
