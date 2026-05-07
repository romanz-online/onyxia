# Plan: Sever Onyxia from Narwhal (Supabase + GitHub Pages)

## Context

The `onyxia` branch (heavily trimmed, web-focused fork of `narwhal-flutter`) needs to become a fully independent app. The original plan was to keep using Firebase but on a separate project. That has been replaced: **Onyxia now runs on Supabase (Postgres + Auth + Storage)** for backend and **GitHub Pages** for static hosting. The conceptual goal — full severance from `narwhal-flutter` — is unchanged. Every backend implementation step changes because the stack changes.

A new GitHub repo is already in place (`main` branch). A Supabase project is already created. There is no production data to migrate (clean start).

---

## Phase A — Project skeleton & Supabase wiring

**A1.** Update `pubspec.yaml` dependencies:
- Add: `supabase_flutter: ^2.x`
- Remove: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- Run `flutter pub get`

**A2.** Capture Supabase credentials from the dashboard (Project Settings → API):
- `SUPABASE_URL` (e.g. `https://<project-ref>.supabase.co`)
- `SUPABASE_ANON_KEY`

These are passed at build time via `--dart-define=SUPABASE_URL=...` and read in code via `String.fromEnvironment(...)`. They never go in source control.

**A3.** Initialize Supabase in [lib/main.dart](lib/main.dart) (replaces `Firebase.initializeApp(...)`):
```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

**A4.** Delete now-obsolete files:
- [.firebaserc](.firebaserc)
- [firebase.json](firebase.json)
- [lib/firebase_options.dart](lib/firebase_options.dart)
- [storage.rules](storage.rules)

**A5.** Sanity check: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` boots without errors. (Repos won't work yet — that's later phases.)

---

## Phase B — Postgres schema

All schema changes live in a single migration file: `supabase/migrations/0001_init.sql`. Apply with `supabase db push` (Supabase CLI) or by running the SQL in the dashboard's SQL editor.

**B1. Tables.** Translate the current Firestore collections into relational tables. Every table has the audit columns `created_at timestamptz`, `updated_at timestamptz`, `created_by uuid references auth.users(id)`, `updated_by uuid references auth.users(id)`.

| Table | Notes |
|---|---|
| `users` | `id uuid PK = auth.users.id`, `email`, `name`, `image_url` |
| `projects` | `id`, `name` |
| `project_members` | `project_id`, `user_id`, `role`, PK = (`project_id`, `user_id`) |
| `artifacts` | `id`, `project_id` FK, `parent_folder_id` nullable self-FK, `type` enum (`folder`/`note`/`canvas`), `name`, `body jsonb` (note bodies) |
| `canvas_objects` | `id`, `canvas_artifact_id` FK→`artifacts`, `kind` enum (`arrow`/`brush`/`image`), `payload jsonb` |
| `pins` | `id`, `canvas_artifact_id` FK, `target_object_id` nullable, `x`, `y`, `expandable bool` |
| `comments` | `id`, `target_id`, `body` |
| `sub_comments` | `id`, `comment_id` FK→`comments`, `body` |
| `history_diffs` | `id`, `canvas_artifact_id` FK, `diff jsonb`, `seq int` |
| `storage_files` | `id`, `project_id`, `canvas_id` nullable, `user_id`, `path`, `mime`, `size` — mirror of objects in Supabase Storage |

**B2. Audit triggers.** Two reusable trigger functions:
- `set_created_audit()` BEFORE INSERT — sets `created_at = now()`, `created_by = auth.uid()`, plus `updated_at` / `updated_by`
- `set_updated_audit()` BEFORE UPDATE — sets `updated_at = now()`, `updated_by = auth.uid()`

Attach to every table. This replaces the app-level `_blame()` / `_create()` helpers in `BaseFirestoreRepository`.

**B3. Auth-to-public mirror trigger.** When a row is inserted into `auth.users`, insert a matching row into `public.users` (id + email + `raw_user_meta_data->>'name'` + avatar). This replaces the Firestore `users/` mirror that the current `auth_repository.dart` maintains by hand.

**B4. RLS policies.** Default-deny on every table. Members of a project can read/write that project's data. One policy file (or one migration block) per table — easier to audit and revise than one giant policy.

**B5. Indexes.** All FK columns; plus any column used in a `WHERE` filter inside the repository layer (e.g. `artifacts.project_id`, `canvas_objects.canvas_artifact_id`, `comments.target_id`).

**B6.** Apply: `supabase db push` (or paste into dashboard SQL editor for the first run).

---

## Phase C — New repository layer

