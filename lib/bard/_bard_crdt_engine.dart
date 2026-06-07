import 'dart:async';
import 'dart:typed_data';

import 'package:crdt_lf/crdt_lf.dart';

import 'bard_codec.dart';
import 'bard_collab_config.dart';

/// Fixed peer id used ONLY to build the deterministic genesis seed from
/// `body.content`. crdt_lf derives each character's FugueElementID from
/// `doc.peerId` + a per-handler counter that resets to 0 on construction, so
/// seeding the same content under the same constant peer id yields a
/// byte-identical Fugue tree on every peer (ids `genesis:0..n-1`). That
/// determinism is what lets live ops merge across peers without a shared
/// persisted snapshot. The genesis change is only ever imported as a snapshot
/// (never added to the DAG and never a causal dep of a live op), so the
/// non-deterministic HLC in its version vector is inert — convergence rests
/// solely on the element ids.
const _kGenesisPeerId = '00000000-0000-4000-8000-000000000000';

/// Builds the deterministic genesis snapshot for [content]. See
/// [_kGenesisPeerId]. Constructed in-process (no JSON round-trip), so the
/// handler's typed `List<FugueValueNode<String>>` state is already correct and
/// no codec rebuild is needed.
Snapshot seedFromContent(String content) {
  final g = CRDTDocument(peerId: PeerId.parse(_kGenesisPeerId));
  if (content.isNotEmpty) {
    CRDTFugueTextHandler(g, BardCodec.handlerKey).insert(0, content);
  }
  return g.takeSnapshot(pruneHistory: false);
}

/// Owns one CRDTDocument + CRDTFugueTextHandler for the lifetime of a
/// collaborative BardEditor session.
///
/// Bridges three flows:
/// - Outbound: local insert/delete/replace calls → CRDT op → onLocalOp callback.
/// - Inbound: remoteOps stream → applyChange → updates stream.
/// - State: currentText getter + updates stream so the editor can refresh its
///   controller after remote ops.
///
/// The engine is internal to `lib/bard/`; the rest of the app should never
/// touch it directly. The public seam is [BardCollabConfig].
class BardCrdtEngine {
  final BardCollabConfig _config;
  late final CRDTDocument _doc;
  late final CRDTFugueTextHandler _text;

  late final StreamSubscription<Change> _localSub;
  late final StreamSubscription<Uint8List> _remoteSub;

  /// Ids of changes we just applied as remote, waiting for the matching
  /// async-broadcast emission on `_doc.localChanges` so we can skip
  /// re-broadcasting them as outbound ops. A boolean flag won't survive the
  /// microtask gap between `applyChange` returning and the broadcast listener
  /// firing — crdt_lf's `_localChangesController` is an async-broadcast
  /// stream, so a transient sync guard always resets too early.
  final Set<String> _recentRemoteIds = <String>{};

  /// Remote changes that arrived before one of their causal deps. Drained on
  /// every subsequent remote event — once a new dep lands in the DAG, any
  /// previously-buffered descendant becomes applicable. crdt_lf doesn't buffer
  /// internally; without this, an out-of-order arrival drops the change
  /// permanently.
  final List<Change> _pendingCausallyNotReady = <Change>[];

  /// Fires after any state mutation (local or remote). The editor listens to
  /// this to refresh the BardController text.
  Stream<void> get updates => _doc.updates;

  /// Current converged text.
  String get currentText => _text.value;

  BardCrdtEngine(this._config) {
    // Fresh per-session peer id. The CRDT's per-handler counter resets to 0
    // every construction, so reusing the same peer id across sessions causes
    // FugueElementID collisions on subsequent loads. A session-scoped UUID
    // sidesteps that — the doc gains one version-vector entry per session,
    // which compaction collapses.
    _doc = CRDTDocument(peerId: .generate());
    _text = CRDTFugueTextHandler(_doc, BardCodec.handlerKey);

    // Hydrate from body.content (the canonical source of truth) via a
    // deterministic genesis seed. The live doc keeps its own unique peer id
    // (above), so local edits never collide with a peer's. See [seedFromContent].
    _doc.importSnapshot(seedFromContent(_config.initialContent));

    // Inbound: remote op bytes → applyChange. Mark the change id BEFORE
    // applyChange runs so the (async-broadcast) localChanges echo for this
    // change can identify itself when it fires later.
    //
    // After each apply, drain the causally-pending buffer: a new dep in the
    // DAG may unblock previously-buffered descendants. Fixed-point retry
    // handles chains.
    _remoteSub = _config.remoteOps.listen((bytes) {
      _tryApply(BardCodec.decodeChange(bytes));
      while (_pendingCausallyNotReady.isNotEmpty) {
        final beforeCount = _pendingCausallyNotReady.length;
        final retries = List<Change>.from(_pendingCausallyNotReady);
        _pendingCausallyNotReady.clear();
        for (final c in retries) {
          _tryApply(c);
        }
        if (_pendingCausallyNotReady.length == beforeCount) break;
      }
    });

    // Outbound: local Change → bytes → callback. Drop echoes of changes we
    // just applied as remote.
    _localSub = _doc.localChanges.listen((change) {
      if (_recentRemoteIds.remove(change.id.toString())) return;
      _config.onLocalOp(BardCodec.encodeChange(change));
    });
  }

  /// Applies a remote [change]. On `CausallyNotReadyException`, buffers the
  /// change for retry once a later event lands its missing deps in the DAG.
  /// Maintains the `_recentRemoteIds` echo guard around every apply attempt.
  void _tryApply(Change change) {
    final idKey = change.id.toString();
    _recentRemoteIds.add(idKey);
    try {
      final applied = _doc.applyChange(change);
      // crdt_lf only emits to localChanges when applied=true. For duplicates,
      // no echo will arrive, so drop the marker now to avoid accumulating.
      if (!applied) _recentRemoteIds.remove(idKey);
    } on CausallyNotReadyException {
      // No echo will fire for a change that wasn't applied. Buffer for retry.
      _recentRemoteIds.remove(idKey);
      _pendingCausallyNotReady.add(change);
    } catch (_) {
      _recentRemoteIds.remove(idKey);
      rethrow;
    }
  }

  /// Inserts [str] at character position [pos] into the CRDT.
  void applyTypedInsert(int pos, String str) {
    if (str.isEmpty) return;
    _text.insert(pos, str);
  }

  /// Deletes [n] characters starting at [pos].
  void applyTypedDelete(int pos, int n) {
    if (n <= 0) return;
    _text.delete(pos, n);
  }

  /// Replaces [n] characters at [pos] with [str]. Batched as one CRDT
  /// transaction so the resulting changes flush together.
  void applyTypedReplace(int pos, int n, String str) {
    _doc.runInTransaction(() {
      if (n > 0) _text.delete(pos, n);
      if (str.isNotEmpty) _text.insert(pos, str);
    });
  }

  /// Fallback: derives ops via Myers diff against the current value. Use this
  /// when input doesn't decompose into a clean insert/delete/replace (paste,
  /// IME commit, autocomplete collapse, programmatic set).
  void applyFallbackChange(String newText) {
    if (newText == _text.value) return;
    _doc.runInTransaction(() {
      _text.change(newText);
    });
  }

  void dispose() {
    _localSub.cancel();
    _remoteSub.cancel();
    _doc.dispose();
  }
}
