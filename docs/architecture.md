# Architecture

How Puzzle Buddy is structured: app entry, persistence, navigation, telemetry, and cross-cutting concerns.

**Last updated:** 2026-09-21 · **Agent guide:** [AGENTS.md](../AGENTS.md)

---

## Release model

Version **1.0** shipped as a **local-first** app; **1.1.0** continues on the same store shape:

- Puzzles persist on device via **SwiftData** (`PuzzleRecord` + photo/completion records)
- Schema versioning: [swiftdata-migrations.md](swiftdata-migrations.md) (`PuzzleSchemaV1` frozen at App Store 1.0.0)
- No sign-in — launch goes splash → onboarding (first run) → main tabs
- **Firebase Analytics + Crashlytics** when a valid `GoogleService-Info.plist` is present (Release by default)
- Auth, Firestore, and push were **removed** from the app (June 2026)

---

## High-level diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        PuzzleBuddyApp                           │
│  @UIApplicationDelegateAdaptor(AppDelegate)                      │
│  .modelContainer(PuzzleRecord)                                   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
     ┌─────────────────┐           ┌─────────────────┐
     │   AppDelegate   │           │    AppShell     │
     │ Firebase init   │           │ splash (optional)│
     │ Analytics +     │           └────────┬────────┘
     │ Crashlytics     │                    ▼
     └─────────────────┘           ┌─────────────────┐
                                   │    RootView     │
                                   │ onboarding OR   │
                                   │   PuzzleView    │
                                   └────────┬────────┘
                                            ▼
                                   ┌─────────────────┐
                                   │   PuzzleTabbar  │
                                   └────────┬────────┘
                         ┌──────────────────┼──────────────────┐
                         ▼                  ▼                  ▼
                  ┌────────────┐    ┌────────────┐    ┌────────────┐
                  │ PuzzleList │    │ Collection │    │ Settings   │
                  │ + detail   │    │ StatsView  │    │ View       │
                  └─────┬──────┘    └────────────┘    └────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │ PuzzleStore │
                 └──────┬──────┘
                        ▼
                 ┌──────────────┐
                 │  SwiftData   │
                 │ PuzzleRecord │
                 └──────────────┘
