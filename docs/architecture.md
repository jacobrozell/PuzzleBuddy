# Architecture

This document describes how Puzzle Buddy is structured: app entry, feature flags, data persistence, UI navigation, and cross-cutting concerns.

## Release model (1.0)

Version **1.0** ships as a **local-first** app:

- Puzzles persist on device via **SwiftData** (`PuzzleRecord`)
- The app launches directly into the puzzle list — no sign-in required
- **Firebase Analytics** and **Crashlytics** are active when a valid `GoogleService-Info.plist` is present
- **Login and Firestore cloud sync** are implemented but **disabled** behind `ProductService.isLoginEnabled` for a future release

## High-level diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        Puzzle_BuddyApp                           │
│  @UIApplicationDelegateAdaptor(AppDelegate)                      │
│  @StateObject FirebaseAuthProvider                               │
│  .modelContainer(PuzzleRecord)                                   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
     ┌─────────────────┐           ┌─────────────────┐
     │   AppDelegate   │           │    RootView     │
     │ Firebase init   │           │ ProductService  │
     │ Crashlytics     │           │ routes UI       │
     │ Push / FCM      │           └────────┬────────┘
     └─────────────────┘                    │
                              ┌─────────────┴─────────────┐
                              ▼                           ▼
                     ┌─────────────────┐         ┌─────────────────┐
                     │   PuzzleView    │         │   LoginView     │
                     │  (default 1.0)  │         │ (login enabled) │
                     └────────┬────────┘         └────────┬────────┘
                              │                           │ signed in
                              └─────────────┬─────────────┘
                                            ▼
                                   ┌─────────────────┐
                                   │   PuzzleTabbar  │
                                   └────────┬────────┘
                                            │
                         ┌──────────────────┼──────────────────┐
                         ▼                  ▼                  ▼
                  ┌────────────┐    ┌────────────┐    ┌────────────┐
                  │ PuzzleList │    │ PuzzleForm │    │ Settings   │
                  │ PuzzleCell │    │ PuzzleDetail│   │ View       │
                  └─────┬──────┘    └────────────┘    └────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │ PuzzleStore │
                 └──────┬──────┘
                        │
           ┌────────────┴────────────┐
           ▼                         ▼
    ┌──────────────┐         ┌──────────────┐
    │  SwiftData   │         │  Firestore   │
    │ PuzzleRecord │         │ (login only) │
    └──────────────┘         └──────────────┘
