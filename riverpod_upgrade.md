# Plan: Upgrade flutter_riverpod 2.6.1 → 3.3.1

## Context

The codebase pins `flutter_riverpod: ^2.6.1` and uses 22 `StateNotifierProvider`s, manual `_mounted` flags, hand-written `StreamSubscription`s, and an `ArtifactsTreeNotifier` that propagates loading/error state into sibling `StateProvider`s via `ref.read(...).state = X`. Riverpod 3.x deprecates `StateNotifier`, ships a unified `Ref`, adds `ref.mounted`, includes free automatic retry on `AsyncNotifier`, and adds a `Mutation` API for structured writes.

This plan upgrades the dependency and migrates code to the new APIs **without introducing code generation or tests**. The goal is to delete boilerplate (subscriptions, `_mounted` fields, dispose overrides), get free retry on async loads, and surface loading/error states uniformly through `AsyncValue` instead of side-channel `StateProvider`s.

## Phase 1 — Bump and fix breaking changes

Modify [pubspec.yaml:34](pubspec.yaml#L34):

```yaml
flutter_riverpod: ^3.3.1
```

Run `flutter pub upgrade flutter_riverpod`, then `flutter analyze`. Breaking changes to expect and fix:

- **`Ref` is unified.** Anywhere a notifier constructor takes `Ref ref` (e.g. [note_state_provider.dart:39](lib/data/providers/note_state_provider.dart#L39), [artifacts_provider.dart:37](lib/data/providers/artifacts_provider.dart#L37)) continues to compile; remove constructor injection in Phase 2 once they become `Notifier`/`AsyncNotifier` subclasses.
- **`StateNotifier`/`StateNotifierProvider` emit deprecation warnings.** They still work — fix progressively in Phase 2/3.
- **`AutoDisposeStateNotifierProvider` typedef** in [note_state_provider.dart:170-171](lib/data/providers/note_state_provider.dart#L170-L171) becomes a deprecation hotspot; replace when migrating that file.
- **`ProviderObserver` signature change** if any observer is registered (none currently).
- **`StreamProvider`/`FutureProvider` retry default.** Two existing `StreamProvider`s gain auto-retry — verify nothing relies on a single failure terminating the stream.

Exit criterion: `flutter analyze` clean, app boots, auth + project selection work.

## Phase 2 — Migrate auth, projects, current user (the foundation)

These providers are watched by everything else, so migrating them first lets later phases watch a clean `AsyncValue` instead of inventing their own loading flags.

### [lib/data/providers/current_user_provider.dart](lib/data/providers/current_user_provider.dart)

Convert `CurrentUserNotifier` to a `StreamNotifier<User>` (or `AsyncNotifier<User>` that listens internally). The manual `StreamSubscription` + `_loadUserFromTable` + `dispose` block collapses to:

```dart
class CurrentUserNotifier extends StreamNotifier<User> {
  @override
  Stream<User> build() {
    final repo = ref.watch(authRepositoryProvider);
    return repo.authStateChanges.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) return User.initial();
      final user = await UsersRepository().get(session.user.id);
      return user?.copyWith(isLogged: true) ?? User.initial();
    });
  }
  // signOut / signInWithGoogle / etc. stay as instance methods — they can call ref.read(authRepositoryProvider)
}
```

Consumers currently watch `currentUserProvider` and get `User` directly. After migration the type is `AsyncValue<User>` — update the few call sites (search `currentUserProvider` and `.id.isEmpty`). The auth-guard pattern then becomes `currentUser.valueOrNull?.id.isEmpty ?? true`.

### [lib/data/providers/projects_provider.dart](lib/data/providers/projects_provider.dart)

Convert `ProjectsNotifier` to `AsyncNotifier<Projects>`:

- `build()` returns `await projectsRepository.getAll()` wrapped in the `Projects` state.
- Free automatic retry replaces the swallowed `catch (e)` at [projects_provider.dart:33-37](lib/data/providers/projects_provider.dart#L33-L37).
- `_mounted` checks disappear — `AsyncNotifier` mutators use `state = AsyncData(...)` which is safe after dispose.
- The duplicated branches at [projects_provider.dart:8-12](lib/data/providers/projects_provider.dart#L8-L12) (both return the same notifier) collapse to a single `build()` that watches `authProvider` and returns `Projects.initial()` when unauthed.

Mutator methods (`addProject`, `deleteProject`, `renameProject`, `updateSelectedProject`) continue to mutate `state.value` and write to the repository — these are candidates for Phase 4 Mutations.

### [lib/data/providers/auth_provider.dart](lib/data/providers/auth_provider.dart)

Already a stream-driven provider — verify it survives the bump unchanged (likely yes, it returns `AsyncValue<Session?>`).

Exit criterion: app loads projects, sign-in/out cycle works, no `StateNotifier` references remain in these three files.

## Phase 3 — Migrate artifacts and note state

### [lib/data/providers/artifacts_provider.dart](lib/data/providers/artifacts_provider.dart)

Convert `ArtifactsTreeNotifier` to `StreamNotifier<List<Artifact>>`:

```dart
class ArtifactsTreeNotifier extends StreamNotifier<List<Artifact>> {
  @override
  Stream<List<Artifact>> build() {
    final projectId = ref.watch(projectsProvider.select((s) => s.valueOrNull?.selectedProject?.id));
    if (projectId == null) return Stream.value([]);
    return ArtifactsRepository(projectId: projectId).getStream();
  }
  // mutators (addItem, deleteItem, updateParent, ...) stay
}
```

**Delete [artifacts_provider.dart:24-28](lib/data/providers/artifacts_provider.dart#L24-L28) (`artifactsReceivedProvider`, `artifactsErrorProvider`) entirely.** They exist only because `StateNotifier<List<Artifact>>` cannot express "still loading" or "errored". Once the state is `AsyncValue<List<Artifact>>`, [artifacts_provider.dart:15-22](lib/data/providers/artifacts_provider.dart#L15-L22) (`artifactsLoadedProvider`) becomes:

```dart
final artifactsLoadedProvider = Provider<bool>((ref) {
  final async = ref.watch(artifactsProvider);
  return async.hasValue && !async.hasError;
});
```

Then delete the `ref.read(_receivedProvider...).state = true` writes at [artifacts_provider.dart:60-66](lib/data/providers/artifacts_provider.dart#L60-L66). Find consumers of the removed providers (grep `artifactsReceivedProvider`, `artifactsErrorProvider`) and switch them to `artifactsProvider`'s `AsyncValue` directly — this is the single biggest cleanup in the migration.

### [lib/data/providers/note_state_provider.dart](lib/data/providers/note_state_provider.dart)

Convert `NoteNotifier` to `AsyncNotifier<NoteState>`:

- Drop `_mounted` (field at [note_state_provider.dart:41](lib/data/providers/note_state_provider.dart#L41), all 9 check sites). Replace with `ref.mounted` where genuinely needed inside async callbacks; most checks are unnecessary because `AsyncNotifier` already guards `state =` after dispose.
- Drop the `Ref ref` constructor parameter at [note_state_provider.dart:39](lib/data/providers/note_state_provider.dart#L39) — `ref` is on `this`.
- Drop the `AutoDisposeStateNotifierProvider` typedef at [note_state_provider.dart:170-171](lib/data/providers/note_state_provider.dart#L170-L171); use `AutoDisposeAsyncNotifierProviderImpl<NoteNotifier, NoteState>` or just drop the alias.
- Use `ref.onDispose` inside `build()` for the debounce `Timer` and `BardController` cleanup instead of overriding `dispose()`.

Exit criterion: opening a note streams content correctly, debounced auto-save still works, no `_mounted` field remains.

## Phase 4 — Adopt Mutations API for writes

Mutations give callers `pending`/`success`/`error` states for free, which the UI can `ref.watch` for spinners and error toasts. Highest-value conversions (write methods with user-visible feedback):

- [projects_provider.dart:107-117](lib/data/providers/projects_provider.dart#L107-L117) `removeMember` — currently shows toasts inline. Convert to a `Mutation` and let the screen watch its state.
- [projects_provider.dart:119-146](lib/data/providers/projects_provider.dart#L119-L146) `addMemberByEmail` — same pattern, inline toasts.
- `ArtifactsTreeNotifier.addItem`, `addItems`, `deleteItem`, `updateItem`, `updateParent` — currently fire-and-forget repository calls; Mutations surface failures.
- `ProjectsNotifier.deleteProject`, `addProject`, `renameProject`, `updateSelectedProject` — same.

Defer Mutations on canvas providers ([lib/presentation/canvas_engine/providers/](lib/presentation/canvas_engine/providers/)) to a follow-up — they're write-heavy and hot, so do them once the pattern is proven on the simpler list providers.

## Phase 5 — Replace ad-hoc cross-provider mutation with `ref.listen`

The `ref.read(otherProvider.notifier).state = X` pattern (after Phase 3, only one residual case in [artifacts_provider.dart:101-104](lib/data/providers/artifacts_provider.dart#L101-L104) — clearing `selectedArtifactProvider` when its target is deleted) should move to `ref.listen` on the consumer side. Audit with grep `\.notifier\)\.state\s*=` and convert each.

## Phase 6 — Migrate remaining StateNotifierProviders

After Phases 2–3, ~17 `StateNotifierProvider`s remain (canvas providers in [lib/presentation/canvas_engine/providers/](lib/presentation/canvas_engine/providers/), [lib/data/providers/](lib/data/providers/) misc). Convert each `class FooNotifier extends StateNotifier<Bar>` → `class FooNotifier extends Notifier<Bar>` and `final fooProvider = StateNotifierProvider(...)` → `final fooProvider = NotifierProvider(...)`. The mechanical rule:

- Sync-only state, no async init → `Notifier<T>`
- Async init or error-prone load → `AsyncNotifier<T>`
- Stream-backed → `StreamNotifier<T>`
- `ref` moves from constructor parameter to inherited member; remove the parameter and any `final Ref ref;` field.

## Update CLAUDE.md scaffolding templates

Replace the StateNotifierProvider template at [CLAUDE.md](CLAUDE.md) ("Provider + Notifier" section, the `lib/data/providers/<name>_provider.dart` block) with the new `Notifier`/`AsyncNotifier` form. Update the auth-guard snippet to use `valueOrNull` on `currentUserProvider`. Leave the test scaffold alone (user does not want tests).

## Critical files to modify

1. [pubspec.yaml](pubspec.yaml) — version bump
2. [lib/data/providers/current_user_provider.dart](lib/data/providers/current_user_provider.dart) — `StreamNotifier`
3. [lib/data/providers/projects_provider.dart](lib/data/providers/projects_provider.dart) — `AsyncNotifier` + Mutations
4. [lib/data/providers/artifacts_provider.dart](lib/data/providers/artifacts_provider.dart) — `StreamNotifier`, delete sidecar received/error providers
5. [lib/data/providers/note_state_provider.dart](lib/data/providers/note_state_provider.dart) — `AsyncNotifier`, drop `_mounted`
6. ~17 remaining `_provider.dart` files under [lib/data/providers/](lib/data/providers/) and [lib/presentation/canvas_engine/providers/](lib/presentation/canvas_engine/providers/)
7. [CLAUDE.md](CLAUDE.md) — update scaffolding template

## Verification

After each phase:

1. `flutter analyze` — no new errors or `StateNotifier` deprecation warnings for migrated files
2. `flutter run` — sign in, list/select project, open the artifact tree, open a note, type to trigger auto-save, sign out
3. Force a Supabase error (e.g. revoke RLS temporarily on `artifacts`) and confirm:
   - The error surfaces in `artifactsProvider`'s `AsyncValue.error`
   - Auto-retry fires (visible in network tab as repeated requests with backoff)
   - UI shows the error state instead of an empty list
4. Hot-reload while a debounced save is pending — confirm the timer is cancelled cleanly (no "setState after dispose" exceptions)

## Out of scope

- Code generation with `@riverpod` / `riverpod_generator` (per user instruction)
- Adding tests (per user instruction)
- Offline persistence (`Storage` API) — defer as a separate follow-up
