## Error Handling and Code Quality Guidelines

### Fallback Methods - CRITICAL RULE

- **NEVER** add fallback methods, try-catch wrappers, or alternative code paths unless the user explicitly requests them
- **ALWAYS** let errors fail clearly and directly
- **REASONING**: Fallback methods mask the real issues and make debugging much harder
- **EXAMPLES OF WHAT NOT TO DO**:
  - Adding try-catch blocks that swallow exceptions
  - Adding "if X fails, try Y" alternative approaches
  - Adding default values when operations fail
- **WHAT TO DO INSTEAD**: Let the operation fail with a clear, descriptive error message

### Exception: When Fallbacks Are Allowed

- Only when the user explicitly says "add a fallback" or "if this fails, try that alternative"
- Document why the fallback exists in comments
- Make fallbacks as specific as possible, not generic catch-alls

### Riverpod WidgetRef Usage - CRITICAL RULES

When writing Flutter widgets with Riverpod, follow these rules for `ref.*` usage in widget lifecycle methods:

#### NEVER use ref.\* directly in initState()

- **CRITICAL**: The WidgetRef `ref` is not established yet when `initState()` runs directly
- Direct `ref.watch()`, `ref.read()`, or `ref.listen()` calls will cause errors
- **EXCEPTION - Safe pattern**: It IS acceptable to use `ref.*` inside `WidgetsBinding.instance.addPostFrameCallback()` within `initState()`, because this ensures the widget has loaded at least one frame:
  ```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safe to use ref.* here after first frame
      ref.read(someProvider.notifier).doSomething();
    });
  }
  ```
- **What to do instead**: Use the `addPostFrameCallback` pattern above, or use `ref.listen()` / `ref.read()` in the widget's `build()` method

#### NEVER use ref.\* in dispose()

- **CRITICAL**: The WidgetRef `ref` no longer exists or is no longer safe to access when `dispose()` is called
- Any `ref.*` calls will cause errors or undefined behavior
- **What to do instead**:
  - **Preferred**: Use `.autoDispose` modifier on providers so cleanup is handled automatically
  - **NEVER** use `ref.*` in `deactivate()` either — `ref` is not reliably accessible (widget may be in-between states or already disposed), causing errors or silent failures
  - **Alternative**: Reset provider state on the next mount via `addPostFrameCallback` in `initState()` of the widget that owns the state

#### Valid Patterns

- **Use ref.watch()** in the `build()` method for reactive UI updates
- **Use ref.read()** in event handlers (button callbacks, etc.) for one-time reads
- **Use ref.listen()** in the `build()` method for side effects based on provider changes
- **Use WidgetsBinding.instance.addPostFrameCallback()** in `initState()` when you need to access ref after the first frame

## UI Widget Conventions

### Text Styling - CRITICAL RULE

- **ALWAYS** use `NarwhalTextStyle(...)` instead of Flutter's native `TextStyle(...)`
- **NEVER** write `style: TextStyle(...)` anywhere in the codebase
- `NarwhalTextStyle` accepts the same parameters as `TextStyle` and ensures design-system-consistent typography

### Icons - CRITICAL RULE

- **ALWAYS** prefer `NarwhalIcon(NarwhalIcons.xxx, ...)` over Flutter's native `Icon(Icons.xxx, ...)`
- Use `NarwhalIcon` whenever a `NarwhalIcons` constant exists for the desired icon
- Only fall back to `Icon(Icons.xxx)` when there is no matching `NarwhalIcons` constant for the required icon

### Custom Painting - CRITICAL RULE

- **ALWAYS** use `NarwhalPaint` instead of Flutter's native `CustomPaint`
- **ALWAYS** use `NarwhalPainter` (from `lib/presentation/common_widget/narwhal_paint.dart`) instead of `CustomPainter`
- `NarwhalPainter` takes a `BuildContext` in its constructor — pass it at creation time so `ThemeHelper` colors are accessible inside `paint()`
- `NarwhalPaint` wraps `Material` + `CustomPaint` to ensure consistent color rendering across Flutter's Material and Canvas pipelines

