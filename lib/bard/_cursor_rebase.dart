import 'package:flutter/material.dart';

/// Rebases a [TextSelection] across an external text change.
///
/// For each selection endpoint, finds the longest unchanged anchor of
/// characters adjacent to the cursor (backward first, then forward) that
/// also appears in [newText], and uses that anchor's new position to
/// compute the rebased offset. Handles single-region edits *and*
/// multi-region edits (where text changes on both sides of the cursor)
/// without collapsing the cursor onto the boundary of an edit.
///
/// Anchor search is bounded by [_maxAnchor] characters in each direction,
/// keeping the cost predictable for interactive use.
TextSelection rebaseSelection({
  required String oldText,
  required String newText,
  required TextSelection oldSelection,
}) {
  if (oldText == newText) return oldSelection;
  if (!oldSelection.isValid) return oldSelection;

  int rebase(int p) => _rebasePosition(oldText, newText, p);

  return TextSelection(
    baseOffset: rebase(oldSelection.baseOffset),
    extentOffset: rebase(oldSelection.extentOffset),
    affinity: oldSelection.affinity,
    isDirectional: oldSelection.isDirectional,
  );
}

const int _maxAnchor = 32;

int _rebasePosition(String oldText, String newText, int oldPos) {
  if (oldPos <= 0) return 0;
  if (oldPos >= oldText.length) return newText.length;

  // Backward anchor: longest run of chars immediately before the cursor that
  // appears in newText. Use its position to place the new cursor right after.
  final backMax = oldPos < _maxAnchor ? oldPos : _maxAnchor;
  for (int k = backMax; k > 0; k--) {
    final anchor = oldText.substring(oldPos - k, oldPos);
    final at = newText.indexOf(anchor);
    if (at != -1) return at + k;
  }

  // Forward anchor: longest run of chars immediately after the cursor that
  // appears in newText. Place the cursor right before that run.
  final fwdMax = (oldText.length - oldPos) < _maxAnchor
      ? (oldText.length - oldPos)
      : _maxAnchor;
  for (int k = fwdMax; k > 0; k--) {
    final anchor = oldText.substring(oldPos, oldPos + k);
    final at = newText.indexOf(anchor);
    if (at != -1) return at;
  }

  // No anchor matched in either direction — clamp to newText length.
  return oldPos.clamp(0, newText.length);
}