**C1.** Create [lib/repository/base_supabase_repository.dart](lib/repository/base_supabase_repository.dart). Mirror the surface area of [lib/repository/base_firestore_repository.dart](lib/repository/base_firestore_repository.dart) so the 9 concrete subclasses change as little as possible:

- `get`, `getAll`, `query`, `add`, `addMultiple`, `update`, `updateMultiple`, `delete`, `deleteMultiple`
- `getStream`, `getDocumentStream`, `queryStream`

Implementation notes:
- **Reads**: `Supabase.instance.client.from(table).select()`, with the existing 11 `where`-style operators translating to PostgREST methods (`.eq`, `.neq`, `.lt`, `.lte`, `.gt`, `.gte`, `.contains`, `.containedBy`, `.inFilter`, `.is_`, etc.).
- **Writes**: `.upsert(...)` / `.update(...).match(...)` / `.delete().match(...)`. For bulk writes, pass an array — Supabase runs each batch in a single transaction server-side.
- **Streams**: Realtime channels — `client.channel('public:$table').onPostgresChanges(event: ..., schema: 'public', table: ..., callback: ...).subscribe()`.
- **Drop** `_blame()` / `_create()` helpers — the DB triggers from B2 set audit columns now.
- **`updateProjectMetadata`** (which currently bumps `projects/{id}.updatedAt` after every write) becomes a Postgres trigger on the child tables that updates `projects.updated_at`. Remove the app-side override mechanism.
- **Multi-table writes** (only used in the auth reconciliation flow today, which is being dropped — see Phase D) can use a Postgres function (`create or replace function ... language plpgsql`) called via `client.rpc('fn_name', params: {...})` if needed later.

**C2.** Migrate the 9 concrete repositories one by one. Each becomes a thin subclass of `BaseSupabaseRepository<T>`:

| File | Backing table |
|---|---|
| [lib/repository/artifacts_repository.dart](lib/repository/artifacts_repository.dart) | `artifacts` |
| [lib/repository/canvas_cursors_repository.dart](lib/repository/canvas_cursors_repository.dart) | **Realtime broadcast only — no table** (cursors are ephemeral presence) |
| [lib/repository/canvas_objects_repository.dart](lib/repository/canvas_objects_repository.dart) | `canvas_objects` |
| [lib/repository/comments_repository.dart](lib/repository/comments_repository.dart) | `comments` + `sub_comments` |
| [lib/repository/history_diffs_repository.dart](lib/repository/history_diffs_repository.dart) | `history_diffs` |
| [lib/repository/pins_repository.dart](lib/repository/pins_repository.dart) | `pins` |
| [lib/repository/projects_repository.dart](lib/repository/projects_repository.dart) | `projects` + `project_members` |
| [lib/repository/user_definitions_repository.dart](lib/repository/user_definitions_repository.dart) | `users` |
| [lib/repository/user_references_repository.dart](lib/repository/user_references_repository.dart) | `users` (read-only) |

**C3.** Replace the 8 `.snapshots()` callsites with Realtime channel subscriptions. Cursor presence (`canvas_cursors_repository.dart`) should use Realtime **broadcast** channels (`channel.sendBroadcastMessage(...)`), not DB rows — cursors fire too often to write through Postgres.

**C4.** Once every concrete repository compiles against `BaseSupabaseRepository<T>`, delete [lib/repository/base_firestore_repository.dart](lib/repository/base_firestore_repository.dart).

---

## Phase D — Auth migration

**D1.** Rewrite [lib/data/providers/auth_provider.dart](lib/data/providers/auth_provider.dart):
```dart
final authProvider = StreamProvider<Session?>((ref) =>
    Supabase.instance.client.auth.onAuthStateChange
        .map((event) => event.session));
```

**D2.** Rewrite [lib/repository/auth_repository.dart](lib/repository/auth_repository.dart) against Supabase Auth:
- Google OAuth: `client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: '<deployed-origin>/auth/callback')`
- Email + password: `signUp(...)` / `signInWithPassword(...)`
- Magic link: `signInWithOtp(email: ..., emailRedirectTo: ...)`
- Sign out: `client.auth.signOut()`

The pending-user reconciliation flow from the old `auth_repository.dart` is **dropped** — invited users will sign in fresh against Supabase Auth and get a row via the trigger from B3. Reintroduce the flow later only if needed.

**D3.** Configure providers in the Supabase dashboard → Authentication → Providers:
- **Google**: create an OAuth 2.0 Web client in Google Cloud Console (APIs & Services → Credentials). Authorized redirect URI = `https://<project-ref>.supabase.co/auth/v1/callback`. Paste client ID + secret into Supabase.
- **Email + password**: enable.
- **Magic link**: part of the email provider — enable.

