# Puzzle Buddy

Track your jigsaw puzzle collection — piece counts, ratings, difficulty, photos, and completion dates. Built with SwiftUI and SwiftData, with Firebase Analytics and Crashlytics.

**Status:** Pre-ship polish · v1.0.0 (2) · **Branch:** `main` · Local-first inaugural release

Puzzle Buddy is a native iOS app for puzzle enthusiasts who want a simple catalog of puzzles they've completed or plan to finish. Version **1.0.0** is local-only on device — no account. The app follows the same production patterns as [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy): privacy-safe analytics, design tokens, accessibility identifiers, XcodeGen, and GitHub Actions CI.

**Agents:** start with [AGENTS.md](AGENTS.md).

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

- Barcode scan for quick-add and **shopping duplicate-check** (offline; suggests details from your saved puzzles when available)

### Collection stats

- Stats tab: completed count, pieces assembled, backlog, time at the table, top tags
- Share collage of collection or filtered list

### Gated for dogfood (implemented, off in 1.0)

| Feature | Flag | Dogfood launch arg |
|---------|------|-------------------|
| IPDb CSV import + JSON/CSV export | `isCollectionImportExportEnabled` | `-enable_collection_import_export` |

### Observability

- Allowlisted Firebase Analytics + Crashlytics (no PII)
- Firebase bootstrap guard for CI / fresh clones

### Accessibility

- WCAG 2.1 AA work in progress — VoiceOver labels, `A11yID`, Reduce Motion, automated `XCUIAccessibilityAudit`

### Roadmap

Post-1.0 plans: see [`docs/implementation/1.0.0-expanded-feature-sprint.md`](docs/implementation/1.0.0-expanded-feature-sprint.md) (active), [`FutureIdeas/backlog.md`](FutureIdeas/backlog.md), [`docs/competitive-gap-analysis.md`](docs/competitive-gap-analysis.md).

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16+ |
| iOS deployment target | 17.0+ |
| Swift | 5.0 |
| macOS (for local builds) | macOS 15+ recommended (matches CI) |
| Firebase project | Analytics + Crashlytics only |
| Optional | [XcodeGen](https://github.com/yonaskolb/XcodeGen), [SwiftLint](https://github.com/realm/SwiftLint) |

## Quick start

### 1. Clone and configure Firebase

```bash
git clone git@github.com:jacobrozell/PuzzleBuddy.git
cd PuzzleBuddy
cp GoogleService-Info.plist.example GoogleService-Info.plist
```

Edit `GoogleService-Info.plist` with values from the [Firebase Console](https://console.firebase.google.com/) → Project settings → Your apps → iOS app. The bundle ID must be `com.jacobrozell.Puzzle-Buddy`.

For **1.0**, Firebase is used for Analytics and Crashlytics only. See [docs/firebase-setup.md](docs/firebase-setup.md).

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
│   ├── Login/                 # OnboardingView only (legacy folder name)
│   ├── Views/                 # SwiftUI screens (puzzle list, form, detail, settings)
│   ├── Helpers/               # Puzzle model, PuzzleRecord (SwiftData), PuzzleStore
│   └── Util/                  # ProductService, design tokens, logging, error handling
├── Puzzle BuddyTests/         # Unit tests
├── Puzzle BuddyUITests/       # UI tests
├── docs/                      # GitHub Pages + extended documentation
├── specs/                     # Feature specs (planned + shipped)
├── AGENTS.md                  # Agent onboarding (read first)
├── accessibility/             # WCAG roadmap and evidence
├── Scripts/                   # CI helpers and git hook installer
├── project.yml                # XcodeGen spec (source of truth for the project)
├── GoogleService-Info.plist.example
└── .github/workflows/ci.yml   # SwiftLint + build/test on push/PR
```

## Architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│  Puzzle_BuddyApp                                            │
│    ├── AppDelegate (Firebase Analytics + Crashlytics)     │
│    ├── ModelContainer (SwiftData / PuzzleRecord)            │
│    └── AppShell → RootView → PuzzleView                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  PuzzleView / PuzzleTabbar                                  │
│    └── PuzzleStore (@StateObject) → SwiftData only          │
└─────────────────────────────────────────────────────────────┘
```

- **SwiftUI** for all UI; `@MainActor` on `PuzzleStore` and `ErrorHandling`
- **SwiftData** for on-device persistence
- **ProductService** gates import/export and other staged features
- **Firebase** for Analytics and Crashlytics only
- **Puzzle** is an `ObservableObject`; **PuzzleRecord** is the SwiftData `@Model`
- **ErrorHandling** is injected via `.withErrorHandling()` at the app root

Full details: [docs/architecture.md](docs/architecture.md).

## Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | **Agent onboarding** — read first |
| [docs/agent-build-checklist.md](docs/agent-build-checklist.md) | Phased build checklist (0→Ship), progress log |
| [docs/feature-inventory.md](docs/feature-inventory.md) | Shipped vs partial vs planned |
| [docs/features.md](docs/features.md) | Core features — user flows and behavior |
| [docs/telemetry.md](docs/telemetry.md) | **Logging, Analytics, Crashlytics spec** (allowlists) |
| [docs/competitive-gap-analysis.md](docs/competitive-gap-analysis.md) | IPDb + Puzzle Tracker gaps vs 1.0 |
| [docs/roadmap.md](docs/roadmap.md) | Future releases and backlog |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Code style, PR checklist |
| [docs/development.md](docs/development.md) | Local setup, debugging |
| [docs/architecture.md](docs/architecture.md) | App layers, data model, navigation |
| [docs/firebase-setup.md](docs/firebase-setup.md) | Firebase Console, plist, Crashlytics |
| [docs/analytics.md](docs/analytics.md) | AppLog quick reference |
| [docs/testing.md](docs/testing.md) | Unit tests, UI tests, CI |
| [docs/wcag.md](docs/wcag.md) | WCAG 2.1 AA conformance guide (criteria, screens, testing) |
| [docs/README.md](docs/README.md) | GitHub Pages setup and public URLs |
| [accessibility/accessibility_todo.md](accessibility/accessibility_todo.md) | WCAG engineering roadmap |
| [accessibility/wcag-2.1-aa/conformance-matrix.md](accessibility/wcag-2.1-aa/conformance-matrix.md) | Per-criterion conformance status |

## Firebase & security

- Never commit `GoogleService-Info.plist` — use the example file for CI and keep real credentials local
- **1.0** uses Firebase for Analytics and Crashlytics only; puzzle data stays on device (SwiftData)

See [docs/firebase-setup.md](docs/firebase-setup.md) and [docs/telemetry.md](docs/telemetry.md).

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
