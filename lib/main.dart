import 'export.dart';
import 'supabase_config.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorHandler.install();

  BrowserContextMenu.disableContextMenu();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  usePathUrlStrategy();

  runApp(
    ProviderScope(
      observers: const [GlobalProviderObserver()],
      child: const NarwhalApp(),
    ),
  );
}
