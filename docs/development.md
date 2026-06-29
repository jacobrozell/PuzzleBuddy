# Local development

Guide for building, running, and debugging Puzzle Buddy on your machine.

**Agents:** [AGENTS.md](../AGENTS.md) · **Telemetry:** [telemetry.md](telemetry.md)

---

## Initial setup

### 1. Clone the repository

```bash
git clone git@github.com:jacobrozell/PuzzleBuddy.git
cd PuzzleBuddy
```

### 2. Install tooling

| Tool | Install | Purpose |
|------|---------|---------|
| Xcode 16+ | Mac App Store | Build and run |
| XcodeGen | `brew install xcodegen` | Generate `.xcodeproj` |
| SwiftLint | `brew install swiftlint` | Lint locally (CI uses container) |

### 3. Firebase configuration

```bash
cp GoogleService-Info.plist.example GoogleService-Info.plist
```

Replace placeholder values for local Analytics/Crashlytics testing, or leave placeholders for SwiftData-only runs. See [firebase-setup.md](firebase-setup.md).

### 4. Generate Xcode project

```bash
xcodegen generate
open PuzzleBuddy.xcodeproj
```

Run this after every pull that changes `project.yml` or when adding files outside existing source globs.

### 5. Git hooks

```bash
./Scripts/install-git-hooks.sh
```

Prevents committing `GoogleService-Info.plist`.

---

## Running the app

### Xcode

1. Scheme: **Puzzle Buddy**
2. Destination: any iOS 17+ Simulator or device
3. ⌘R to run, ⌘U to test

### Command line build

```bash
xcodegen generate

xcodebuild build \
  -project "PuzzleBuddy.xcodeproj" \
  -scheme PuzzleBuddy \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### Command line tests

```bash
xcodebuild build-for-testing \
  -project "PuzzleBuddy.xcodeproj" \
  -scheme PuzzleBuddy \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```

---

## Project maintenance

### Adding source files

Files under `App/` are included automatically via `project.yml`. For new top-level folders or targets, edit `project.yml` and run `xcodegen generate`.

### Adding Swift packages

Edit `project.yml` under `packages:` and target `dependencies:`. Current Firebase products: `FirebaseCore`, `FirebaseAnalytics`, `FirebaseCrashlytics`.

### Changing bundle ID or version

In `project.yml`: `PRODUCT_BUNDLE_IDENTIFIER`, `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`.

Also update `PuzzleBuddyApp.version` in `PuzzleBuddyApp.swift` and Firebase iOS app registration if bundle ID changes.

---

## Debugging tips

### Firebase not initializing

If `FirebaseBootstrap.shouldConfigure` is false:

- `GoogleService-Info.plist` missing from bundle
- `GOOGLE_APP_ID` contains `REPLACE_WITH`

Expected for CI and fresh clones using the example plist.

### View logs

`AppLog` → subsystem `com.jacobrozell.Puzzle-Buddy`. Filter in Console.app or Xcode debug console.

### Disable Firebase Analytics / Crashlytics locally

Scheme → Run → Arguments:

```
-disable_firebase_analytics
```

### Force telemetry in Debug

```
-firebase_analytics_debug
```

Add `-FIRAnalyticsDebugEnabled` for Firebase DebugView.

### SwiftUI previews

Use `PreviewSupport.puzzleStore` or `PreviewSupport.modelContext`.

### UI tests with seeded data

```
-disable_firebase_analytics
-ui_testing_bypass_onboarding
-ui_testing_seed_puzzles
```

See `UITestSupport` and [testing.md](testing.md).

---

## Simulator notes

- **Camera:** limited on Simulator — use photo library for image tests
- **Barcode scan:** requires device with camera for live scanner

```bash
xcrun simctl list devices available
```

---

## Clean builds

```bash
rm -rf DerivedData
xcodegen generate
xcodebuild -resolvePackageDependencies \
  -project "PuzzleBuddy.xcodeproj" \
  -scheme PuzzleBuddy
```

---

## Reproduce CI locally

```bash
cp GoogleService-Info.plist.example GoogleService-Info.plist
brew install xcodegen
xcodegen generate
xcodebuild -resolvePackageDependencies -project "PuzzleBuddy.xcodeproj" -scheme PuzzleBuddy
swiftlint lint
Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```
