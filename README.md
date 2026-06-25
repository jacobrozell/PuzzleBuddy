# Puzzle Buddy

Track your jigsaw puzzle collection — piece counts, ratings, difficulty, photos, and completion dates. Built with SwiftUI and SwiftData, with Firebase Analytics and Crashlytics.

**Status:** Pre-ship polish · v1.0.0 (1) · **Branch:** `main` · Local-first 1.0 (login/cloud sync in 1.1+)

Puzzle Buddy is a native iOS app for puzzle enthusiasts who want a simple catalog of puzzles they've completed or plan to finish. Version **1.0.0** is the inaugural release — local-first on device; account sign-in and cloud sync ship in **1.1.0+** behind a feature flag. The app follows the same production patterns as [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy): privacy-safe analytics, design tokens, accessibility identifiers, XcodeGen, and GitHub Actions CI.

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Project structure](#project-structure)
- [Architecture overview](#architecture-overview)
- [Documentation](#documentation)
- [Firebase & security](#firebase--security)
- [CI/CD](#cicd)
- [Contributing](#contributing)
- [Legal & support](#legal--support)
- [Related apps](#related-apps)

## Features

### Puzzle catalog

- Add puzzles with name, piece count, star rating (0–5 in half-star steps), difficulty (1–5), estimated time spent, completion date, and status (To-Do / Completed)
- Attach a photo from the camera or photo library (stored as compressed JPEG on device)
- Browse puzzles in a tabbed list with detail and edit flows
- Delete puzzles with swipe-to-delete
- **SwiftData** persistence — puzzles survive app restarts with no account required

### Authentication (future release)

Login and cloud sync are implemented but **disabled for 1.0** via `ProductService.isLoginEnabled`. When enabled in a future release:

- Email and password sign-in and account creation
- Sign in with Apple (nonce-based OAuth flow via Firebase Auth)
- Forgot-password flow
- Firestore-backed sync scoped per user: `/users/{email}/puzzles/{puzzleId}`

Launch with `-enable_login` to test the login flow locally.

### Observability

- `AppLog` wrapper: structured os.log output plus allowlisted Firebase Analytics events
- **Firebase Crashlytics** for warnings and non-fatal errors (no PII)
- No PII (email, UID, password, display name) sent to Analytics — metadata keys are redacted before upload
- Firebase only configures when a real `GoogleService-Info.plist` is present (placeholder values are ignored)

### Polish

- Design tokens (`Brand`, `DS`) for colors, spacing, and button styles
- Brand gradient background with Reduce Motion support on splash and screens
- VoiceOver labels and `A11yID` identifiers for UI testing on key screens
- GitHub Pages site for App Store legal URLs (privacy, support, accessibility)

### Planned (see [docs/roadmap.md](docs/roadmap.md))

- **Collection stats** — totals for completed puzzles, pieces, hours, backlog, and period summaries (data already captured; UI not built)
- **Catalog polish** — status tabs, search/filter, ratings on list rows
- **Richer tracking** — In-Progress status, timer, barcode scan, tags, notes (phased; see roadmap)
- **Competitive positioning** — feature comparison and build priority vs. [Puzzle Tracker](https://apps.apple.com/us/app/puzzle-tracker/id1561473799)

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16+ |
| iOS deployment target | 17.0+ |
| Swift | 5.0 |
| macOS (for local builds) | macOS 15+ recommended (matches CI) |
| Firebase project | Analytics + Crashlytics (Auth + Firestore optional until login ships) |
| Optional | [XcodeGen](https://github.com/yonaskolb/XcodeGen), [SwiftLint](https://github.com/realm/SwiftLint), [Firebase CLI](https://firebase.google.com/docs/cli) |

## Quick start

### 1. Clone and configure Firebase

```bash
git clone git@github.com:jacobrozell/PuzzleBuddy.git
cd PuzzleBuddy
cp GoogleService-Info.plist.example GoogleService-Info.plist
```

Edit `GoogleService-Info.plist` with values from the [Firebase Console](https://console.firebase.google.com/) → Project settings → Your apps → iOS app. The bundle ID must be `com.jacobrozell.Puzzle-Buddy`.

For **1.0**, Firebase is used for Analytics and Crashlytics. Enable **Email/Password** and **Apple** sign-in providers under Authentication → Sign-in method when preparing the login release. See [docs/firebase-setup.md](docs/firebase-setup.md).

### 2. Generate the Xcode project

The `.xcodeproj` is generated from `project.yml` and is not committed.

```bash
brew install xcodegen   # if needed
xcodegen generate
open "Puzzle Buddy.xcodeproj"
```

### 3. Install git hooks

Blocks accidentally committing a real Firebase plist:

```bash
./Scripts/install-git-hooks.sh
```

### 4. Build and run

Select the **Puzzle Buddy** scheme, choose an iOS Simulator or device, and press ⌘R.

For CI-style verification locally:

```bash
swiftlint lint
Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```

See [docs/development.md](docs/development.md) for the full local workflow, simulator tips, and troubleshooting.

## Project structure

```
Puzzle-Buddy/
├── Puzzle Buddy/              # Main app target
│   ├── Login/                 # Auth views (gated by ProductService)
│   ├── Views/                 # SwiftUI screens (puzzle list, form, detail, settings)
│   ├── Helpers/               # Puzzle model, PuzzleRecord (SwiftData), PuzzleStore
│   └── Util/                  # ProductService, design tokens, logging, error handling
├── Puzzle BuddyTests/         # Unit tests
├── Puzzle BuddyUITests/       # UI tests
├── docs/                      # GitHub Pages + extended documentation
├── accessibility/             # WCAG roadmap and evidence
├── Scripts/                   # CI helpers and git hook installer
├── project.yml                # XcodeGen spec (source of truth for the project)
├── firestore.rules            # Firestore security rules
├── firebase.json              # Firebase CLI config
├── GoogleService-Info.plist.example
└── .github/workflows/ci.yml   # SwiftLint + build/test on push/PR
```

## Architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│  Puzzle_BuddyApp                                            │
│    ├── AppDelegate (Firebase, Crashlytics, push)            │
│    ├── ModelContainer (SwiftData / PuzzleRecord)            │
│    ├── FirebaseAuthProvider (@EnvironmentObject)            │
│    └── RootView → PuzzleView (1.0 default)                │
│              or LoginView → PuzzleView (login enabled)      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  PuzzleView / PuzzleTabbar                                  │
│    └── PuzzleStore (@StateObject)                           │
│          ├── SwiftData (1.0 default)                        │
│          └── Firestore: /users/{email}/puzzles (login)      │
└─────────────────────────────────────────────────────────────┘
```

- **SwiftUI** for all UI; `@MainActor` on store and auth types
- **SwiftData** for on-device persistence in 1.0
- **ProductService** gates login and Firestore cloud sync
- **Firebase** for Analytics and Crashlytics; Auth/Firestore when login ships
- **Puzzle** is an `ObservableObject`; **PuzzleRecord** is the SwiftData `@Model`
- **ErrorHandling** is injected via `.withErrorHandling()` at the app root

Full details: [docs/architecture.md](docs/architecture.md).

## Documentation

| Document | Description |
|----------|-------------|
| [docs/agent-build-checklist.md](docs/agent-build-checklist.md) | Phased build checklist (0→Ship), progress log, agent session template |
| [docs/feature-inventory.md](docs/feature-inventory.md) | Shipped vs partial vs planned — product reality register |
| [docs/features.md](docs/features.md) | Core features — user flows, data model, and behavior (verbose) |
| [docs/roadmap.md](docs/roadmap.md) | Future releases, stats plan, competitive analysis, accessibility phases, model extensions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Code style, PR checklist, conventions |
| [docs/development.md](docs/development.md) | Local setup, XcodeGen, debugging, common issues |
| [docs/architecture.md](docs/architecture.md) | App layers, data model, navigation, dependencies |
| [docs/firebase-setup.md](docs/firebase-setup.md) | Firebase project, Auth, Firestore, rules deployment |
| [docs/analytics.md](docs/analytics.md) | AppLog, Analytics allowlist, privacy guarantees |
| [docs/testing.md](docs/testing.md) | Unit tests, UI tests, CI test runner |
| [docs/wcag.md](docs/wcag.md) | WCAG 2.1 AA conformance guide (criteria, screens, testing) |
| [docs/README.md](docs/README.md) | GitHub Pages setup and public URLs |
| [accessibility/accessibility_todo.md](accessibility/accessibility_todo.md) | WCAG engineering roadmap |
| [accessibility/wcag-2.1-aa/conformance-matrix.md](accessibility/wcag-2.1-aa/conformance-matrix.md) | Per-criterion conformance status |

## Firebase & security

- Never commit `GoogleService-Info.plist` — use the example file for CI and keep real credentials local
- **1.0** uses Firebase for Analytics and Crashlytics only; puzzle data stays on device
- When login ships, deploy Firestore rules from the repo root:

```bash
firebase deploy --only firestore:rules
```

- Rules require `request.auth.token.email == userId` for all reads and writes under `/users/{userId}`

See [docs/firebase-setup.md](docs/firebase-setup.md) for step-by-step Firebase Console configuration.

## CI/CD

GitHub Actions runs on every push and pull request to `main`, `master`, and `dev`:

1. **SwiftLint** (Linux container) — style checks plus a guard that no real `GoogleService-Info.plist` is tracked
2. **Build & Test** (macOS 15) — copies the example plist, runs `xcodegen generate`, builds for testing, runs unit and UI tests on iPhone 16 Simulator

Workflow file: [.github/workflows/ci.yml](.github/workflows/ci.yml).

## Contributing

We welcome issues and pull requests. Read [CONTRIBUTING.md](CONTRIBUTING.md) for code style, testing expectations, and the PR checklist.

## Legal & support

Public pages (hosted on GitHub Pages from `/docs`):

- [Privacy policy](https://jacobrozell.github.io/PuzzleBuddy/privacy.html)
- [Support](https://jacobrozell.github.io/PuzzleBuddy/support.html)
- [Accessibility statement](https://jacobrozell.github.io/PuzzleBuddy/accessibility.html)

Setup instructions: [docs/README.md](docs/README.md).

## Related apps

Built with the same production patterns as [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy) — CI, analytics wrapper, design tokens, accessibility identifiers, and GitHub Pages.