### Colors - CRITICAL RULE

- **ALWAYS** use `ThemeHelper` colors (e.g. `ThemeHelper.neutral100(context)`) instead of hardcoded color values
- **NEVER** write `Color(0xFF...)`, `Colors.xxx`, or any other hardcoded color literal in widget code
- **EXCEPTION — no context**: When a `BuildContext` or `ThemeHelper` is genuinely inaccessible (e.g. in a constant or a static context), a hardcoded color may be used as a temporary measure — but it **MUST** be accompanied by a comment:
  ```dart
  // TODO: replace with ThemeHelper color once context is available
  const Color(0xFF2A2A2A)
  ```
  Note: painters are **not** an exception — use `NarwhalPainter` which receives `BuildContext` directly.
- **EXCEPTION — transparency**: `Colors.transparent` is always acceptable and requires no comment

---

## Architecture Quick Reference

### Import Convention

Every Dart file: `import 'package:onyxia/export.dart';`
This barrel includes ALL providers, models, common widgets, and helpers. Never add granular imports for symbols already in `export.dart`.

### File Path Conventions

- Provider + its Notifier → same file at `lib/data/providers/<name>_provider.dart`
- Canvas-specific providers → `lib/presentation/screens/canvas/providers/<name>_provider.dart`
- Repositories → `lib/repository/<name>_repository.dart` (all extend `BaseSupabaseRepository<T>`)
- Screens → `lib/presentation/screens/<name>/<name>_screen.dart` + `widgets/` subdirectory
- Models → `lib/data/models/<domain>/<name>.dart`

### Auth Guard Pattern (required in all auth-dependent providers)

Watch `authProvider` and `currentUserProvider` inside `build()` so the notifier rebuilds when auth state changes. The notifier returns its initial state regardless — Riverpod handles re-running `build()` on dependency change, so explicit `.id.isEmpty` checks aren't needed.

```dart
@override
<State> build() {
  ref.watch(authProvider);
  ref.watch(currentUserProvider);
  return <State>.initial();
}
```

See `lib/data/providers/projects_provider.dart` for the canonical example.

### Key Providers

