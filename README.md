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

### Puzzle catalog (1.0)

- **Statuses:** Wishlist, To-Do, In-Progress, Completed — with progress % and days puzzling on detail
- **Metadata:** name, brand (`source`), piece count, half-star rating, difficulty, time spent, tags, notes, missing-pieces flag, barcode
- **Photos:** cover image from camera or library (JPEG on device)
- **Find & organize:** status tabs, search (name/brand/barcode/tags), sort, piece-count / missing-pieces / needs-photo / tag filters
- **Pick my next puzzle:** random selector from backlog with tag and piece-count filters (dice toolbar button)
- **SwiftData** persistence — no account required

### Shopping & barcode

- Barcode scan for quick-add and **shopping duplicate-check** (offline)
- Optional UPC metadata lookup (Settings toggle; UPCitemdb)

### Collection stats

- Stats tab: completed count, pieces assembled, backlog, time at the table, top tags
- Share collage of collection or filtered list

### Gated for 1.1+ (implemented, off in 1.0)

| Feature | Flag | Dogfood launch arg |
|---------|------|-------------------|
| IPDb CSV import + JSON/CSV export | `isCollectionImportExportEnabled` | `-enable_collection_import_export` |
| Login + Firestore sync | `isLoginEnabled` | `-enable_login` |

### Authentication (1.1+)

Email/password, Sign in with Apple, forgot password, Firestore sync — see [docs/firebase-setup.md](docs/firebase-setup.md).

### Observability

- Allowlisted Firebase Analytics + Crashlytics (no PII)
- Firebase bootstrap guard for CI / fresh clones

### Accessibility

- WCAG 2.1 AA work in progress — VoiceOver labels, `A11yID`, Reduce Motion, automated `XCUIAccessibilityAudit`

### Roadmap

Post-1.0 plans: in-app timer, multi-photo gallery, purchase location, year/type, JSON restore — [FutureIdeas/backlog.md](FutureIdeas/backlog.md) and [docs/roadmap.md](docs/roadmap.md).

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
