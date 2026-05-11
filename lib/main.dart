import 'export.dart';
import 'supabase_config.dart';

void main() async {
  if (!kIsWeb) return;

  WidgetsFlutterBinding.ensureInitialized();

  BrowserContextMenu.disableContextMenu();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: NarwhalApp()));
}
