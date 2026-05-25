import 'package:onyxia/export.dart';
import 'package:onyxia/core/narwhal_text_theme.dart';

// TODO: fix the white loading screen while the app is loading. it should be dark.

// TODO: redo or get rid of narwhal branding in the loading screens

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
      themeMode: ThemeMode.dark,
      builder: (context, child) =>
          Portal(child: child ?? const SizedBox.shrink()),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeHelper.accentColor(),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: ThemeHelper.neutral100(context),
      cardColor: ThemeHelper.neutral100(context),
      dividerColor: ThemeHelper.neutral400(context),
      canvasColor: ThemeHelper.neutral800(context),
      primaryColor: ThemeHelper.accentColor(),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeHelper.neutral100(context),
        foregroundColor: ThemeHelper.neutral300(context),
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeHelper.neutral800(context)),
      ),
      iconTheme: IconThemeData(color: ThemeHelper.neutral800(context)),
      textTheme: NarwhalTextTheme.textTheme.apply(
        bodyColor: ThemeHelper.neutral300(context),
        displayColor: ThemeHelper.neutral300(context),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: ThemeHelper.neutral300(context),
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeHelper.neutral400(context)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration(milliseconds: 800),
        decoration: BoxDecoration(
          color: ThemeHelper.neutral700(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      popupMenuTheme:
          PopupMenuThemeData(color: ThemeHelper.neutral800(context)),
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
  ) =>
      child;
}
