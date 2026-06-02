import 'package:onyxia/export.dart';

/// Stream of the current Supabase Session — null when signed out.
final authProvider = StreamProvider<Session?>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session,
  ),
);
