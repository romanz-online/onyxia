import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

class OnyxiaApp extends ConsumerStatefulWidget {
  const OnyxiaApp({super.key});

  @override
  ConsumerState<OnyxiaApp> createState() => _OnyxiaAppState();
}

class _OnyxiaAppState extends ConsumerState<OnyxiaApp> {
  @override
  Widget build(BuildContext context) {
    final routerInstance = ref.watch(routerProvider);
    return Themed(
      // using a builder here so that the entirety of MaterialApp, including its theme (which sometimes is outside of its context) gets captured under Themed()
      child: Builder(
        builder: (context) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Onyxia',
          routeInformationParser: routerInstance.routeInformationParser,
          routerDelegate: routerInstance.routerDelegate,
          routeInformationProvider: routerInstance.routeInformationProvider,
          theme: _buildTheme(),
          builder: (context, child) =>
              Portal(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ThemeHelper.accent().withValues(alpha: 0.75),
      selectionColor: ThemeHelper.accent().withValues(alpha: 0.6),
      selectionHandleColor: ThemeHelper.accent().withValues(alpha: 0.75),
    ),
    dialogTheme: DialogThemeData(
      barrierColor: Colors.black.withValues(alpha: 0.3),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: .resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? ThemeHelper.auxiliary()
            : ThemeHelper.background2(),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const _NoTransitionBuilder(),
      },
    ),
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
