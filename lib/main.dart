import 'export.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorHandler.install();

  BrowserContextMenu.disableContextMenu();

  await Supabase.initialize(
    url: 'https://nhceibemgsbcgsrqrvzd.supabase.co',
    anonKey: 'sb_publishable_s_Lw-sNKGvdng1Vs9LWJcQ_PP-gh-t_',
    authOptions: const FlutterAuthClientOptions(authFlowType: .pkce),
  );

  usePathUrlStrategy();

  runApp(
    ProviderScope(
      observers: const [GlobalProviderObserver()],
      child: const OnyxiaApp(),
    ),
  );
}
