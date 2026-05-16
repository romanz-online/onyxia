import 'export.dart';
import 'supabase_config.dart';

void main() async {
  if (!kIsWeb) return;

  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorHandler.install();

  BrowserContextMenu.disableContextMenu();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(ProviderScope(
    observers: const [GlobalProviderObserver()],
    child: const NarwhalApp(),
  ));
}
