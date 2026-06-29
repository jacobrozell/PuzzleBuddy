# Firebase setup

Configure Firebase for Puzzle Buddy local development and production.

**Scope:** Analytics and Crashlytics only. The app does **not** use Firebase Auth, Firestore, or Cloud Messaging.

**Last updated:** 2026-06-29

See also: [telemetry.md](telemetry.md) (allowlists, bootstrap logic), [AGENTS.md](../AGENTS.md) (agent quick reference).

---

## What Firebase powers

| Service | Status | Purpose |
|---------|--------|---------|
| **Analytics** | Active (Release) | Allowlisted product events via `AppLog` |
| **Crashlytics** | Active (Release) | Breadcrumbs + allowlisted non-fatals |
| **Authentication** | Not in app | Removed — future work in [specs/planned/auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md) |
| **Firestore** | Not in app | Removed from app and Firebase Console |
| **Cloud Messaging** | Not in app | Removed — no push registration |

Puzzle data is stored **only on device** via SwiftData (`PuzzleRecord`).

---

## Prerequisites

- Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
- Xcode 16+, iOS 17 deployment target
- Optional: real `GoogleService-Info.plist` for local Analytics/Crashlytics verification (not required for builds/tests)

---

## 1. Create or select a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Add project or select existing Puzzle Buddy project
3. Google Analytics in the Firebase wizard is optional — the app uses a custom allowlisted wrapper

---

## 2. Register the iOS app

1. Project settings → **Add app** → **iOS**
2. **Bundle ID:** `com.jacobrozell.Puzzle-Buddy` (must match `project.yml`)
3. Download `GoogleService-Info.plist`
4. Place at repo root (same level as `project.yml`):

```bash
cp ~/Downloads/GoogleService-Info.plist /path/to/Puzzle-Buddy/
```

5. Regenerate Xcode project:

```bash
xcodegen generate
```

> **Security:** Never commit this file. Run `./Scripts/install-git-hooks.sh` to enable the pre-commit guard.

### Placeholder config for CI

`GoogleService-Info.plist.example` contains `REPLACE_WITH_*` values. CI copies this before building:

```bash
cp GoogleService-Info.plist.example GoogleService-Info.plist
```

`FirebaseBootstrap.shouldConfigure` returns `false` for placeholders — Firebase does not initialize, but the app and tests run normally with SwiftData-only persistence.

---

## 3. Enable Crashlytics in Console

1. Firebase Console → **Build** → **Crashlytics**
2. Follow first-run setup if prompted (dSYM upload is handled by the Xcode build phase in `project.yml`)

No Auth, Firestore, or Cloud Messaging setup is required.

---

## 4. SDK packages (reference)

Declared in `project.yml`:

| Product | Purpose |
|---------|---------|
| `FirebaseCore` | Bootstrap |
| `FirebaseAnalytics` | GA4 events |
| `FirebaseCrashlytics` | Crashes + non-fatals |

Regenerate after package changes: `xcodegen generate`.

---

## 5. Local debugging

### Disable remote telemetry

Xcode → Edit Scheme → Run → Arguments:

```
-disable_firebase_analytics
```

Disables both Analytics and Crashlytics collection.

### Force telemetry in Debug

```
-firebase_analytics_debug
```

Also add `-FIRAnalyticsDebugEnabled` for Firebase DebugView.

### Verify Analytics

1. Run on simulator/device with real plist + debug flags above
2. Firebase Console → Analytics → **DebugView**
3. Trigger allowlisted actions (add puzzle, complete onboarding, etc.)

### Verify Crashlytics

1. Release build or `-firebase_analytics_debug` on device/simulator
2. Trigger allowlisted error (e.g. force SwiftData failure in dev only)
3. Firebase Console → Crashlytics → non-fatals and breadcrumbs

---

## 6. Smoke test checklist

- [ ] `xcodegen generate` && open in Xcode
- [ ] Run on Simulator — onboarding → puzzle list (no login)
- [ ] Add puzzle — quit and relaunch; puzzle persists (SwiftData)
- [ ] With real plist + DebugView flags: see `app_open` / `puzzle_added` in DebugView
- [ ] CI passes with example plist (Firebase inactive)

---

## 7. Common issues

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Firebase not configuring | Placeholder or missing plist | Copy real plist or use example for CI |
| No DebugView events | Debug collection off | Add `-firebase_analytics_debug` and `-FIRAnalyticsDebugEnabled` |
| No Crashlytics symbols | dSYM not uploaded | Check Crashlytics run script in build log |
| `KeyError` in console from `fromData` | Legacy test dict missing keys | Used for export serialization tests only |

---

## 8. Production checklist

- [ ] Real `GoogleService-Info.plist` on release build machines only (not in git)
- [ ] Analytics and Crashlytics receiving events in Console (Release build)
- [ ] App Store Connect bundle ID matches `com.jacobrozell.Puzzle-Buddy`
- [ ] Privacy policy mentions Analytics/Crashlytics ([privacy.html](privacy.html))

---

## Removed services (historical)

Prior to June 2026 the repo included Auth, Firestore sync, FCM push, `firestore.rules`, and `firebase.json`. Those were removed from the app and Firebase Console. Do not re-enable without [auth-cloud-sync spec](../specs/planned/auth-cloud-sync.md) approval.
