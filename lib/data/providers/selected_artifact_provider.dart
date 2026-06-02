import 'package:onyxia/export.dart';

final selectedArtifactProvider =
    NotifierProvider<_SelectedArtifactNotifier, Artifact?>(
      _SelectedArtifactNotifier.new,
    );

class _SelectedArtifactNotifier extends Notifier<Artifact?> {
  // Last successfully-resolved selection. Used to bridge the brief window
  // during a rename where the realtime artifact stream re-emits the renamed
  // note with its OLD name (a concurrent multi-row update — the renamed note
  // plus every note whose `[[wikilink]]` was rewritten — can deliver the other
  // rows first) while the URL already holds the NEW name. Matching by name
  // alone would momentarily find nothing and tear the editor down; instead we
  // keep the held artifact as long as the URL name hasn't changed since we
  // last resolved it.
  String? _lastId;
  String? _lastName;

  @override
  Artifact? build() {
    final name = ref.watch(_selectedArtifactNameFromUrlProvider);
    final artifacts = ref.watch(artifactsProvider).value ?? const <Artifact>[];

    if (name == null || name.isEmpty || name == Routes.graph) {
      _lastId = null;
      _lastName = null;
      return null;
    }

    final match = artifacts.firstWhereOrNull((a) => a.name == name);
    if (match != null) {
      _lastId = match.id;
      _lastName = name;
      return match;
    }

    // URL name currently resolves to nothing. If it hasn't changed since our
    // last resolve and the held artifact still exists, the list is just
    // momentarily stale mid-rename — keep the selection rather than flashing
    // to null. A genuine navigation (zombie wiki-link, graph, new note) moves
    // the URL to a different name, so `_lastName != name` and we fall through.
    if (_lastId != null && _lastName == name) {
      final held = artifacts.firstWhereOrNull((a) => a.id == _lastId);
      if (held != null) return held;
    }

    _lastId = null;
    _lastName = null;
    return null;
  }
}

final _selectedArtifactNameFromUrlProvider =
    NotifierProvider<_SelectedArtifactNameFromUrlNotifier, String?>(
      _SelectedArtifactNameFromUrlNotifier.new,
    );

class _SelectedArtifactNameFromUrlNotifier extends Notifier<String?> {
  @override
  String? build() {
    final router = ref.watch(routerProvider);
    void listener() {
      state = router
          .routerDelegate
          .currentConfiguration
          .pathParameters['selectedId'];
    }

    router.routeInformationProvider.addListener(listener);
    ref.onDispose(() {
      router.routeInformationProvider.removeListener(listener);
    });
    return router
        .routerDelegate
        .currentConfiguration
        .pathParameters['selectedId'];
  }
}