- `authProvider` → `AsyncValue<Session?>` (StreamProvider over Supabase auth state changes; `Session` is `supabase_flutter`'s type)
- `currentUserProvider` → `User` (NotifierProvider, sync)
- Both must be watched in every auth-dependent provider

---

## ThemeHelper Quick Reference

All methods are `static` on `ThemeHelper`. **Never invent or guess a method name** — check `lib/helpers/theme_helper.dart` before using.

**Context-aware** (all take `BuildContext context`):

- Neutral: `neutral100` `neutral200` `neutral300` `neutral400` `neutral500` `neutral600` `neutral700` `neutral800` `neutral900`
- Blue: `blue100` `blue200` `blue300` `blue400` `blue500` `blue600` `blue700` `blue800`
- Red: `red100` `red200` `red300` `red400` `red500` `red600` `red700` `red800` `red900`
- Orange: `orange100` `orange200` `orange400` `orange500` `orange600` `orange700`
- Green: `green100` `green200` `green300` `green400` `green500` `green600` `green700`
- Purple: `purple100` `purple200` `purple300` `purple400` `purple500` `purple600`
- Special: `black(ctx)` `white(ctx)`

**Context-free** (no BuildContext):

- `blue()` `red()` `orange()` `green()` `purple()` — fixed accent shades
- `amber()` `yellow()` `errorColor()` `accentColor()`

---

## Scaffolding Templates

Use these verbatim when creating new files. Replace `<Name>` / `<name>` / `<Model>` / `<State>` / `<table>` with actual names.

### Repository

```dart
// lib/repository/<name>_repository.dart
import 'package:onyxia/export.dart';

class <Name>Repository extends BaseSupabaseRepository<<Model>> {
  <Name>Repository({super.projectId});

  @override
  String get tableName => '<table>';

  @override
  <Model> fromMap(Map<String, dynamic> map) => <Model>.fromMap(map);

  @override
  Map<String, dynamic> toMap(<Model> item) => item.toMap();

  @override
  String getIdFromItem(<Model> item) => item.id;

  // Optional overrides:
  // @override bool get requireProjectId => false;        // for non-project-scoped tables (e.g. users)
  // @override String? get scopeField => 'canvas_id';     // when scoping by a column other than project_id
  // @override String? get defaultOrderBy => 'created_at';
}
```

### Provider + Notifier

We use `flutter_riverpod` 3.x. `StateNotifier` / `StateNotifierProvider` / `StateProvider` are removed — use `Notifier` + `NotifierProvider` instead. The `state` setter is `@protected`, so external mutators expose explicit methods (e.g. `set(value)`, `toggle()`).

```dart
// lib/data/providers/<name>_provider.dart
import 'package:onyxia/export.dart';

final <name>Provider =
    NotifierProvider.autoDispose<<Name>Notifier, <State>>(<Name>Notifier.new);

class <Name>Notifier extends Notifier<<State>> {
  @override
  <State> build() {
    ref.watch(authProvider);
    ref.watch(currentUserProvider);
    return <State>.initial();
  }
}
```

For a family-parameterized notifier:

```dart
final <name>Provider =
    NotifierProvider.family<<Name>Notifier, <State>, <Arg>>(<Name>Notifier.new);

class <Name>Notifier extends Notifier<<State>> {
  <Name>Notifier(this.arg);
  final <Arg> arg;

  @override
  <State> build() => <State>.initial();
}
```

For a simple holder that replaces an old `StateProvider<T>` (callers wrote
`ref.read(p.notifier).state = v`):

```dart
final <name>Provider =
    NotifierProvider<<Name>Notifier, <T>>(<Name>Notifier.new);

class <Name>Notifier extends Notifier<<T>> {
  @override
  <T> build() => /* initial */;

  void set(<T> value) => state = value;
}
```

Callers then use `ref.read(<name>Provider.notifier).set(v)` instead of `.state = v`.

### Model

```dart
class <Name> {
  final String id;

  <Name>({required this.id});

  factory <Name>.initial() => <Name>(id: '');

  <Name> copyWith({String? id}) => <Name>(id: id ?? this.id);

  Map<String, dynamic> toMap() => {'id': id};

  factory <Name>.fromMap(Map<String, dynamic> map) =>
      <Name>(id: map['id'] ?? '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is <Name> && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

### Screen

```dart
// lib/presentation/screens/<name>/<name>_screen.dart
import 'package:onyxia/export.dart';

class <Name>Screen extends ConsumerStatefulWidget {
  const <Name>Screen({super.key});

  @override
  ConsumerState<<Name>Screen> createState() => _<Name>ScreenState();
}

class _<Name>ScreenState extends ConsumerState<<Name>Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ref.read(...) calls go here
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // replace with actual scaffold
  }
}
```

### Provider Unit Test

```dart
// test/<feature>/<name>_notifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onyxia/<path>/<name>_provider.dart';
import '../helpers/provider_test_helpers.dart';

void main() {
  group('<Name>Notifier', () {
    late ProviderContainer container;

    setUp(() {
      container = makeTestContainer(overrides: [
        // Override auth-dependent providers directly:
        // <name>Provider.overrideWith((ref) => <Name>Notifier(<State>.initial())),
      ]);
    });

    tearDown(() => container.dispose());

    test('initial state is correct', () {
      final state = container.read(<name>Provider);
      expect(state, <State>.initial());
    });
  });
}
```

---

## Violation Scanner

Run `/sweep-violations` (`.claude/commands/sweep-violations.md`) at any time for a full audit of all 600+ Dart files.

To install the pre-commit hook (one-time, from the repo root):

```bash
ln -sf ../../scripts/check_narwhal_rules.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```
