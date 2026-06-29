# Telemetry specification

Authoritative reference for logging, Firebase Analytics, and Firebase Crashlytics in **Puzzle Buddy (iOS + Android)**.

**iOS implementation:** `App/Util/AppLogging.swift`, `App/Util/FirebaseCrashlyticsEventMapping.swift`, `App/AppDelegate.swift`

**Android implementation:** `PuzzleBuddy-Android/.../support/logging/` (`AppLogger.kt`, `FirebaseAnalyticsEventMapping.kt`, `FirebaseCrashlyticsEventMapping.kt`, `LogSinks.kt`), `FirebaseBootstrap.kt`, `PuzzleBuddyDatabaseFactory.kt`

**Cross-platform parity:** [`workspace/firebase-cross-platform-parity.md`](../../workspace/firebase-cross-platform-parity.md) · verify with `~/Desktop/personal/DaRules/scripts/check-firebase-parity.sh`

**Pattern:** Matches [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy) — single `AppLog` / `AppLogger` API, allowlisted remote events, Release-only collection by default.

**Last updated:** 2026-06-29

---

## Design goals

1. **One API** — feature code calls `AppLog.shared`, never Firebase SDKs directly
2. **Allowlist only** — unknown event names never reach Analytics
3. **No PII** — blocked metadata keys; Crashlytics breadcrumbs use `[category] eventName` only (no free-text messages)
4. **CI-safe** — placeholder `GoogleService-Info.plist` disables Firebase init
5. **Debug-quiet** — remote telemetry off in Debug builds unless explicitly opted in

---

## API usage

```swift
AppLog.shared.info(
    .puzzles,
    eventName: "puzzle_added",
    message: "Puzzle saved.",
    metadata: ["puzzle_status": puzzle.status.rawValue]
)

AppLog.shared.warning(.puzzles, eventName: "puzzle_load_failed", message: error.localizedDescription)
AppLog.shared.error(.puzzles, eventName: "puzzle_load_failed", message: error.localizedDescription)
AppLog.shared.debug(.ui, eventName: "screen_appeared", message: "Detail opened.")
```

### Log levels

| Level | os.log (Console) | Firebase Analytics | Crashlytics breadcrumb | Crashlytics non-fatal |
|-------|------------------|--------------------|-------------------------|------------------------|
| `debug` | Yes (Debug min level) | No | No | No |
| `info` | Yes | Yes, if allowlisted | Yes (`[cat] eventName`) | No |
| `warning` | Yes | Yes, if allowlisted | Yes | No |
| `error` | Yes | Yes, if allowlisted | Yes | Yes, if allowlisted event |

Release builds use minimum level `.info`; Debug builds use `.debug`.

### Categories (`LogCategory`)

| Category | Use for |
|----------|---------|
| `.app` | Launch, bootstrap, onboarding |
| `.puzzles` | CRUD, import, demo data, local load failures |
| `.ui` | Settings export, screen-level events |

---

## Firebase bootstrap

`FirebaseBootstrap` in `AppLogging.swift`:

| Property | When `true` |
|----------|-------------|
| `shouldConfigure` | Valid plist bundled; `GOOGLE_APP_ID` does not contain `REPLACE_WITH` |
| `isAnalyticsCollectionEnabled` | `shouldConfigure` + remote telemetry enabled |
| `isCrashlyticsCollectionEnabled` | Same as Analytics |

Remote telemetry enabled when:

- Not `-disable_firebase_analytics`
- **Release** build, **or** launch arg `-firebase_analytics_debug`
- Not `UITestSupport.isRunningUnderTest` (Crashlytics sink only; AppDelegate also skips `FirebaseApp.configure()` under UI test)

`AppDelegate` after `FirebaseApp.configure()`:

```swift
Analytics.setAnalyticsCollectionEnabled(FirebaseBootstrap.isAnalyticsCollectionEnabled)
Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(FirebaseBootstrap.isCrashlyticsCollectionEnabled)
```

### Launch arguments

| Argument | Effect |
|----------|--------|
| `-disable_firebase_analytics` | No Analytics or Crashlytics collection |
| `-firebase_analytics_debug` | Force collection on in Debug |
| `-FIRAnalyticsDebugEnabled` | Firebase SDK DebugView (scheme arg; not app logic) |

---

## Analytics allowlist

Defined in `PuzzleAnalyticsEventMapping.allowlistedEvents`:

| Event name | Firebase event name | Fired from | Notes |
|------------|----------------------|------------|-------|
| `app_bootstrap_ready` | `app_open` | `RootView` | App shell ready |
| `onboarding_completed` | same | `OnboardingView` | First-run carousel finished |
| `puzzle_list_refreshed` | same | `PuzzleStore.loadLocalPuzzles` | Local SwiftData load |
| `puzzle_added` | same | `PuzzleStore.addLocally` | |
| `puzzle_updated` | same | `PuzzleStore.update` | |
| `puzzle_deleted` | same | `PuzzleStore.delete` | |
| `puzzle_import_completed` | same | `PuzzleStore.importPuzzles` | IPDb/import path |
| `puzzle_backup_restored` | same | `PuzzleStore.restoreFromBackup` | JSON backup restore |
| `puzzle_load_failed` | same | `PuzzleStore` SwiftData fetch errors | Local-only |
| `puzzle_redo_started` | same | `PuzzleStore.startRedo` | User confirms redo |
| `puzzle_completion_recorded` | same | `PuzzleStore.recordCompletion` | New completion appended |
| `settings_collection_exported` | same | `SettingsView` | Gated by import/export flag |
| `shopping_scan_match` | same | `ShoppingModeView` | Duplicate found |
| `shopping_scan_no_match` | same | `ShoppingModeView` | No duplicate |
| `puzzle_status_changed` | same | `PuzzleStore.update` | Status field changed |
| `tab_selected` | same | `PuzzleTabbar` | Tab switch |
| `pick_next_puzzle_selected` | same | `PickNextPuzzleView` | Pick-next spin |
| `barcode_scan_completed` | same | List scan, shopping mode | Unified barcode outcome |
| `onboarding_skipped` | same | `OnboardingView` | Skip on page 1 (no `onboarding_completed`) |
| `demo_data_loaded` | same | `PuzzleStore.loadDemoPuzzles` | Demo collection loaded |
| `demo_data_removed` | same | `PuzzleStore.removeDemoPuzzles` | Demo collection removed |