```

---

## App entry and lifecycle

### `PuzzleBuddyApp`

The `@main` app struct:

1. Adapts `AppDelegate` for Firebase bootstrap
2. Creates shared `ModelContainer` for `PuzzleRecord`
3. Presents `AppShell` with `.withErrorHandling()`
4. Applies appearance preference from `@AppStorage`

App version: `PuzzleBuddyApp.version` — keep in sync with `project.yml` `MARKETING_VERSION`.

### `AppShell`

- Shows branded `SplashView` on cold launch (~1.4s) unless UI testing
- Embeds `RootView`

### `RootView`

- First run: `OnboardingView` until `OnboardingStorage.isComplete`
- Otherwise: `PuzzleView`
- Logs `app_bootstrap_ready` on launch

### `AppDelegate`

When `FirebaseBootstrap.shouldConfigure && !UITestSupport.isRunningUnderTest`:

1. `FirebaseApp.configure()`
2. `Analytics.setAnalyticsCollectionEnabled(...)`
3. `Crashlytics.setCrashlyticsCollectionEnabled(...)`

`FirebaseAppDelegateProxyEnabled` is `false` — app manages configuration explicitly.

No push notification registration.

---

## Feature flags (`ProductService`)

| Flag | Default | Launch argument |
|------|---------|-----------------|
| `isBarcodeScanEnabled` | device has scanner | — |
| `isShoppingModeEnabled` | `true` | — |
| `isPickNextEnabled` | `true` | — |
| `isFriendsListEnabled` | `false` | — (Friends list UI stub; On loan uses FriendStore) |

There is no login, cloud sync, or Settings import/export flag. Collection import/export UI was removed in 1.1.0.

---

## Data layer

### `Puzzle` model

`ObservableObject` representing one puzzle in the UI.

| Type | Values | Storage |
|------|--------|---------|
| `Rating` | 0, 1, 1.5, … 5 (half stars) | `Double` |
| `Difficulty` | 0–5 | `String` enum |
| `Status` | Wishlist, To-Do, In-Progress, Completed, Abandoned | `String` |
| `PuzzleTime` | hours + minutes | `"2hr:30min"` string in export |

Images: JPEG compression (0.30 quality) in SwiftData external storage.

Serialization for **export/import tests** (not cloud):

- `getDataFields() -> [String: Any]`
- `Puzzle.fromData(_:)` — round-trip dictionary; dates as `Date`

### `PuzzleRecord` (SwiftData)

`@Model` persisted on device. Mirrors puzzle fields; see [features.md](features.md) for the full field list.

Also persisted: `PuzzlePhotoRecord`, `PuzzleCompletionRecord`.

**Versioning:** containers open via `PuzzleModelContainer` with `PuzzleSchemaV1` + `PuzzleMigrationPlan`. Policy and how to bump: [swiftdata-migrations.md](swiftdata-migrations.md).

### `PuzzleStore`

`@MainActor` `ObservableObject` — **SwiftData only**.

| State | Meaning |
|-------|---------|
| `idle` | Not loading |
| `fetching` | Load in progress |
| `done` | Load completed |

Operations:

- `fetchPuzzles()` → loads from SwiftData (`FetchDescriptor<PuzzleRecord>`)
- `add`, `update`, `delete` → local CRUD
- `importPuzzles`, `loadDemoPuzzles`, `clearAllPuzzles`, etc.

Init accepts `ModelContext` only (no user/sync parameters).

---

## UI layer

### Navigation

`PuzzleView` owns `PuzzleStore` and embeds `PuzzleTabbar`:

| Tab | View |
|-----|------|
| Puzzles | `PuzzleList` → detail / form |
| Stats | `CollectionStatsView` |
| Settings | `SettingsView` |

`PuzzleView.task` loads puzzles when empty (or seeds demo data for UI tests).

### Onboarding

`Login/OnboardingView.swift` — folder name is legacy; only onboarding remains.

### Design system

`DesignTokens.swift`: `Brand`, `DS`, `A11yID`, button styles.

### Error handling

`ErrorHandling` `@EnvironmentObject` at app root via `withErrorHandling()`.

---

## Observability

| Component | File |
|-----------|------|
| Logger API | `Util/AppLogging.swift` |
| Crashlytics mapping | `Util/FirebaseCrashlyticsEventMapping.swift` |
| Bootstrap flags | `FirebaseBootstrap` in `AppLogging.swift` |

Full allowlists and behavior: [telemetry.md](telemetry.md).

---

## UI testing support

`Util/UITestSupport.swift`:

| Check | Purpose |
|-------|---------|
| `isRunningUnderTest` | Skips Firebase configure; skips splash |
| `shouldSeedPuzzles` | Loads demo puzzles |
| `isBypassOnboardingEnabled` | Skips onboarding (`-ui_testing_bypass_onboarding`) |

Launch args documented in [testing.md](testing.md) and [AGENTS.md](../AGENTS.md).

---

## Dependencies

| Package | Products | Purpose |
|---------|----------|---------|
| firebase-ios-sdk 11+ | Core, Analytics, Crashlytics | Telemetry |
| SwiftData | (system) | On-device persistence |

Declared in `project.yml`; resolve via SPM.

---

## Build configuration

| Setting | Value |
|---------|-------|
| Bundle ID | `com.jacobrozell.Puzzle-Buddy` |
| Deployment target | iOS 17.0 |
| Devices | iPhone + iPad |
| Team | `7JT2JB89AV` |
| Entitlements | Empty (no Sign in with Apple / push) |
| Crashlytics | dSYM upload post-build script in `project.yml` |

---

## Future work

Account + cloud sync: [specs/planned/auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md) (not implemented).

Product roadmap: [roadmap.md](roadmap.md), [FutureIdeas/backlog.md](../FutureIdeas/backlog.md).

SwiftData: [swiftdata-migrations.md](swiftdata-migrations.md) — `PuzzleSchemaV1` / `PuzzleMigrationPlan`. Add a schema version + stage before breaking stored-property changes.
