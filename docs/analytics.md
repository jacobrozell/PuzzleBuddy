# Analytics and logging

Quick reference for Puzzle Buddy telemetry. **Full spec:** [telemetry.md](telemetry.md).

## Rules

1. Call **`AppLog.shared`** — never `Analytics.logEvent` or Crashlytics directly
2. **Allowlist only** — add event names to `PuzzleAnalyticsEventMapping` before shipping
3. **No PII** in metadata or log messages used for Crashlytics
4. **Release-only** remote telemetry by default (Debug off unless `-firebase_analytics_debug`)

## Example

```swift
AppLog.shared.info(
    .puzzles,
    eventName: "puzzle_added",
    message: "Puzzle saved.",
    metadata: ["puzzle_status": puzzle.status.rawValue]
)
```

## Allowlisted Analytics events

See the full table in [telemetry.md § Analytics allowlist](telemetry.md#analytics-allowlist).

Summary: `app_bootstrap_ready` → Firebase `app_open`; plus onboarding, puzzle CRUD, import, export, shopping scan, and local load failure (`puzzle_sync_failed`).

## Crashlytics

- **Breadcrumbs** at `.info+`: `[category] eventName`
- **Non-fatals** at `.error` for allowlisted events only (`FirebaseCrashlyticsEventMapping.swift`)

## Debug

| Goal | Launch arguments |
|------|------------------|
| Disable telemetry | `-disable_firebase_analytics` |
| Enable in Debug | `-firebase_analytics_debug` |
| Firebase DebugView | `-FIRAnalyticsDebugEnabled` |

## Adding events

Follow the checklist in [telemetry.md § Adding a new Analytics event](telemetry.md#adding-a-new-analytics-event-checklist).

## Agent entry point

[AGENTS.md](../AGENTS.md) · [architecture.md](architecture.md) · [firebase-setup.md](firebase-setup.md)
