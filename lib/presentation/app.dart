import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

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
    // Watched so MaterialApp rebuilds and ColorScheme.fromSeed recomputes
    // when the user toggles themes — ColorRef swaps alone don't refresh
    // Material's seeded color scheme.
    ref.watch(themeProvider);

    return Themed(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Onyxia',
        routeInformationParser: routerInstance.routeInformationParser,
        routerDelegate: routerInstance.routerDelegate,
        routeInformationProvider: routerInstance.routeInformationProvider,
        theme: _buildTheme(),
        builder: (context, child) =>
            Portal(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  // TODO: walk through all of this. do i even need "MaterialApp"? do i need any of these values if i'm overriding a lot of them? which ones don't i override?
  ThemeData _buildTheme() {
    return ThemeData(
      fontFamily: 'Inter',
      // what is this for? do i use it anywhere?
      colorScheme: ColorScheme.fromSeed(seedColor: ThemeHelper.accent()),
      // do i actually use any of these?
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
      // does this ever get used? i'm unsure
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
      // i use onyxiatextformfield; do i need this at all?
      inputDecorationTheme: InputDecorationTheme(
        fillColor: ThemeHelper.auxiliary(),
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeHelper.auxiliary()),
        ),
      ),
      // i use my own onyxiatooltip
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration(milliseconds: 800),
        decoration: BoxDecoration(
          color: ThemeHelper.foreground1(),
          borderRadius: .circular(4),
        ),
      ),
      // i don't think i use popup menus at all?
      popupMenuTheme: PopupMenuThemeData(color: ThemeHelper.foreground1()),
      // is there a simpler way of doing this?
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _NoTransitionBuilder(),
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
