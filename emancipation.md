# Plan: Divorce Onyxia from Narwhal

## Context

The `onyxia` branch (95 commits ahead of master, ~1,424 files removed, heavily trimmed web-focused version) needs to become a fully independent app with its own Git repo, Firebase project, hosting, and identity — completely severed from the `narwhal-flutter` Firebase project and the narwhalflutter GitLab repo.

---

## Step-by-Step Checklist

### 1. New Git Repository

- Create a new GitLab repo (e.g., `onyxia` or `onyxia-flutter`)
- From the current repo, push the onyxia branch as `main`:
  ```bash
  git remote add onyxia-origin <new-repo-url>
  git push onyxia-origin onyxia:main
  ```
- Clone the new repo locally and work from it going forward
- Remove the old `origin` remote so there's no accidental cross-push

### 2. New Firebase Project

- Go to [Firebase Console](https://console.firebase.google.com) → **Add project** → name it (e.g., `onyxia-app`)
- Enable **Google Analytics** if desired
- Enable **Authentication** → Sign-in methods:
  - Google (requires OAuth client setup — see step 6)
  - Any other methods currently used
- Enable **Firestore Database** → choose region matching narwhal's (check narwhal console to match latency)
- Enable **Storage**
- Enable **Hosting** (create two sites: `onyxia-app` for prod, `onyxia-app-staging` for staging)
- Enable **Cloud Functions** (if using Blaze plan — required for functions)

### 3. Regenerate firebase_options.dart

- Install/update FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Run: `flutterfire configure --project=<new-firebase-project-id>`
  - Select Web (and any other platforms needed)
  - This regenerates `lib/firebase_options.dart` with new API keys, app IDs, and project ID
- The current staging/production split logic in `firebase_options.dart` (checking hostname for `narwhal-staging.ics.com`) will need to be updated to check the new staging domain instead

### 4. Update .firebaserc

**File:** `.firebaserc`

- Replace `"default": "narwhal-flutter"` with `"default": "<new-project-id>"`
- Replace all `"narwhal-flutter"` hosting target names with the new site names

### 5. Update firebase.json

**File:** `firebase.json`

- Update `appId`, `measurementId`, `authDomain`, `storageBucket` under the hosting configs to new values
- Update hosting target names (production/staging site IDs)
- These values come from the Firebase Console for the new project

### 6. Google Sign-in OAuth Credentials

- In Google Cloud Console (linked to new Firebase project) → **APIs & Services** → **Credentials**
- Create an **OAuth 2.0 Client ID** for Web
- Add Authorized JavaScript Origins: your new domain(s)
- Add Authorized Redirect URIs: `https://<new-domain>/__/auth/handler`
- In Firebase Console → Authentication → Sign-in method → Google → paste the new Client ID + Secret
- Update `firebase_options.dart` if it contains a hardcoded `clientId` (currently it does for iOS/macOS)

### 7. Deploy Firestore Rules & Indexes

- Copy `firestore.rules` and `firestore.indexes.json` from current repo (they're Firebase-project-agnostic)
- Deploy: `firebase deploy --only firestore:rules,firestore:indexes`

### 8. Deploy Storage Rules

- Copy `storage.rules` (project-agnostic)
- Deploy: `firebase deploy --only storage`

### 9. Deploy Cloud Functions

**Directory:** `functions/`

- Update `functions/` Node.js code if it contains any hardcoded `narwhal-flutter` project references
- Deploy: `firebase deploy --only functions`
- Note: Functions billing requires Blaze plan on the new project

### 10. Update App Identity (user-visible strings)

**File:** `pubspec.yaml`

- Change `name: narwhal_flutter` → `name: onyxia` (or chosen name)
- Change `description` to match new app

**File:** `web/manifest.json`

- Change `"name": "Narwhal"` → `"name": "Onyxia"`
- Change `"short_name": "Narwhal"` → `"short_name": "Onyxia"`
- Change `"description"` to match

**File:** `web/index.html`

- `<title>` already says "Onyxia" ✓
- Update `<meta name="description">` (currently says "Narwhal is a web application…")
- Update `<meta name="apple-mobile-web-app-title">` if present

### 11. Update Package Name References

After renaming `name` in `pubspec.yaml`, all Dart imports using `package:onyxia/` must be updated to `package:onyxia/` (or whatever the new name is). This is a bulk find-replace across the entire `lib/` directory:

- `import 'package:onyxia/` → `import 'package:onyxia/`
- This affects every `.dart` file — use IDE rename or `sed` / PowerShell bulk replace

### 12. Update CI/CD

**File:** `.gitlab-ci.yml`

- Update any Firebase project ID references (deploy targets, project flags)
- Update any repo-specific URLs or environment variables
- Update deployment targets to point to new hosting sites

### 13. Custom Domain (if desired)

- In Firebase Console → Hosting → your new site → **Add custom domain**
- Point DNS to Firebase hosting servers
- Update `firebase_options.dart` staging detection logic to check the new domain instead of `narwhal-staging.ics.com`

### 14. Environment Variables / Secrets in CI

- GitLab CI uses masked variables for Firebase tokens, etc.
- In new GitLab repo → Settings → CI/CD → Variables: re-add `FIREBASE_TOKEN` (or service account key) for the new project

---

## What Does NOT Need to Change

- Internal widget names (`NarwhalButton`, `NarwhalIcon`, `NarwhalPainter`, etc.) — these are internal utility class names that users never see; renaming them would be a massive refactor with zero user-facing benefit
- Firestore collection schema — the `projects/`, `users/`, etc. paths are app-level, not Firebase-project-level
- `CLAUDE.md` — project conventions stay the same

---

## Verification

1. `flutter build web` succeeds with no import errors after package rename
2. `firebase deploy --only hosting` deploys to new project's hosting site
3. Open deployed URL → app loads, no console errors about wrong Firebase project
4. Google Sign-in completes successfully (OAuth domain is authorized)
5. Firestore read/write works (rules deployed, new project)
6. Functions callable from the app (if used)
