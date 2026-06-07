import 'dart:typed_data';

/// Network plumbing for a single collaborative BardEditor session.
///
/// The host (e.g. a Riverpod provider backed by Supabase) constructs this and
/// passes it to [BardEditor]. The editor seeds an in-memory CRDT from
/// [initialContent] (the canonical `body.content`), emits each local op via
/// [onLocalOp], applies inbound ops from [remoteOps], and reconciles whole-text
/// updates from [externalContent].
///
/// Op bytes are opaque to the host — the host never decodes them. The wire
/// format is a base64-encoded JSON object per op. CRDT ops are an *ephemeral*
/// live-sync transport only: they are broadcast, never persisted. The canonical
/// source of truth is `body.content`, which the host writes back as the editor
/// converges.
class BardCollabConfig {
  /// The note's canonical text (`body.content`) at session open. The editor
  /// deterministically seeds its CRDT from this so peers opening the same
  /// content converge without a shared persisted snapshot.
  final String initialContent;

  /// Continuous inbound op stream (one CRDT change per event). Applies
  /// idempotently — own echoes are detected by op id and become no-ops at the
  /// CRDT level.
  final Stream<Uint8List> remoteOps;

  /// Called when the local editor produces a CRDT op. Host forwards it to the
  /// network (e.g. a Supabase Realtime broadcast).
  final void Function(Uint8List opBytes) onLocalOp;

  /// Whole-text reconciliation stream. The host pushes a fresh `body.content`
  /// here when it observes a remote change that may not have arrived as live
  /// ops (e.g. an edit from a client that has since disconnected, or a wiki-link
  /// rename). The editor merges it into the CRDT via a Myers diff, which also
  /// re-broadcasts the delta to any connected peers. Null disables the backstop.
  final Stream<String>? externalContent;

  const BardCollabConfig({
    required this.initialContent,
    required this.remoteOps,
    required this.onLocalOp,
    this.externalContent,
  });
}