```

## App entry and lifecycle

### `Puzzle_BuddyApp`

The `@main` app struct:

1. Adapts `AppDelegate` for Firebase, Crashlytics, and push notification setup
2. Creates a shared `ModelContainer` for `PuzzleRecord` (SwiftData)
3. Creates a single `FirebaseAuthProvider` as `@StateObject`
4. Presents `RootView` with `.withErrorHandling()` and `.environmentObject(authProvider)`

`RootView` checks `ProductService.isLoginEnabled`:

- **`false` (1.0 default):** `PuzzleView` — local SwiftData storage
- **`true` (future):** `LoginView` — auth gate, then `PuzzleView(user:)` with Firestore sync

When login is enabled, launch restores `Auth.auth().currentUser` and calls `updateUser()` to sync profile metadata to Firestore.

App version is defined as `Puzzle_BuddyApp.version` (used by analytics and user profile updates).

### `AppDelegate`

- Configures Firebase only when `FirebaseBootstrap.shouldConfigure` is true (valid, non-placeholder plist)
- Enables Crashlytics collection after `FirebaseApp.configure()`
- Registers for remote notifications and wires Firebase Cloud Messaging delegates
- Sets `FirebaseAppDelegateProxyEnabled` to `false` in Info.plist — the app manages delegates explicitly

## Feature flags (`ProductService`)

| Flag | 1.0 default | Purpose |
|------|-------------|---------|
| `isLoginEnabled` | `false` | Show login UI and enable account features |
| `isCloudSyncEnabled` | `false` | `isLoginEnabled && FirebaseBootstrap.shouldConfigure` — Firestore sync |

To test login locally, launch with `-enable_login` or set `isLoginEnabled` to return `true` in `ProductService.swift`. Remote Config can replace the static flag when login ships.

## Authentication layer (gated)

Login code remains in the repo but is not active in 1.0.

### `FirebaseAuthProvider`

`@MainActor` `ObservableObject` centralizing auth state:

| Method | Purpose |
|--------|---------|
| `login()` | Email/password sign-in |
| `createAccount(with:email:password:)` | Creates Auth user + `/users/{email}` Firestore doc |
| `updateUser()` | Updates `currentVersion` and `lastLoggedIn` on user doc |
| `logout()` | Signs out and clears `user` |
| `startSignInWithAppleFlow` / `signInWithAppleCompletion` | Apple Sign In with SHA-256 nonce |

Published state:

- `user: FirebaseAuth.User?` — drives navigation after login (when enabled)
- `login`, `password`, `displayName` — form bindings
- `shouldBypassAccount` — UI-test bypass for puzzle UI without auth

### Auth views (`Login/`)

- `LoginView` — auth gate when `ProductService.isLoginEnabled`; routes to `PuzzleView` or account creation
- `CreateAccount` — registration form
- `ForgotPasswordView` — password reset email

Sign in with Apple uses `AuthenticationServices` with Firebase `OAuthProvider.credential`.

## Data layer

### `Puzzle` model

`ObservableObject` representing one puzzle in the UI. Key nested types:

| Type | Values | Storage |
|------|--------|---------|
| `Rating` | 0, 1, 1.5, … 5 (half stars) | `Double` |
| `Difficulty` | 0–5 as string enum | `String` |
| `Status` | `To-Do`, `In-Progress`, `Completed` | `String` |
| `PuzzleTime` | hours + minutes | Serialized as `"2hr:30min"` |

Images are JPEG-compressed (0.30 quality).

Serialization:

- **To SwiftData:** `PuzzleRecord(from:)` / `apply(from:)`
- **To Firestore:** `getDataFields() -> [String: Any]` (when cloud sync is enabled)
- **From Firestore:** `Puzzle.fromData(_:)` (handles `Timestamp` for dates)

### `PuzzleRecord` (SwiftData)

`@Model` class persisted on device:

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UUID` | Unique key |
| `name` | `String` | Puzzle title |
| `pieces` | `Int?` | Piece count |
| `rating` | `Double` | `Rating.rawValue` |
| `difficulty` | `String` | `Difficulty.rawValue` |
| `estimatedTimeHours` / `estimatedTimeMinutes` | `Int?` | Time spent |
| `completionDate` | `Date` | |
| `status` | `String` | `To-Do`, `In-Progress`, or `Completed` |
| `imageData` | `Data?` | JPEG bytes (`@Attribute(.externalStorage)`) |

