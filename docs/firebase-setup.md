# Firebase setup

Step-by-step guide to configuring Firebase for local development and production for Puzzle Buddy.

## What Firebase powers in 1.0

| Service | 1.0 status | Purpose |
|---------|------------|---------|
| **Analytics** | Active | Allowlisted events via `AppLog` |
| **Crashlytics** | Active | Warnings and non-fatal errors |
| **Authentication** | Configured, UI gated | Ships when `ProductService.isLoginEnabled` is true |
| **Firestore** | Configured, unused in 1.0 | Cloud sync when login ships |
| **Cloud Messaging** | Optional | Push notifications |

Puzzle data in **1.0** is stored locally with **SwiftData**. Firebase Auth and Firestore setup below prepares for the login release.

- Apple Developer account (for Sign in with Apple and push notifications)
- Firebase project (create at [console.firebase.google.com](https://console.firebase.google.com))
- Firebase CLI optional but recommended: `npm install -g firebase-tools`

## 1. Create or select a Firebase project

1. Open the [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** (or select an existing project)
3. Follow the wizard (Google Analytics optional — Puzzle Buddy uses a custom allowlisted Analytics wrapper)

## 2. Register the iOS app

1. In Project settings, click **Add app** → **iOS**
2. **Bundle ID:** `com.jacobrozell.Puzzle-Buddy` (must match `project.yml`)
3. Download `GoogleService-Info.plist`
4. Place it at the repo root (same level as `project.yml`):

```bash
cp ~/Downloads/GoogleService-Info.plist /path/to/PuzzleBuddy/
```

5. Regenerate the Xcode project so the plist is included as a resource:

```bash
xcodegen generate
```

> **Security:** Never commit this file. Run `./Scripts/install-git-hooks.sh` to enable the pre-commit guard.

### Placeholder config for CI

`GoogleService-Info.plist.example` contains `REPLACE_WITH_*` values. CI copies this file before building. `FirebaseBootstrap.shouldConfigure` returns `false` for placeholders, so Firebase does not initialize in CI — builds still compile and tests run without a live backend.

## 3. Enable Authentication providers (login release)

Required before enabling `ProductService.isLoginEnabled`. Safe to configure early; the 1.0 app does not present login UI.

In Firebase Console → **Authentication** → **Sign-in method**:

### Email/Password

1. Enable **Email/Password**
2. Save

### Sign in with Apple

1. Enable **Apple**
2. In [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/serviceId):
   - Ensure the App ID has **Sign in with Apple** capability
   - Create a Services ID if required by your Firebase Apple provider setup
   - Configure return URLs per [Firebase Apple auth docs](https://firebase.google.com/docs/auth/ios/apple)
3. Add the Apple team ID, key ID, and private key in Firebase if using the full OAuth flow for web; native iOS Sign in with Apple uses the app's entitlements

The app entitlements file is `Puzzle Buddy/Puzzle Buddy.entitlements` with the Sign in with Apple capability.

## 4. Create Firestore database (login release)

Required for cloud sync when login ships. Not used for puzzle storage in 1.0.

1. Firebase Console → **Firestore Database** → **Create database**
2. Start in **production mode** (we deploy custom rules from the repo)
3. Choose a region close to your users

### Deploy security rules

From the repo root (after `firebase login` and `firebase use <project-id>`):

```bash
firebase deploy --only firestore:rules
```

Rules in `firestore.rules`:

```
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.token.email == userId;

  match /puzzles/{puzzleId} {
    allow read, write: if request.auth != null && request.auth.token.email == userId;
  }
}
```

**Important:** User document IDs and the Firestore path use the user's **email address** as `userId`. Auth tokens must include `email` (email/password and Apple with email scope).

### Data layout

```
users/
  {userEmail}/
    username: string
    currentVersion: string
    lastLoggedIn: timestamp
    puzzles/
      {puzzleUUID}/
        id, name, pieces, rating, difficulty, ...
```

## 5. Firebase CLI configuration

`firebase.json` points to `firestore.rules`:

```json
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

Initialize CLI in the repo (one time):

```bash
firebase login
firebase use --add   # select your project
```

## 6. Analytics and Crashlytics

Firebase Analytics and Crashlytics are included via the iOS SDK. Puzzle Buddy only logs **allowlisted** Analytics events through `AppLog`. Crashlytics receives warning/error log lines and non-fatal error records — no PII. See [analytics.md](analytics.md).

To disable Analytics during local debugging, launch with argument:

```
-disable_firebase_analytics
```

In Xcode: Edit Scheme → Run → Arguments → Arguments Passed On Launch.

## 7. Cloud Messaging (optional)

The app registers for push notifications in `AppDelegate`. For production push:

1. Upload your APNs authentication key or certificate in Firebase Console → Project settings → Cloud Messaging
2. Enable **Push Notifications** capability in Xcode for the app target
3. Test on a physical device (simulator push is limited)

FCM tokens are posted to `NotificationCenter` (`FCMToken`) but are not required for core puzzle functionality.

## 8. Verify the setup

### Local smoke test (1.0)

1. `xcodegen generate` && open in Xcode
2. Run on Simulator — app opens to puzzle list (no login)
3. Add a puzzle — quit and relaunch; puzzle should still be present (SwiftData)
4. Check Firebase Console → Analytics DebugView (with `-FIRAnalyticsDebugEnabled`) and Crashlytics after triggering a logged error

### Login + Firestore smoke test (when login enabled)

1. Launch with `-enable_login` or set `ProductService.isLoginEnabled` to `true`
2. Create an account with email/password
3. Add a puzzle — check Firestore Console for a new document under `users/{email}/puzzles`

### Common issues

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Firebase not configuring | Placeholder plist or missing file | Copy real `GoogleService-Info.plist` |
| Permission denied on Firestore | Rules not deployed or email mismatch | `firebase deploy --only firestore:rules`; ensure signed-in email matches path |
| Apple Sign In fails | Entitlements or Firebase Apple provider | Check capability, bundle ID, Firebase Apple config |
| `KeyError` logs in console | Legacy documents missing fields | `fromData` logs missing keys; add defaults or migrate data |

## 9. Production checklist

- [ ] Real `GoogleService-Info.plist` on build machines only (not in git)
- [ ] Analytics and Crashlytics receiving events in Firebase Console
- [ ] App Store Connect bundle ID matches `com.jacobrozell.Puzzle-Buddy`
- [ ] When login ships: Firestore rules deployed from `firestore.rules`
- [ ] When login ships: Email/Password and Apple providers enabled
- [ ] APNs configured if using push
