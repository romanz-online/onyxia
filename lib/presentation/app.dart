import 'package:onyxia/export.dart';

class NarwhalApp extends ConsumerStatefulWidget {
  const NarwhalApp({super.key});

  @override
  ConsumerState<NarwhalApp> createState() => _NarwhalAppState();
}

class _NarwhalAppState extends ConsumerState<NarwhalApp> {
  GoRouter get router => ref.read(routerProvider);

  @override
  Widget build(BuildContext context) {
    final routerInstance = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Onyxia',
      routeInformationParser: routerInstance.routeInformationParser,
      routerDelegate: routerInstance.routerDelegate,
      routeInformationProvider: routerInstance.routeInformationProvider,
      theme: _buildTheme(),
      builder: (context, child) =>
          Portal(child: child ?? const SizedBox.shrink()),
    );
  }

  // TODO: i'm making my own theme. need to gut or replace a lot of this
  ThemeData _buildTheme() {
    return ThemeData(
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(seedColor: ThemeHelper.accent()),
      scaffoldBackgroundColor: ThemeHelper.background1(),
      cardColor: ThemeHelper.background1(),
      dividerColor: ThemeHelper.auxiliary(),
      canvasColor: ThemeHelper.foreground1(),
      primaryColor: ThemeHelper.accent(),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeHelper.background1(),
        foregroundColor: ThemeHelper.auxiliary(),
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeHelper.foreground1()),
      ),
      iconTheme: IconThemeData(color: ThemeHelper.foreground1()),
      textTheme:
          const TextTheme(
            // Small scale (10px)
            labelSmall: TextStyle(fontSize: 10, fontWeight: .w400),
            bodySmall: TextStyle(fontSize: 10, fontWeight: .w600),
            titleSmall: TextStyle(fontSize: 10, fontWeight: .w700),
            // Medium scale (12px)
            labelMedium: TextStyle(fontSize: 12, fontWeight: .w300),
            bodyMedium: TextStyle(fontSize: 12, fontWeight: .w400),
            titleMedium: TextStyle(fontSize: 12, fontWeight: .w600),
            headlineSmall: TextStyle(fontSize: 12, fontWeight: .w700),
            displaySmall: TextStyle(fontSize: 12, fontWeight: .w400),
            // Large scale (16px)
            labelLarge: TextStyle(fontSize: 16, fontWeight: .w300),
            bodyLarge: TextStyle(fontSize: 16, fontWeight: .w400),
          ).apply(
            bodyColor: ThemeHelper.auxiliary(),
            displayColor: ThemeHelper.auxiliary(),
          ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: ThemeHelper.auxiliary(),
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeHelper.auxiliary()),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration(milliseconds: 800),
        decoration: BoxDecoration(
          color: ThemeHelper.foreground1(),
          borderRadius: .circular(4),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(color: ThemeHelper.foreground1()),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionBuilder(),
          TargetPlatform.iOS: _NoTransitionBuilder(),
          TargetPlatform.linux: _NoTransitionBuilder(),
          TargetPlatform.macOS: _NoTransitionBuilder(),
          TargetPlatform.windows: _NoTransitionBuilder(),
          TargetPlatform.fuchsia: _NoTransitionBuilder(),
        },
      ),
    );
  }
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
