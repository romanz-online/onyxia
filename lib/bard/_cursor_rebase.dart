import 'package:flutter/material.dart';

/// Rebases a [TextSelection] across an external text change.
///
/// Computes the change region as the common-prefix / common-suffix split
/// between [oldText] and [newText], then shifts each selection endpoint:
/// - Endpoints at or before the change region: unchanged.
/// - Endpoints at or past the change region: shifted by `insertedLen - removedLen`.
/// - Endpoints inside the change region: collapsed to the region start.
///
/// This handles single-region inserts, deletes, and replacements correctly.
/// Multi-region updates collapse into one super-region — cursor placement is
/// slightly suboptimal but never broken.
TextSelection rebaseSelection({
  required String oldText,
  required String newText,
  required TextSelection oldSelection,
}) {
  if (oldText == newText) return oldSelection;
  if (!oldSelection.isValid) return oldSelection;

  final shorter =
      oldText.length < newText.length ? oldText.length : newText.length;

  // Common prefix.
  int prefix = 0;
  while (prefix < shorter &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }

  // Common suffix, bounded so it can't overlap the prefix on the shorter side.
  int suffix = 0;
  while (suffix < shorter - prefix &&
      oldText.codeUnitAt(oldText.length - 1 - suffix) ==
          newText.codeUnitAt(newText.length - 1 - suffix)) {
    suffix++;
  }

  final removedLen = oldText.length - suffix - prefix;
  final insertedLen = newText.length - suffix - prefix;
  final delta = insertedLen - removedLen;
  final regionEnd = oldText.length - suffix;

  int rebase(int p) {
    if (p <= prefix) return p;
    if (p >= regionEnd) return p + delta;
    return prefix;
  }

  return TextSelection(
    baseOffset: rebase(oldSelection.baseOffset),
    extentOffset: rebase(oldSelection.extentOffset),
    affinity: oldSelection.affinity,
    isDirectional: oldSelection.isDirectional,
  );
}
