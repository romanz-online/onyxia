import 'dart:async';
import 'dart:convert';

import 'package:onyxia/export.dart';

/// Opens ephemeral live-sync sessions for note CRDT ops over Supabase Realtime
/// Broadcast. Ops are never persisted — `body.content` (on the `artifacts`
/// table) is the canonical source of truth. This replaces the persisted-op
/// transport that used to live in `ArtifactOpsRepository`.
class NoteBroadcastRepository {
  NoteBroadcastRepository({required this.vaultId});

  final String? vaultId;

  /// Opens a live session for [artifactId]. Caller owns the returned session
  /// and must [NoteBroadcastSession.dispose] it when the editor closes.
  NoteBroadcastSession openSession(String artifactId) {
    if (vaultId == null || vaultId!.isEmpty) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }
    return NoteBroadcastSession._(vaultId!, artifactId);
  }
}

/// A single live broadcast session for one note. Inbound ops and outbound
/// broadcasts share ONE subscribed channel (topic `note:{vaultId}:{artifactId}`).
///
/// [inboundOps] is a single-subscription stream that buffers events arriving
/// before the CRDT engine attaches its listener, so no op is dropped in the
/// window between channel join and engine construction.
class NoteBroadcastSession {
  NoteBroadcastSession._(String vaultId, this.artifactId)
    : _channel = Supabase.instance.client.channel(
        'note:$vaultId:$artifactId',
        // self:false — never receive our own broadcasts. private:true —
        // access is gated by the realtime.messages RLS policy scoped to vault
        // membership (the vaultId in the topic is what that policy checks).
        opts: const RealtimeChannelConfig(self: false, private: true),
      ) {
    _channel
      ..onBroadcast(
        event: _opEvent,
        callback: (payload) {
          // Broadcast deliveries wrap the sent map under a 'payload' key.
          final data = payload['payload'];
          final encoded = data is Map ? data['op'] as String? : null;
          if (encoded == null) return;
          _inbound.add(base64Decode(encoded));
        },
      )
      ..subscribe();
  }

  static const _opEvent = 'op';

  final String artifactId;
  final RealtimeChannel _channel;
  final StreamController<Uint8List> _inbound = StreamController<Uint8List>();

  /// Inbound op bytes from connected peers (single-subscription, buffered).
  Stream<Uint8List> get inboundOps => _inbound.stream;

  /// Broadcasts a local CRDT op to connected peers. Fire-and-forget; the
  /// channel must be subscribed first (it is, from the constructor) or the
  /// client silently falls back to REST.
  void broadcastOp(Uint8List opBytes) {
    _channel.sendBroadcastMessage(
      event: _opEvent,
      payload: {'op': base64Encode(opBytes)},
    );
  }

  Future<void> dispose() async {
    await _inbound.close();
    await Supabase.instance.client.removeChannel(_channel);
  }
}
