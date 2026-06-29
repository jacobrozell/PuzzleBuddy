# Puzzle Buddy — agent guide

Read this file first when working in this repo. It summarizes product reality, conventions, and where authoritative docs live.

**Last updated:** 2026-06-29

---

## Product snapshot (1.0.0)

| Topic | Reality |
|-------|---------|
| **Purpose** | Local-first jigsaw puzzle catalog (SwiftData on device) |
| **Account** | Not required — no login UI, no cloud sync |
| **Firebase** | **Analytics + Crashlytics only** (no Auth, Firestore, FCM in app or `project.yml`) |
| **Bundle ID** | `com.jacobrozell.Puzzle-Buddy` |
| **Min iOS** | 17.0 |
| **Apple team** | `7JT2JB89AV` (personal) |
| **Version source** | `project.yml` `MARKETING_VERSION` + `PuzzleBuddyApp.version` (keep in sync) |

Auth + Firestore were **removed June 2026** (Firebase Console cleaned up). Future account sync is a **planned spec only** — see [specs/planned/auth-cloud-sync.md](specs/planned/auth-cloud-sync.md). Do not reintroduce Auth/Firestore without an approved spec and explicit user request.

---

## Read order for common tasks

| Task | Start here |
|------|------------|
| Architecture / data flow | [docs/architecture.md](docs/architecture.md) |
| Logging, Analytics, Crashlytics | [docs/telemetry.md](docs/telemetry.md) |
| Firebase Console / plist | [docs/firebase-setup.md](docs/firebase-setup.md) |
| Feature behavior (verbose) | [docs/features.md](docs/features.md) |
| What ships vs gated vs planned | [docs/feature-inventory.md](docs/feature-inventory.md) |
| Local build / debug | [docs/development.md](docs/development.md) |
| Tests / UI test args | [docs/testing.md](docs/testing.md) |
| Phased ship checklist | [docs/agent-build-checklist.md](docs/agent-build-checklist.md) |
| Code style / PR expectations | [CONTRIBUTING.md](CONTRIBUTING.md) |

**Dart Buddy parity:** Telemetry follows the same pattern as [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy) — `AppLog` allowlist, Release-only remote collection, Crashlytics breadcrumbs at `.info+`, allowlisted non-fatals only.

---

## Repository layout

```
PuzzleBuddy/
├── AGENTS.md                    ← you are here
├── App/                ← app target (SwiftUI)
│   ├── Login/OnboardingView.swift   ← onboarding only (Login/ name is legacy)
│   ├── Views/                   ← screens, tab bar, settings
│   ├── Helpers/                 ← Puzzle, PuzzleRecord, PuzzleStore
│   └── Util/                    ← AppLogging, ProductService, DesignTokens, UITestSupport
├── AppTests/           ← unit tests
├── AppUITests/         ← UI + WCAG audits
├── docs/                        ← technical docs (+ GitHub Pages HTML)
├── specs/                       ← feature specs (planned + shipped snippets)
├── project.yml                  ← XcodeGen source of truth (regenerate .xcodeproj)
├── GoogleService-Info.plist.example
└── Scripts/ci/run-tests.sh
```

**Not in repo:** `PuzzleBuddy.xcodeproj` (generated), real `GoogleService-Info.plist` (gitignored).

---

## App entry flow

```
PuzzleBuddyApp
  → AppShell (splash unless UI test)
    → RootView
        → OnboardingView (first run)
        → PuzzleView → PuzzleTabbar (Puzzles | Stats | Settings)
            → PuzzleStore (SwiftData only)
AppDelegate → FirebaseApp.configure() when valid plist + not UI test
```

Key types:

| Type | Role |
|------|------|
| `PuzzleStore` | `@MainActor` collection CRUD; SwiftData via `ModelContext` |
| `Puzzle` | UI/domain `ObservableObject` |
| `PuzzleRecord` | SwiftData `@Model` persistence |
| `ProductService` | Feature flags (import/export gated; no login flags) |
| `AppLog.shared` | Only logging/analytics API |
| `ErrorHandling` | Root-level alert presentation |