**Planned extensions** (not in schema yet): tags, brand, start date, disposition, missing-pieces flag, material, purchase location, progress photos, and additional status values (`Wishlist`, `Abandoned`). See [roadmap.md — Puzzle model extensions](roadmap.md#puzzle-model-extensions).

### `PuzzleStore`

`@MainActor` `ObservableObject` managing the puzzle collection:

| State | Meaning |
|-------|---------|
| `idle` | Not currently fetching |
| `fetching` | Cloud `getDocuments()` in flight |
| `done` | Load completed (success or handled error) |

**Local mode (1.0 default):** `fetchPuzzles()` loads from SwiftData. `add`, `update`, and `delete` read/write `PuzzleRecord` via `ModelContext`.

**Cloud mode (login enabled + signed in):** Firestore path `/users/{email}/puzzles`. Same CRUD operations sync to Firestore when `ProductService.isCloudSyncEnabled` is true.

Operations:

- `fetchPuzzles()` — load from SwiftData or Firestore
- `add(puzzle:)` — insert locally and/or `setData` with document ID = `puzzle.id.uuidString`
- `update(puzzle:)` — update local record and/or `updateData`
- `delete(at:)` — remove local records and/or Firestore documents

### Firestore schema (future cloud sync)

**Collection:** `users/{userId}`

| Field | Type | Notes |
|-------|------|-------|
| `username` | string | Set on account creation |
| `currentVersion` | string | App version on login |
| `lastLoggedIn` | timestamp | Updated on each session |

**Subcollection:** `users/{userId}/puzzles/{puzzleId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | UUID string (duplicate of doc ID) |
| `name` | string | Puzzle title |
| `pieces` | int or `"nil"` | Piece count |
| `rating` | double | `Rating.rawValue` |
| `difficulty` | string | `Difficulty.rawValue` |
| `estimatedTimeSpent` | string | e.g. `"2hr:30min"` or `"nil"` |
| `completionDate` | timestamp | |
| `status` | string | `To-Do`, `In-Progress`, or `Completed` |
| `imageData` | string | Base64 JPEG or `"nil"` |

Security rules (`firestore.rules`) require `request.auth.token.email == userId` for all access.

## UI layer

### Navigation

`PuzzleView` owns a `PuzzleStore` (injected with `ModelContext`) and embeds `PuzzleTabbar`:

- **Puzzles tab** — `PuzzleList` with navigation to `PuzzleDetail` / `PuzzleForm`
- **Stats tab** — `CollectionStatsView` (collection aggregates from `CollectionStats.compute`)
- **Settings tab** — `SettingsView` (sign out when login enabled, app info, legal links)

`PuzzleView` calls `fetchPuzzles()` in `.task` when the local array is empty.

### Key views

| View | Responsibility |
|------|----------------|
| `RootView` | Routes between local app and login based on `ProductService` |
| `PuzzleList` | List of `PuzzleCell` rows, status filter, search, sort menu, add button, swipe delete |
| `CollectionStatsView` | Collection-wide stats hero cards and summary grid |
| `PuzzleCell` | Row summary (name, pieces, rating stars, thumbnail) |
| `PuzzleForm` | Create/edit puzzle fields |
| `PuzzleDetail` | Read-only detail with edit entry point; derived pace metrics via `PuzzleDetailMetrics` |
| `DifficultyView` | 1–5 difficulty picker |
| `RatingsView` | Editable half-star rating control (form); read-only on detail and list rows |
| `SettingsView` | Account (when login enabled) and legal links |
| `ImagePicker` | Camera / photo library wrapper |

### Design system

`DesignTokens.swift` defines:

- **`Brand`** — semantic colors (background, card, accent, text) with light/dark dynamic pairs where needed
- **`DS.Spacing` / `DS.Radius`** — layout constants
- **`BrandBackground`** — gradient with Reduce Motion fallback
- **`BrandPrimaryButtonStyle`** — capsule primary button
- **`A11yID`** — centralized accessibility identifiers for UI tests

### Error handling

`ErrorHandling` is a `@MainActor` `ObservableObject` attached at the app root via `withErrorHandling()`. Views call `eh.handle(error:title:)` to show a SwiftUI `Alert` without blocking nested alerts.

## Cross-cutting concerns

### Logging (`AppLogging.swift`)

- `AppLog.shared` implements `AppLogger`
- Debug builds log at `.debug`; release at `.info`
- Firebase Analytics receives only allowlisted events at info level and above
- Warnings and errors are also forwarded to **Crashlytics** (logs + non-fatal `record(error:)`)

See [analytics.md](analytics.md).

### Firebase bootstrap

`FirebaseBootstrap.shouldConfigure` checks that `GoogleService-Info.plist` exists and `GOOGLE_APP_ID` does not contain `REPLACE_WITH`. This allows CI and fresh clones to build without a real Firebase project. When false, Analytics and Crashlytics are inactive but SwiftData still works.

### Push notifications

FCM is integrated in `AppDelegate` but puzzle sync does not depend on push. Token updates post to `NotificationCenter` name `FCMToken`.

## Dependencies

| Package | Products used | Purpose |
|---------|---------------|---------|
| firebase-ios-sdk 11+ | Analytics, Auth, Crashlytics, Firestore, Messaging | Telemetry, future auth/sync, push |
| SwiftData | (system) | On-device puzzle persistence |

Declared in `project.yml`; resolved via Swift Package Manager in Xcode.

## Build configuration

- **Bundle ID:** `com.jacobrozell.Puzzle-Buddy`
- **Deployment target:** iOS 17.0 (SwiftData)
- **Devices:** iPhone and iPad (`TARGETED_DEVICE_FAMILY: 1,2`)
- **Entitlements:** Sign in with Apple (`Puzzle Buddy.entitlements`)
- **Info.plist keys:** Camera usage for puzzle photos; scene manifest generated
- **Crashlytics:** dSYM upload run script in `project.yml` post-build phase

## Future considerations

See [roadmap.md](roadmap.md) for the full release plan, accessibility phases, and model extensions. Highlights:

- Enable login by flipping `ProductService.isLoginEnabled` (or Remote Config)
- Migrate local SwiftData puzzles to Firestore on first sign-in (not yet implemented)
- `Puzzle` has commented fields for barcode, timer, notes, price
- `createAccountWithApple` is stubbed — Apple users rely on Firebase Auth user record after OAuth
- Image storage in Firestore documents may hit size limits for large photos — Cloud Storage would be a future migration path
