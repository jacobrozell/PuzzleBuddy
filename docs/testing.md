# Testing

Puzzle Buddy uses XCTest for unit tests and XCUITest for UI automation. CI runs the full suite on every push and pull request.

**Last updated:** 2026-06-29

---

## Test targets

| Target | Path | Purpose |
|--------|------|---------|
| **AppTests** | `AppTests/` | Unit tests — models, store, telemetry mapping |
| **AppUITests** | `AppUITests/` | UI smoke, WCAG audits, accessibility |

Both wired in `project.yml` under the **Puzzle Buddy** scheme.

---

## Running tests

### Xcode

⌘U with scheme **Puzzle Buddy**.

### Command line (CI parity)

```bash
xcodegen generate
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

## Unit tests (highlights)

| File | Covers |
|------|--------|
| `PuzzleSerializationTests` | `PuzzleTime`, `getDataFields()`, `fromData(_:)` |
| `PuzzlePersistenceTests` | `PuzzleRecord` round-trip, `PuzzleStore` save/reload |
| `AppLoggingTests` | Analytics mapping, redaction, Crashlytics non-fatal codes |
| `AppTests` | App version, allowlist smoke, `ProductService` flags |
| `AccessibilityLabelTests` | `A11yID` contract |

When changing puzzle fields: extend serialization/persistence tests first.

When changing telemetry allowlists: update `AppLoggingTests` and [telemetry.md](telemetry.md).

---

## UI tests

### Launch arguments (`UITestLaunch`)

| Argument | Purpose |
|----------|---------|
| `-disable_firebase_analytics` | Disable Analytics + Crashlytics |
| `-ui_testing_bypass_onboarding` | Skip onboarding |
| `-ui_testing_seed_puzzles` | Insert demo puzzles |

Default UI test flow: puzzle list with seeded data — **no login screen** (auth removed from app).

### Key suites

| File | Purpose |
|------|---------|
| `PuzzleAccessibilityUITests` | WCAG audits on list, form, settings |
| `WCAGAccessibilitySupport` | `launchForBypassOnboarding`, audit helpers |

Login-screen UI tests were removed with auth code. VoiceOver script for login archived in [accessibility/wcag-2.1-aa/voiceover-scripts/login.md](../accessibility/wcag-2.1-aa/voiceover-scripts/login.md).

### Locating elements

Use `UITestA11yID` / app `A11yID` constants — avoid brittle label-only queries.

---

## Firebase in tests

CI uses `GoogleService-Info.plist.example` → Firebase does not configure. Tests must not depend on live Analytics or Crashlytics.

`UITestSupport.isRunningUnderTest` skips Firebase init in `AppDelegate`.

---

## Contributor expectations

| Change | Minimum testing |
|--------|-----------------|
| New `Puzzle` / `PuzzleRecord` field | `PuzzleSerializationTests` / `PuzzlePersistenceTests` |
| New primary control | `A11yID` + label or UI test |
| New Analytics event | Allowlist + `AppLoggingTests` + [telemetry.md](telemetry.md) |
| `ProductService` flag | `AppTests` + docs |

---

## CI

Workflow: `.github/workflows/ci.yml` — SwiftLint, example plist, `xcodegen`, build-for-testing, `Scripts/ci/run-tests.sh`.

Parallel testing disabled (`CI_PARALLEL_TESTING: NO`).

---

## Debugging failures

```bash
xcrun simctl list devices available   # pick valid simulator name
open TestResults.xcresult             # inspect failures
```

For flaky UI tests: increase timeouts, erase simulator, enable Reduce Motion.
