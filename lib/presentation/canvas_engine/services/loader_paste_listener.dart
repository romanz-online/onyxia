// Web implementation for paste listener
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'clipboard_service.dart';

/// Web paste listener handle type
typedef PasteListenerHandle = JSFunction;

/// Setup paste listener for web platform
PasteListenerHandle? setupPasteListenerImpl(
  WidgetRef ref,
  BuildContext context,
) {
  final listener = ((web.Event event) {
    CanvasClipboardService().handleJsPaste(event, ref, context);
  }).toJS;

  web.window.addEventListener('paste', listener);
  return listener;
}

/// Remove paste listener for web platform
void removePasteListenerImpl(PasteListenerHandle? listener) {
  if (listener != null) {
    web.window.removeEventListener('paste', listener);
  }
}