Events **not** in this set are logged to os.log only (never sent to Firebase Analytics).

### Allowlisted parameters

Only these metadata keys are forwarded (max 100 chars each):

| Key | Source |
|-----|--------|
| `app_version` | Auto-injected from `PuzzleBuddyApp.version` |
| `log_category` | Auto-injected from `LogCategory` |
| `puzzle_count` | Call site |
| `puzzle_status` | Call site |
| `completion_number` | `puzzle_completion_recorded` |
| `completion_count` | `puzzle_redo_started` |
| `format` | Export format (`json`, `csv`, etc.) |
| `import_policy` | Import / restore |
| `add_source` | `puzzle_added` — `manual`, `barcode`, `import`, `demo` |
| `piece_count_bucket` | Puzzle metadata helper |
| `has_photo` | Puzzle metadata helper |
| `photo_count` | Puzzle metadata helper |
| `status_from` / `status_to` | `puzzle_status_changed` |
| `scan_context` / `scan_result` | `barcode_scan_completed` |
| `tab` | `tab_selected` |
| `entry_point` | `pick_next_puzzle_selected` |
| `page_index` | `onboarding_skipped` |
| `puzzle_type` | `puzzle_completion_recorded` |
| `difficulty` | `puzzle_completion_recorded` |
| `rating_bucket` | `puzzle_completion_recorded` |
| `has_missing_pieces` | `puzzle_completion_recorded` |

---

## Log-only events (not in Analytics allowlist)

These appear in Console / Crashlytics breadcrumbs but **not** as Analytics events:

| Event name | Level | Source |
|------------|-------|--------|
| `puzzle_collection_cleared` | info | `PuzzleStore.clearAllPuzzles` |
| `demo_data_seed_failed` | warning | `PuzzleStore` UI test seed |
| `model_container_load_failed` | warning | `PuzzleModelContainer` |
| `model_container_reset_failed` | warning | `PuzzleModelContainer` |

Promote to Analytics allowlist only with product approval.

---

## Crashlytics

### Breadcrumbs

At `.info` and above, when collection is enabled:

```text
[puzzles] puzzle_added
```

Format: `[category] eventName` — **no message body** (avoids leaking error descriptions).

### Non-fatal errors

Only allowlisted `.error` events become `Crashlytics.record(error:)` via `FirebaseCrashlyticsEventMapping`:

| Event name | Code | Typical cause |
|------------|------|---------------|
| `puzzle_load_failed` | 2001 | SwiftData fetch/save failure |
| `model_container_load_failed` | 2002 | ModelContainer creation failed |
| `model_container_reset_failed` | 2003 | Store recovery failed |
| `demo_data_seed_failed` | 2004 | UI test demo seed failed |

Domain: `com.jacobrozell.Puzzle-Buddy.logger`

UserInfo includes sanitized allowlisted metadata + `log_category`, `event_name`, `app_version`.

### dSYM upload

Post-build script in `project.yml` runs Firebase Crashlytics `run` for symbolicated crash reports.

---

## Redaction

`LogRedaction` removes metadata keys whose lowercase name is in:

`email`, `uid`, `password`, `token`, `name`, `displayName`

Do not rely on redaction as a safety net — never pass PII intentionally.

---

## Adding a new Analytics event (checklist)

1. Choose snake_case `eventName`
2. Add to `PuzzleAnalyticsEventMapping.allowlistedEvents`
3. Add parameter keys to `allowlistedParameterKeys` only if PII-free
4. Call `AppLog.shared.info` (or warning/error) from feature code
5. Document in this file (Analytics table)
6. Add/adjust test in `AppLoggingTests` or `AppTests`
7. If `.error` should be a Crashlytics non-fatal, add to `FirebaseCrashlyticsEventMapping` with new stable code
8. **Android parity** — update `PuzzleBuddy-Android/.../FirebaseAnalyticsEventMapping.kt` (and Crashlytics mapping) in the same change; run `~/Desktop/personal/DaRules/scripts/check-firebase-parity.sh`

---

## Inspecting telemetry

### Xcode / Console.app

Subsystem: `com.jacobrozell.Puzzle-Buddy`, category: `app`

### Firebase DebugView

1. Scheme → `-FIRAnalyticsDebugEnabled` + `-firebase_analytics_debug` for Debug collection
2. Firebase Console → Analytics → DebugView
3. Remove debug flags before App Store archive

### Crashlytics console

Non-fatals appear under Crashlytics → Issues (grouped by error code). Breadcrumbs attach to crash and non-fatal sessions.

---

## Related docs

- [ga4-analytics-spec.md](ga4-analytics-spec.md) — GA4 reports, funnels, custom dimensions, future events
- [release/ga4-phase-b-console-checklist.md](release/ga4-phase-b-console-checklist.md) — Firebase Console registration steps
- [analytics.md](analytics.md) — shorter developer quick reference
- [firebase-setup.md](firebase-setup.md) — Console and plist setup
- [testing.md](testing.md) — disabling telemetry in tests
