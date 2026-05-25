import 'dart:convert';
import 'dart:typed_data';

import 'package:crdt_lf/crdt_lf.dart';

/// Public codec for bard CRDT serialization. Owns the byte format
/// (`utf8(jsonEncode(...))`) and the document handler key. Use these
/// whenever code outside `lib/bard/` needs to read or write bard data
/// (e.g. import/export flows).
class BardCodec {
  /// Key the bard CRDT uses for its single text handler inside the document.
  /// All bard documents are a `CRDTFugueTextHandler` registered under this key.
  static const handlerKey = 'content';

  static Uint8List encodeChange(Change change) =>
      Uint8List.fromList(utf8.encode(jsonEncode(change.toJson())));

  static Change decodeChange(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return Change.fromJson(json);
  }

  static Uint8List encodeSnapshot(Snapshot snap) =>
      Uint8List.fromList(utf8.encode(jsonEncode(snap.toJson())));

  static Snapshot decodeSnapshot(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final raw = Snapshot.fromJson(json);
    // crdt_lf 2.5.0's Snapshot.fromJson does only a shallow Map.from on
    // `data`, so the handler's `is List<FugueValueNode<String>>` check
    // (in _initialState) fails after a JSON round-trip and text loads empty.
    // Rebuild the typed content list here.
    final content = raw.data[handlerKey];
    if (content is List) {
      final typed = content
          .map(
            (e) => FugueValueNode<String>.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return Snapshot(
        id: raw.id,
        versionVector: raw.versionVector,
        data: {...raw.data, handlerKey: typed},
      );
    }
    return raw;
  }
}
