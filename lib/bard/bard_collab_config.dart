import 'dart:typed_data';

/// Network plumbing for a single collaborative BardEditor session.
///
/// The host (e.g. a Riverpod provider backed by Supabase) constructs this and
/// passes it to [BardEditor]. The editor reconstructs a CRDT internally from
/// [initialSnapshot] + [initialOps], emits each local op via [onLocalOp], and
/// applies inbound ops from [remoteOps].
///
/// All bytes are opaque to the host — the host never decodes them. The wire
/// format is a base64-encoded JSON object per op or snapshot.
class BardCollabConfig {
  /// Latest snapshot bytes for this document, or null if no snapshot exists yet.
  final Uint8List? initialSnapshot;

  /// All ops newer than [initialSnapshot]'s version vector. Applied in order on
  /// editor construction.
  final List<Uint8List> initialOps;

  /// Continuous inbound op stream. Each event is the bytes of one CRDT change
  /// — applies idempotently (own echoes are detected by op id and become
  /// no-ops at the CRDT level).
  final Stream<Uint8List> remoteOps;

  /// Called when the local editor produces a CRDT op. Host is responsible for
  /// forwarding to the network (e.g. inserting a row into artifact_ops).
  final void Function(Uint8List opBytes) onLocalOp;

  const BardCollabConfig({
    required this.initialSnapshot,
    required this.initialOps,
    required this.remoteOps,
    required this.onLocalOp,
  });
}
