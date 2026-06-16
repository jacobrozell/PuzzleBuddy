# Core Features

This document describes every major feature in Puzzle Buddy as shipped in version **1.0**, including user-facing behavior, data semantics, and how each feature is implemented. For architecture and file layout, see [architecture.md](architecture.md).

## Product overview

Puzzle Buddy is a native iOS app for jigsaw puzzle enthusiasts who want a personal catalog of puzzles they have completed or plan to finish. The app answers three questions for each puzzle:

1. **What is it?** — name, piece count, photo
2. **How was it?** — star rating, difficulty, time spent
3. **Where is it in my journey?** — To-Do, In-Progress, or Completed, plus completion date

Planned product work — **find & organize** (search, status tabs, custom tags, pick-next), collection stats polish, richer metadata, and competitive positioning vs. [Puzzle Tracker](https://apps.apple.com/us/app/puzzle-tracker/id1561473799) — is documented in [roadmap.md](roadmap.md#find--organize--user-driven-product-strategy).

Version 1.0 is **local-first**: all puzzle data lives on device via SwiftData. No account is required to use the app. Firebase provides Analytics and Crashlytics only; authentication and cloud sync are implemented but disabled behind a feature flag (see [roadmap.md](roadmap.md)).

---

## App launch and first-run experience

### Splash screen

On every cold launch, the app shows a branded splash (`SplashView`) before routing to onboarding or the main experience.

| Element | Behavior |
|---------|----------|
| Brand crest | Animated pulse ring when Reduce Motion is off; static when Reduce Motion is on |
| Tagline | "Log · Track · Complete" |
| Loading indicator | Appears after a short fade-in with caption "Piecing things together…" |
| Accessibility | Splash is a single container with header trait on app name; loading progress view has `A11yID.splashLoading` |

The splash bridges the system launch screen (`LaunchScreen.storyboard`) and app initialization (SwiftData container, Firebase bootstrap, auth provider).

### Onboarding

First-time users see a four-page onboarding carousel (`OnboardingView`) stored in `UserDefaults` under `PuzzleBuddy.OnboardingComplete`. A legacy key (`PuzzlePal_Onboarding_Complete`) is also checked for users upgrading from an earlier build.

| Page | Title | Message |
|------|-------|---------|
| 1 | Welcome to Puzzle Buddy | Personal jigsaw catalog — track every box on your shelf |
| 2 | Build Your Collection | Log piece counts, ratings, difficulty, and status |
| 3 | Capture the Moment | Attach photos from camera or library |
| 4 | Ready to Puzzle? | Everything stays on device — no account needed |

Navigation:

- **Skip** (page 1) or **Back** / **Next** on subsequent pages
- **Get Started** on the final page marks onboarding complete and dismisses the flow
- Completing onboarding logs `onboarding_completed` to Analytics (allowlisted)

Onboarding is skipped automatically during UI tests (`UITestSupport.isRunningUnderTest`).

### Root routing

`RootView` decides what the user sees after splash/onboarding:

```
Onboarding incomplete → OnboardingView
Login enabled         → LoginView
Default (1.0)         → PuzzleView (local SwiftData)
```

See [architecture.md](architecture.md#feature-flags-productservice) for how `ProductService.isLoginEnabled` is controlled.

---

## Puzzle catalog

The catalog is the heart of the app. Users browse, add, edit, and delete puzzles from a scrollable list with a floating add button.

### Puzzle list (`PuzzleList`)

| Capability | Details |
|------------|---------|
| Display | One row per puzzle via `PuzzleCell`; sorted by completion date (newest first) |
| Status filter | Segmented control: **To-Do**, **In-Progress**, **Completed**, **All** (default All) |
| Search | Text field below status filter; matches puzzle name (case-insensitive) |
| Sort | Toolbar menu: date (newest first), rating, difficulty, piece count (descending) |
| Add | Floating `+` button opens `PuzzleForm` as a sheet |
| Delete | Swipe-to-delete removes puzzles from SwiftData (and Firestore when cloud sync is on) |
| Refresh | Pull-to-refresh re-fetches from SwiftData or Firestore |
| Empty state | List renders empty until first puzzle is added; `fetchPuzzles()` runs on appear |
| Layout | Card-style rows with circular thumbnail, name, piece count, and completion date |
| Adaptive layout | Rows stack vertically at large Dynamic Type sizes or compact vertical size class |

Each row is a `NavigationLink` to `PuzzleDetail`. VoiceOver reads a combined label: name, piece count, rating (when set), status, and completion date.

### Puzzle row (`PuzzleCell`)

Visual summary shown in the list:

- **Thumbnail** — circular crop of attached photo, or puzzle-piece SF Symbol placeholder
- **Name** — headline, up to 3 lines, capitalized
- **Rating** — read-only `RatingsView` star summary when rating is set; hidden for unrated puzzles
- **Metadata** — piece count and completion date in footnote style

Rows use `brandCardSurface()` styling and adapt between horizontal and stacked layouts.

### Puzzle detail (`PuzzleDetail`)

Read-only detail view with inline edit mode toggled from the navigation bar.

**Read mode** (`DetailView`):

| Section | Content |
|---------|---------|
| Summary panel | Photo (or placeholder), name, star rating (if set), difficulty (if set) |
| Stats panel | Status, completion date, time spent, piece count, puzzle pace, pace per 1,000 pieces (when data allows) |

**Edit mode** reuses `PuzzleFormInternal` inline. Tapping **Save** calls `PuzzleStore.update(puzzle:)` and returns to read mode.

**Adaptive layout**: On iPad or wide iPhone landscape, summary and stats panels appear side by side; otherwise they stack vertically.

### Stats and insights

#### Collection stats (`CollectionStatsView`)

A dedicated **Stats** tab shows collection-wide aggregates computed from existing puzzle fields — no extra schema or account required.

| Stat | Source | Display |
|------|--------|---------|
| Puzzles completed | `status == Completed` | Hero card |
| Total pieces assembled | Sum of `pieces` (completed) | Hero card |
| Backlog size | `status == To-Do` | "On your shelf" |
| Average rating | Mean of `rating` (completed, non-zero) | Shown when any rated completions exist |
| Go-to piece count | Mode of `pieces` (completed); median when all unique | Shown when completed puzzles have piece counts |
| Time at the table | Sum of `estimatedTimeSpent` (completed with hours and minutes set) | Friendly hours/minutes label |
| Finished this month / year | `completionDate` vs. current calendar period | "This year" section |
| Biggest / smallest completed | Max/min `pieces` (completed) | "Piece counts" section when applicable |

VoiceOver reads each card as a combined label (title + value + optional subtitle). UI tests target `A11yID.collectionStatsScreen` and hero card identifiers.

When the catalog is empty, hero cards show zeros and a short prompt encourages adding puzzles.

Logic lives in `CollectionStats.compute(from:)` (`CollectionStats.swift`) for unit testing without SwiftData.

#### Per-puzzle detail metrics

| Row | When shown |
|-----|------------|
| Status, completion date, time spent, piece count | When set on the puzzle |
| Puzzle pace | Time bucket — Quick finish / Weekend puzzle / Marathon project — when hours and minutes are both set |
| Pace | Hours (or minutes) per 1,000 pieces when piece count and full time estimate are set |

**Pieces per minute** was removed. Pace metrics live in `PuzzleDetailMetrics.swift` and only appear when time is fully entered (both hours and minutes), matching collection stats time aggregation.

#### Known gaps (planned)

Milestones, year-in-review, and widget are not implemented yet.

See [roadmap.md — Stats and collection insights](roadmap.md#stats-and-collection-insights) for the phased plan.

#### List and search (1.0)

`PuzzleList` includes status segments, name search, sort menu, and star ratings on rows when set.

---

The form is presented as a sheet for new puzzles or inline on the detail screen for edits.

#### Required and optional fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Name | Text | **Yes** | Submit disabled when empty |
| Pieces | Integer | No | Number pad keyboard |
| Status | Picker | No | `To-Do` (default), `In-Progress`, or `Completed` |
| Rating | Picker | No | 0 (N/A) through 5.0 in half-star steps |
| Difficulty | Picker | No | 0 (N/A) through 5 |
| Hours spent | Integer | No | Part of `PuzzleTime` |
| Minutes spent | Integer | No | Part of `PuzzleTime` |
| Completion date | Date picker | No | Graphical style; defaults to today |
| Photo | Image | No | Camera or photo library |

#### Rating scale

Ratings use half-star granularity:

```
0 (none), 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
```

Stored as `Double` (`Puzzle.Rating.rawValue`). The form and detail use the visual `RatingsView` half-star control; tap left/right halves of each star to set half-step ratings. VoiceOver can adjust with swipe up/down.

#### Difficulty scale

Difficulty is an integer 0–5 stored as a string enum (`"0"` through `"5"`). `0` displays as N/A.

#### Time spent

`Puzzle.PuzzleTime` holds optional hours and minutes. Serialized as `"2hr:30min"` for Firestore and split into `estimatedTimeHours` / `estimatedTimeMinutes` on `PuzzleRecord`.

#### Photo attachment (`ImagePickerView`)

| Action | Source | Presentation |
|--------|--------|----------------|
| Choose photo | Photo library | Sheet |
| Take photo | Camera | Full-screen cover |

Photos are stored as JPEG at **0.30 compression quality** in SwiftData (`@Attribute(.externalStorage)` on `imageData`). Camera usage requires the `NSCameraUsageDescription` Info.plist key.

The form **Submit** button calls `PuzzleStore.add(puzzle:)` and dismisses the sheet on success. Errors surface via `ErrorHandling` alert.

---

## Data model and persistence

### Puzzle (`PuzzleObject.swift`)

`Puzzle` is an `ObservableObject` used in SwiftUI bindings. Each puzzle has a stable `UUID` primary key.

### PuzzleRecord (SwiftData)

`PuzzleRecord` is the `@Model` persisted on device:

| Field | Swift type | Maps to |
|-------|------------|---------|
| `id` | `UUID` | Puzzle identity |
| `name` | `String` | Title |
| `pieces` | `Int?` | Piece count |
| `rating` | `Double` | `Rating.rawValue` |
| `difficulty` | `String` | `Difficulty.rawValue` |
| `estimatedTimeHours` | `Int?` | Hours component |
| `estimatedTimeMinutes` | `Int?` | Minutes component |
| `completionDate` | `Date` | When finished (or target date for To-Do) |
| `status` | `String` | `To-Do`, `In-Progress`, or `Completed` |
| `imageData` | `Data?` | JPEG bytes, external storage |

Conversion helpers:

- `PuzzleRecord(from:)` — create record from `Puzzle`
- `apply(from:)` — update record in place
- `toPuzzle()` — hydrate `Puzzle` for the UI

### PuzzleStore

`PuzzleStore` is the single source of truth for the puzzle array in memory.

| Operation | Local mode (1.0) | Cloud mode (future) |
|-----------|------------------|---------------------|
| `fetchPuzzles()` | `FetchDescriptor` sorted by `completionDate` desc | Firestore `getDocuments()` on `/users/{email}/puzzles` |
| `add(puzzle:)` | Insert `PuzzleRecord`, append to array | `setData` then local insert |
| `update(puzzle:)` | Find record by ID, `apply(from:)`, save | `updateData` then local update |
| `delete(at:)` | Delete records, remove from array | Firestore `delete` then local delete |

State machine: `idle` → `fetching` → `done` (cloud fetch only).

Analytics events fire on CRUD success and sync failure (`puzzle_added`, `puzzle_updated`, `puzzle_deleted`, `puzzle_list_refreshed`, `puzzle_sync_failed`).

---

## Navigation and shell

### Tab bar (`PuzzleTabbar`)

Three tabs inside a `NavigationStack`:

| Tab | Icon | Content |
|-----|------|---------|
| Puzzles | `list.bullet.circle.fill` | `PuzzleList` |
| Stats | `chart.bar.fill` | `CollectionStatsView` |
| Settings | `gearshape` | `SettingsView` |

Navigation title reflects the active tab ("Puzzle Buddy", "Collection Stats", or "Settings"). Brand background and accent tint applied globally.

### Settings (`SettingsView`)

| Section | 1.0 content | When login enabled |
|---------|-------------|-------------------|
| Account | Hidden | Sign Out button |
| Help & Legal | Privacy Policy, Support, Accessibility (GitHub Pages links) | Same |
| About | App version from `Puzzle_BuddyApp.version` | Same |

Legal URLs point to `https://jacobrozell.github.io/PuzzleBuddy/`.

---

## Authentication (implemented, disabled in 1.0)

Login code ships in the repository but is gated by `ProductService.isLoginEnabled` (default `false`). Launch with `-enable_login` to test locally.

When enabled, `RootView` presents `LoginView` instead of `PuzzleView` directly.

### Supported auth methods

| Method | Status | Implementation |
|--------|--------|----------------|
| Email / password sign-in | Ready | `FirebaseAuthProvider.login()` |
| Email / password registration | Ready | `createAccount(with:email:password:)` + Firestore user doc |
| Sign in with Apple | Ready | SHA-256 nonce + `OAuthProvider.credential` |
| Forgot password | Ready | `ForgotPasswordView` sends reset email |
| Apple account creation helper | Stubbed | `createAccountWithApple` is commented out |

### User profile (Firestore)

On sign-in, `updateUser()` writes to `/users/{email}`:

- `currentVersion` — app version string
- `lastLoggedIn` — server timestamp

Account creation also sets `username` from the registration form.

### Profile view (`ProfileView`)

Account management UI for signed-in users: email display, password reset, username change (`ChangeUsernameView`). Not wired into the main tab bar in 1.0; intended for the login release.

---

## Observability

### AppLog and Analytics

All telemetry goes through `AppLog.shared` — never call `Analytics.logEvent` directly.

| Principle | Implementation |
|-----------|----------------|
| Allowlist only | Unknown event names never reach Firebase |
| No PII | Email, UID, password, display name blocked from metadata |
| CI-safe | Analytics inactive when Firebase is not configured |

Allowlisted puzzle events: `puzzle_added`, `puzzle_updated`, `puzzle_deleted`, `puzzle_list_refreshed`, `puzzle_sync_failed`, `onboarding_completed`.

See [analytics.md](analytics.md) for the full event and parameter allowlist.

### Crashlytics

Warnings and errors are forwarded to Firebase Crashlytics as logs and non-fatal `record(error:)` calls. No PII in crash metadata.

### Firebase bootstrap

Firebase configures only when `GoogleService-Info.plist` exists and `GOOGLE_APP_ID` does not contain `REPLACE_WITH`. This lets CI and fresh clones build without a real Firebase project.

---

## Design system

Defined in `DesignTokens.swift`:

| Token group | Purpose |
|-------------|---------|
| `Brand` | Semantic colors — background, card, accent, text (light/dark adaptive) |
| `DS.Spacing` | Layout constants (`s2`–`s6`) |
| `DS.Radius` | Corner radii (`md`, etc.) |
| `BrandBackground` | Animated gradient; flat color when Reduce Motion is on |
| `BrandPrimaryButtonStyle` / `BrandSecondaryButtonStyle` | Capsule buttons |
| `A11yID` | Centralized accessibility identifiers for UI tests |

### Animations

- **Lottie** — onboarding and login hero animations (`LottieView.swift`)
- **Reduce Motion** — brand background and splash pulse respect `@Environment(\.accessibilityReduceMotion)`

### Adaptive layout

`AdaptiveLayout.swift` provides helpers for:

- Wide auth layout (iPad / landscape)
- Wide detail layout (side-by-side panels)
- Stacked row layout (large Dynamic Type)
- Tab bar clearance for floating add button

---

## Accessibility (current state)

Phase 1 accessibility work is complete. See [wcag.md](wcag.md) and [../accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) for the full conformance picture.

### Implemented today

| Area | Coverage |
|------|----------|
| VoiceOver labels | Login fields, puzzle form fields, list rows, detail rows, settings |
| Accessibility identifiers | `A11yID` on login, list, form, settings, onboarding, splash |
| Reduce Motion | Brand background, splash pulse |
| Dynamic Type | Adaptive row layouts in `PuzzleCell` and detail rows |
| Automated audits | `XCUIAccessibilityAudit` on login, list, settings, form |

### Known gaps (planned)

- Star rating and difficulty controls need richer VoiceOver value announcements on the form
- Image picker needs explicit accessibility labels (partially done)
- Localization not yet implemented
- Lottie animations need Reduce Motion static fallbacks

---

## Platform and permissions

| Requirement | Value |
|-------------|-------|
| iOS deployment target | 17.0+ (SwiftData) |
| Devices | iPhone and iPad |
| Camera | Required for "Take photo" — `NSCameraUsageDescription` |
| Photo library | Implicit via `UIImagePickerController` |
| Sign in with Apple | Entitlement present; active when login ships |
| Push notifications | FCM integrated in `AppDelegate`; not used for puzzle sync |

---

## Testing hooks

| Hook | Purpose |
|------|---------|
| `-enable_login` | Enable login UI and cloud sync path |
| `-ui_testing` / `UITestSupport` | Bypass auth, seed fixtures, skip onboarding |
| `auth.shouldBypassAccount` | UI test path straight to `PuzzleView` |
| Preview fixtures | `Puzzle.fixture()`, `PreviewSupport` for SwiftUI previews |

See [testing.md](testing.md) for CI and test suite details.

---

## Related documentation

| Document | Topic |
|----------|-------|
| [architecture.md](architecture.md) | Layers, dependencies, Firestore schema |
| [roadmap.md](roadmap.md) | Future releases and planned features |
| [firebase-setup.md](firebase-setup.md) | Firebase Console configuration |
| [analytics.md](analytics.md) | Logging and privacy rules |
| [wcag.md](wcag.md) | Accessibility conformance guide |
