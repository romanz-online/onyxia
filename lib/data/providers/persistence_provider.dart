import 'package:onyxia/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceNotifier extends StateNotifier<String?> {
  final String storageKey;
  final String defaultValue;
  // Tracks whether save() was called before _load() completed.
  // If true, _load() must not overwrite the explicitly saved value.
  bool _explicitlySaved = false;

  PersistenceNotifier({
    required this.storageKey,
    this.defaultValue = '',
  }) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(storageKey);
    if (id != null && id != defaultValue && mounted && !_explicitlySaved) {
      state = id;
    }
  }

  Future<void> save(String? id) async {
    // Mark as explicitly saved BEFORE the await so _load() won't overwrite
    // this value if it completes concurrently.
    _explicitlySaved = true;
    if (mounted) {
      state = id;
    }
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty || id == defaultValue) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, id);
    }
  }

  Future<void> clear() => save(null);
}

final itemPersistenceProvider = StateNotifierProvider<PersistenceNotifier, String?>((ref) {
  return PersistenceNotifier(storageKey: 'selected_item_id');
});