---

## Feature flags (`ProductService`)

| Flag | Default | Launch argument |
|------|---------|-----------------|
| `isCollectionImportExportEnabled` | `false` | `-enable_collection_import_export` |
| `isBarcodeScanEnabled` | device capability | — |
| `isShoppingModeEnabled` | `true` | — |
| `isPickNextEnabled` | `true` | — |

There is **no** `isLoginEnabled` or cloud sync flag.

---

## Firebase & telemetry rules

1. **Never** call `Analytics.logEvent` or `Crashlytics` directly from feature code — use `AppLog.shared`.
2. New Analytics events → add to `PuzzleAnalyticsEventMapping.allowlistedEvents` in `AppLogging.swift` + document in [docs/telemetry.md](docs/telemetry.md) + unit test if mapping logic changes.
3. New Crashlytics non-fatals → add to `FirebaseCrashlyticsEventMapping` with stable error code + test in `AppLoggingTests`.
4. **No PII** in logs or metadata (`LogRedaction` strips email, uid, password, token, name, displayName).
5. Remote telemetry **off in Debug** unless `-firebase_analytics_debug`; off when `-disable_firebase_analytics` or under UI test (`UITestSupport.isRunningUnderTest`).
6. CI uses placeholder plist → `FirebaseBootstrap.shouldConfigure == false` → no Firebase init.

Full allowlists, bootstrap logic, and launch args: [docs/telemetry.md](docs/telemetry.md).

---

## Build & test commands

```bash
cd Puzzle-Buddy
cp GoogleService-Info.plist.example GoogleService-Info.plist   # CI / no-Firebase local
xcodegen generate
swiftlint lint
Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```

After editing `project.yml`: always `xcodegen generate`.

Personal git push: use `git@github.com-personal:jacobrozell/PuzzleBuddy.git` (see workspace rules).

---

## UI test launch arguments

| Argument | Purpose |
|----------|---------|
| `-disable_firebase_analytics` | Disable Analytics + Crashlytics collection |
| `-ui_testing_bypass_onboarding` | Skip onboarding in UI tests |
| `-ui_testing_seed_puzzles` | Load demo puzzles into SwiftData |
| `-enable_collection_import_export` | Enable Settings import/export UI |

See `UITestSupport.swift` and `UITestLaunch` in UI test target.

---

## When changing the puzzle model

1. Update `Puzzle`, `PuzzleRecord` (`init(from:)`, `apply(from:)`, `toPuzzle()`).
2. Update `getDataFields()` / `fromData(_:)` if export/serialization fields change (used for JSON/export tests — **not** Firestore).
3. Add/update tests: `PuzzleSerializationTests`, `PuzzlePersistenceTests`.
4. Update [docs/features.md](docs/features.md) field tables if user-visible.

SwiftData schema changes may require migration planning — none implemented yet.

---

## Documentation maintenance

Update docs when you change:

- Analytics/Crashlytics allowlists → `docs/telemetry.md`, `docs/analytics.md`
- Architecture or navigation → `docs/architecture.md`
- Feature flags → `ProductService.swift`, `docs/feature-inventory.md`, `docs/features.md`
- Firebase Console steps → `docs/firebase-setup.md`
- Shipped vs planned scope → `docs/feature-inventory.md`, `docs/agent-build-checklist.md` progress log

Set **Last updated** dates on files you touch.

---

## Anti-patterns (avoid)

- Re-adding Firebase Auth, Firestore, or Messaging without spec + user approval
- Committing `GoogleService-Info.plist`
- Using `print()` in app code (SwiftLint `no_print_statements`)
- Logging PII even if redaction would strip it
- Editing generated `.xcodeproj` instead of `project.yml`
- Assuming login/cloud sync docs in old commits still apply — check this file and `docs/architecture.md`
