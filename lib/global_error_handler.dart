import 'package:onyxia/export.dart';

class GlobalErrorHandler {
  static String? _lastSignature;
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const _dedupeWindow = Duration(seconds: 2);

  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack, source: 'flutter');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, source: 'platform');
      return true;
    };
  }

  static void report(
    Object error,
    StackTrace? stack, {
    required String source,
  }) {
    final message = _format(error);
    final signature = '$source|$message';
    final now = DateTime.now();
    if (signature == _lastSignature &&
        now.difference(_lastAt) < _dedupeWindow) {
      return;
    }
    _lastSignature = signature;
    _lastAt = now;

    debugPrint('🔴 [$source] $error');
    if (stack != null) debugPrint(stack.toString());

    // Defer to next frame so we don't try to mount an overlay during
    // a build/layout/paint that's already failing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState?.overlay == null) return;
      OnyxiaToast.show(text: message, type: ToastType.error);
    });
  }

  static String _format(Object error) {
    final raw = error.toString();
    return raw.length > 240 ? '${raw.substring(0, 237)}...' : raw;
  }
}

final class GlobalProviderObserver extends ProviderObserver {
  const GlobalProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final name =
        context.provider.name ?? context.provider.runtimeType.toString();
    GlobalErrorHandler.report(error, stackTrace, source: 'provider:$name');
  }
}
