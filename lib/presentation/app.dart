import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

class NarwhalApp extends ConsumerStatefulWidget {
  const NarwhalApp({super.key});

  @override
  ConsumerState<NarwhalApp> createState() => _NarwhalAppState();
}

class _NarwhalAppState extends ConsumerState<NarwhalApp> {
  @override
  Widget build(BuildContext context) {
    final routerInstance = ref.watch(routerProvider);

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

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
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
