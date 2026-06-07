import 'dart:convert';
import 'dart:typed_data';

import 'package:crdt_lf/crdt_lf.dart';

/// Public codec for bard CRDT op serialization. Owns the wire byte format
/// (`utf8(jsonEncode(...))`) and the document handler key. CRDT ops are an
/// ephemeral live-sync transport only — the canonical source of truth is
/// `body.content` on the `artifacts` table, not any serialized CRDT state.
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
}
