# Local development

Guide for building, running, and debugging Puzzle Buddy on your machine.

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
| Firebase CLI | `npm install -g firebase-tools` | Deploy Firestore rules |

### 3. Firebase configuration

```bash
cp GoogleService-Info.plist.example GoogleService-Info.plist
```

Replace placeholder values with your Firebase iOS app config, or download the plist from Firebase Console. See [firebase-setup.md](firebase-setup.md).

### 4. Generate Xcode project

```bash
xcodegen generate
open "Puzzle Buddy.xcodeproj"
```

Run this after every pull that changes `project.yml` or when adding files outside existing source globs.

### 5. Git hooks

```bash
./Scripts/install-git-hooks.sh
```

Prevents committing `GoogleService-Info.plist`.

## Running the app

### Xcode

1. Scheme: **Puzzle Buddy**
2. Destination: any iOS 17+ Simulator or device
3. ⌘R to run, ⌘U to test

### Command line build

```bash
xcodegen generate

xcodebuild build \
  -project "Puzzle Buddy.xcodeproj" \
  -scheme "Puzzle Buddy" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### Command line tests

```bash
# Build for testing first
xcodebuild build-for-testing \
  -project "Puzzle Buddy.xcodeproj" \
  -scheme "Puzzle Buddy" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Run tests (matches CI)
Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```

Environment variables used by `Scripts/ci/run-tests.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `CI_XCODE_PROJECT` | `Puzzle Buddy.xcodeproj` | Project path |
| `CI_XCODE_SCHEME` | `Puzzle Buddy` | Scheme name |
| `CI_PARALLEL_TESTING` | `NO` | Parallel test execution |
| `CI_XCODE_TEST_LOG` | `xcodebuild-test.log` | Test log file |

## Project maintenance

### Adding source files

Files under `Puzzle Buddy/` are included automatically via `project.yml`:

```yaml
sources:
  - path: Puzzle Buddy
    excludes:
      - "**/README.md"
```

For new top-level folders or targets, edit `project.yml` and run `xcodegen generate`.

### Adding Swift packages

Edit `project.yml` under `packages:` and target `dependencies:`, then regenerate. Example existing entries: Firebase, Lottie.

### Changing bundle ID or version

In `project.yml` under the `Puzzle Buddy` target `settings`:

- `PRODUCT_BUNDLE_IDENTIFIER`
- `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`

Also update Firebase iOS app registration if bundle ID changes.

## Debugging tips

### Firebase not initializing

Check Console for Firebase logs. If `FirebaseBootstrap.shouldConfigure` is false:

- `GoogleService-Info.plist` is missing from the bundle
- `GOOGLE_APP_ID` still contains `REPLACE_WITH`

### Firestore permission errors

Only applies when `ProductService.isLoginEnabled` is true and a user is signed in:

- Confirm user is signed in (`Auth.auth().currentUser`)
- Path must be `/users/{email}/puzzles` where `email` matches the token
- Deploy rules: `firebase deploy --only firestore:rules`

### View logs

`AppLog` writes to unified logging subsystem `com.jacobrozell.Puzzle-Buddy`. In Console.app, filter by subsystem or run from Xcode debug console.

Debug builds log at `.debug` level; release at `.info`.

### Disable Firebase Analytics locally

Xcode → Edit Scheme → Run → Arguments:

```
-disable_firebase_analytics
```

### SwiftUI previews

Previews are enabled (`ENABLE_PREVIEWS: YES`). Use `PreviewSupport.puzzleStore` or `PreviewSupport.modelContext` for in-memory SwiftData fixtures.

### Test login flow locally

Login is off by default in 1.0. To exercise auth UI:

Xcode → Edit Scheme → Run → Arguments → add `-enable_login`

Or test via UI tests using `UITestLaunch.loginArguments` (includes `-enable_login`).

### Test main app without login

Default launch goes straight to the puzzle list. For UI tests with seeded data:

```
-disable_firebase_analytics
-ui_testing_bypass_auth
-ui_testing_seed_puzzles
```

See `UITestSupport` and `UITestLaunch` for the full set.

## Simulator notes

- **Camera:** Simulator has limited camera support; use photo library for image tests
- **Sign in with Apple:** Works on Simulator with an Apple ID signed into Settings
- **Push notifications:** Use a physical device for full FCM testing

### Listing simulators

```bash
xcrun simctl list devices available
```

Use an available device name in `-destination`, e.g. `platform=iOS Simulator,name=iPhone 16`.

## DerivedData and clean builds

If packages or project generation act stale:

```bash
rm -rf DerivedData
xcodegen generate
xcodebuild -resolvePackageDependencies \
  -project "Puzzle Buddy.xcodeproj" \
  -scheme "Puzzle Buddy"
```

`DerivedData/` is gitignored.

## Local-only mode (1.0 default)

`ProductService.isLoginEnabled` is `false` for 1.0. The app uses SwiftData for persistence — no account or network required for puzzle CRUD.

`FirebaseAuthProvider.shouldBypassAccount` remains for UI tests (`-ui_testing_bypass_auth`) to skip the login gate when testing with `-enable_login`.

## Troubleshooting CI locally

Reproduce CI steps:

```bash
cp GoogleService-Info.plist.example GoogleService-Info.plist
brew install xcodegen
xcodegen generate
xcodebuild -resolvePackageDependencies -project "Puzzle Buddy.xcodeproj" -scheme "Puzzle Buddy"
swiftlint lint
Scripts/ci/run-tests.sh "platform=iOS Simulator,name=iPhone 16"
```

CI runs on `macos-15` with Xcode 16 and iPhone 16 Simulator — match when debugging CI-only failures.
