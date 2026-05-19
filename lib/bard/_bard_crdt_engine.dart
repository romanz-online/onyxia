import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crdt_lf/crdt_lf.dart';

import 'bard_collab_config.dart';

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
  static const _handlerKey = 'content';

  final BardCollabConfig _config;
  late final CRDTDocument _doc;
  late final CRDTFugueTextHandler _text;

  late final StreamSubscription<Change> _localSub;
  late final StreamSubscription<Uint8List> _remoteSub;

  /// True while applying a remote op — guards the local-change emission to
  /// avoid loops. (CRDT already dedupes by id, but this skips a wasted encode
  /// + network round-trip.)
  bool _applyingRemote = false;

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
    _doc = CRDTDocument(peerId: PeerId.generate());
    _text = CRDTFugueTextHandler(_doc, _handlerKey);

    // Hydrate from snapshot then catch-up ops.
    final snap = _config.initialSnapshot;
    if (snap != null) {
      _doc.importSnapshot(_decodeSnapshot(snap));
    }
    if (_config.initialOps.isNotEmpty) {
      _doc.importChanges(_config.initialOps.map(_decodeChange).toList());
    }

    // Inbound: remote op bytes → applyChange.
    _remoteSub = _config.remoteOps.listen((bytes) {
      _applyingRemote = true;
      try {
        _doc.applyChange(_decodeChange(bytes));
      } finally {
        _applyingRemote = false;
      }
    });

    // Outbound: local Change → bytes → callback.
    _localSub = _doc.localChanges.listen((change) {
      if (_applyingRemote) return;
      _config.onLocalOp(_encodeChange(change));
    });
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

  /// Take a snapshot of the current state. Returns encoded bytes.
  ///
  /// Useful for clients to occasionally cache a snapshot locally; the
  /// compaction service does the canonical version.
  Uint8List takeSnapshotBytes() {
    final snap = _doc.takeSnapshot(pruneHistory: false);
    return _encodeSnapshot(snap);
  }

  void dispose() {
    _localSub.cancel();
    _remoteSub.cancel();
    _doc.dispose();
  }

  // ── Codec ─────────────────────────────────────────────────────────────────

  static Uint8List _encodeChange(Change change) {
    return Uint8List.fromList(utf8.encode(jsonEncode(change.toJson())));
  }

  static Change _decodeChange(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return Change.fromJson(json);
  }

  static Uint8List _encodeSnapshot(Snapshot snap) {
    return Uint8List.fromList(utf8.encode(jsonEncode(snap.toJson())));
  }

  static Snapshot _decodeSnapshot(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return Snapshot.fromJson(json);
  }
}