**D4.** Update [lib/data/providers/current_user_provider.dart](lib/data/providers/current_user_provider.dart) to read from the `public.users` table (populated by the B3 trigger) rather than Firestore. Drop the pending-user reconciliation logic.

---

## Phase E — Storage migration

**E1.** Create Storage buckets in the Supabase dashboard:
- `avatars` — public read
- `project-files` — private; access gated by RLS policies on the bucket
- `releases` — public read

**E2.** Replace [lib/services/firebase_storage_service.dart](lib/services/firebase_storage_service.dart) with `lib/services/supabase_storage_service.dart`. Keep the API surface identical so callers don't change. Underneath: `client.storage.from(bucket).upload(...)` / `download(...)` / `getPublicUrl(...)` / `createSignedUrl(...)`.

**E3.** Update [lib/repository/file_storage.dart](lib/repository/file_storage.dart) to upsert metadata into the `storage_files` table on every upload and delete the row on every removal.

**E4.** Bucket access policies (Supabase dashboard → Storage → Policies). Mirror the current rules:
- `releases/*` — public read, authenticated write
- `avatars/<uid>/*` — public read, write only by the owning uid
- `project-files/<project_id>/*` — read/write only by members of that project (join `project_members`)

---

## Phase F — App identity (carry-over)

**F1.** [pubspec.yaml](pubspec.yaml): confirm `name: onyxia` (already in place); update `description`.

**F2.** [web/manifest.json](web/manifest.json): `"name"` and `"short_name"` → `"Onyxia"`; update `"description"`.

**F3.** [web/index.html](web/index.html): `<title>` already says "Onyxia"; update `<meta name="description">` if it still mentions Narwhal; update `<meta name="apple-mobile-web-app-title">` if present.

(The original plan's "rename `package:onyxia/` → `package:onyxia/`" step was a typo and is dropped — imports already use `package:onyxia/`.)

---

## Phase G — Hosting on GitHub Pages

**G1.** GitHub repo → Settings → Pages → Source = "GitHub Actions".

**G2.** Add `.github/workflows/deploy.yml`:
```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: |
          flutter build web --release \
            --base-href /<repo-name>/ \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
      - id: deployment
        uses: actions/deploy-pages@v4
```

**G3.** Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to GitHub repo Secrets (Settings → Secrets and variables → Actions).

**G4.** After the first successful deploy, copy the Pages URL into Supabase dashboard → Authentication → URL Configuration → **Site URL** and **Additional Redirect URLs** (so OAuth and magic-link redirects are accepted).

**G5.** *(Optional)* Custom domain: GitHub Pages → custom domain → DNS CNAME → also add the custom domain to Supabase's redirect allowlist.

---

## Phase H — CI/CD cleanup

**H1.** If `.gitlab-ci.yml` still exists, delete it — the project is on GitHub now and the workflow from G2 is the only CI config needed.

**H2.** Remove `FIREBASE_TOKEN` and any other Firebase-related secrets from any CI environment that previously used them.

---

## What does NOT change

- Internal widget names (`NarwhalButton`, `NarwhalIcon`, `NarwhalPainter`, etc.) — internal utility names; renaming would be a massive refactor with zero user-facing benefit.
- Domain models in [lib/data/models/](lib/data/models/) — field shapes stay the same; only the persistence layer changes.
- [CLAUDE.md](CLAUDE.md) project conventions.
- The screen/widget tree under [lib/presentation/](lib/presentation/).

---

## Explicitly dropped from scope

- **Cloud Functions** — the original plan had a step for these; the repo never had a `functions/` directory, so there's nothing to port.
- **Pending-user reconciliation flow** — the current `auth_repository.dart` has logic to merge provisional invited-user records with real Firebase Auth users; this is being dropped. Reintroduce later only if invitation flows actually need it.
- **Package rename step** — the original plan listed `package:onyxia/` → `package:onyxia/`, which was a no-op typo. Imports already use `package:onyxia/`.

---

## Verification

1. `grep -r "package:firebase\|cloud_firestore" lib/` returns nothing.
2. `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` compiles cleanly.
3. App boots locally; auth state stream emits `null` initially.
4. Sign in with Google → returns to the app authenticated → a row appears in `public.users` (via the B3 trigger).
5. Create a project → rows appear in `projects` and `project_members`; a different signed-in user cannot read the project (RLS works).
6. Open a canvas in two browser sessions; drawing in one streams updates to the other via Realtime.
7. Upload an image → file lands in the `project-files` bucket and a metadata row appears in `storage_files`.
8. Push to `main` → GitHub Actions deploys to Pages → deployed URL loads, no console errors, Supabase auth callback completes against the deployed origin.
