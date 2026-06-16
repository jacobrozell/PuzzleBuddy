# Analytics and logging

Puzzle Buddy uses a single logging API (`AppLog`) that writes to Apple's unified logging system and optionally forwards privacy-safe events to Firebase Analytics.

## Design goals

1. **One API** — developers call `AppLog.shared`, not `Analytics.logEvent` directly
2. **Allowlist only** — unknown event names never reach Firebase
3. **No PII** — emails, UIDs, passwords, and display names are blocked from metadata
4. **CI-safe** — Analytics disabled when Firebase is not configured or when launch argument is set

## Usage

```swift
AppLog.shared.info(
    .puzzles,
    eventName: "puzzle_added",
    message: "Puzzle saved.",
    metadata: ["puzzle_status": puzzle.status.rawValue]
)

AppLog.shared.warning(.auth, eventName: "auth_failed", message: error.localizedDescription)
AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
AppLog.shared.debug(.ui, eventName: "screen_appeared", message: "Detail opened.")  // DEBUG only to Analytics threshold
```

### Log levels

| Level | os.log | Firebase Analytics |
|-------|--------|-------------------|
| `debug` | Yes (DEBUG min level) | No |
| `info` | Yes | Yes, if allowlisted |
| `warning` | Yes | Yes, if allowlisted |
| `error` | Yes | Yes, if allowlisted |

Release builds use minimum level `.info`; debug builds use `.debug`.

### Categories

| `LogCategory` | Use for |
|---------------|---------|
| `.app` | Launch, bootstrap, push registration |
| `.auth` | Sign-in, sign-out, account creation, profile sync |
| `.puzzles` | CRUD and sync |
| `.ui` | Screen-level events (if added) |

## Allowlisted events

Defined in `PuzzleAnalyticsEventMapping.allowlistedEvents`:

| Event name | Firebase name | When fired |
|------------|---------------|------------|
| `app_bootstrap_ready` | `app_open` | App launch task completes |
| `user_signed_in` | same | Email sign-in success |
| `user_signed_out` | same | Sign out |
| `user_account_created` | same | Email registration |
| `user_profile_updated` | same | Firestore user doc update |
| `puzzle_list_refreshed` | same | Local SwiftData load or Firestore fetch completes |
| `puzzle_added` | same | Puzzle saved (local or Firestore) |
| `puzzle_updated` | same | Puzzle updated (local or Firestore) |
| `puzzle_deleted` | same | Delete success |
| `puzzle_sync_failed` | same | SwiftData or Firestore errors |
| `auth_failed` | same | Auth errors at launch |

Events **not** in this set are logged locally only (if level permits) and are never sent to Firebase.

## Allowlisted parameters

Only these metadata keys are forwarded (max 100 characters each):

- `app_version` — auto-injected from `Puzzle_BuddyApp.version`
- `log_category` — auto-injected from `LogCategory`
- `auth_provider` — e.g. `"email"`
- `puzzle_count` — stringified count after fetch
- `puzzle_status` — `To-Do` or `Completed`

`app_version` and `log_category` are always set on mapped events.

## Redaction

`LogRedaction` removes metadata keys whose lowercase name matches:

`email`, `uid`, `password`, `token`, `name`, `displayName`

Do not attempt to log these fields — they will be stripped before Analytics and should not appear in intentional telemetry.

## Bootstrap gating

Analytics collection requires all of:

1. `FirebaseBootstrap.shouldConfigure` — valid `GoogleService-Info.plist`
2. `FirebaseBootstrap.isAnalyticsCollectionEnabled` — launch args do not include `-disable_firebase_analytics`
3. Log level ≥ `.info`
4. Event and parameters pass allowlist mapping

## Adding a new analytics event

1. Choose a descriptive snake_case `eventName`
2. Add the name to `allowlistedEvents` in `AppLogging.swift`
3. If you need new parameters, add keys to `allowlistedParameterKeys` only when they contain no PII
4. Call `AppLog.shared.info` (or warning/error) from the appropriate code path
5. Document the event in this file

Example — adding a settings export event:

```swift
// AppLogging.swift — allowlistedEvents
"settings_data_exported"

// SettingsView.swift
AppLog.shared.info(.ui, eventName: "settings_data_exported", message: "User exported data.")
```

## What not to do

```swift
// BAD — direct Analytics bypasses allowlist and review
Analytics.logEvent("button_tap", parameters: ["screen": "home"])

// BAD — PII in metadata (will be redacted, but don't rely on that)
AppLog.shared.info(.auth, eventName: "user_signed_in", message: "OK", metadata: ["email": user.email])

// BAD — print in production code (SwiftLint warning)
print("User logged in: \(user.email)")
```

Use `AppLog` with allowlisted events and safe metadata only.

## Inspecting events

### Xcode debug console

`DefaultAppLogger` writes to `Logger(subsystem: "com.jacobrozell.Puzzle-Buddy", category: "app")`.

### Firebase DebugView

1. In Xcode scheme, add launch argument `-FIRAnalyticsDebugEnabled` (Firebase SDK debug mode)
2. Open Firebase Console → Analytics → DebugView
3. Run the app on simulator or device

Remove debug flags before release builds.

## Relationship to Crashlytics

Crashlytics is integrated alongside Analytics. `DefaultAppLogger` forwards:

| Level | Crashlytics action |
|-------|-------------------|
| `warning` | `Crashlytics.crashlytics().log(...)` |
| `error` | Log line + `record(error:)` as a non-fatal |

Crashlytics only runs when `FirebaseBootstrap.shouldConfigure` is true and the app is not under test (`UITestSupport.isRunningUnderTest`). Follow the same PII rules as Analytics — no emails, UIDs, or display names in log messages.

dSYM upload is configured via a post-build run script in `project.yml` for symbolicated crash reports.
