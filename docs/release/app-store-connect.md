# Puzzle Buddy — App Store Connect checklist (1.0.0)

Use this when creating the app record and submitting build **1.0.0 (1)**. Aligns with [`todo.md`](todo.md) and [`../privacy.html`](../privacy.html).

## App information

| Field | Value |
|-------|-------|
| **Name** | Puzzle Buddy |
| **Subtitle** | Track your jigsaw collection |
| **Primary category** | Lifestyle (or Entertainment) |
| **Bundle ID** | `com.jacobrozell.Puzzle-Buddy` |
| **SKU** | `puzzle-buddy-ios` (suggested) |
| **Version** | 1.0.0 |
| **Build** | 1 |

## URLs (GitHub Pages)

| Purpose | URL |
|---------|-----|
| Privacy Policy | https://jacobrozell.github.io/PuzzleBuddy/privacy.html |
| Support | https://jacobrozell.github.io/PuzzleBuddy/support.html |
| Accessibility | https://jacobrozell.github.io/PuzzleBuddy/accessibility.html |
| Marketing | https://jacobrozell.github.io/PuzzleBuddy/ |

Push updated `docs/*.html` to `main` on GitHub before submit so hosted copy matches the build.

## Privacy nutrition label (1.0 local-first)

Declare what **actually ships** in 1.0.0 (`isLoginEnabled = false`).

| Data type | Collected | Linked to user | Used for tracking | Notes |
|-----------|-----------|----------------|-------------------|-------|
| **Product interaction** (Firebase Analytics) | Yes | No | No | Allowlisted events only (`app_open`, puzzle CRUD counts); no email in payloads |
| **Crash data** (Firebase Crashlytics) | Yes | No | No | Crash logs and non-PII warnings |
| **Photos / user content** | Yes | No | No | Puzzle cover images stored **on device** only in 1.0 |
| **Other user content** | Yes | No | No | Puzzle titles, ratings, tags — on device |
| **Identifiers** (UPC barcode digits) | No | No | No | Stored on device only; not sent to third parties |

**Do not declare** (not used in 1.0): email, name, precise location, contacts, financial info, push token (push not requested in 1.0).

## Age rating

Questionnaire answers (expected):

- No unrestricted web access in app UI (external links open Safari for policy/support only)
- No gambling, violence, mature content
- No social networking / user-generated public content
- Camera used for puzzle photos and barcode scan

Expected rating: **4+**

## Export compliance

- App uses HTTPS for optional barcode lookup and Firebase services
- Standard encryption only → **Yes**, qualifies for exemption (annual self-classification)

## Review notes (optional field)

Suggested text for App Review:

> Puzzle Buddy 1.0 is a local-first puzzle catalog. No account is required. Optional barcode product lookup is off by default (Settings → Barcode & cataloging). Demo data: Settings → Collection → Load Demo Data. Sign-in and cloud sync are implemented but disabled for this release.

## Accessibility URL

App Store Connect → App Accessibility → URL:

https://jacobrozell.github.io/PuzzleBuddy/accessibility.html

## Screenshots (still todo)

Capture on **iPhone 6.7"** and **iPad 13"** emphasizing:

1. Puzzle list with collection
2. Barcode duplicate check / shopping mode
3. Collection stats
4. Add puzzle form
5. Settings (local-first, export/import)

No login or account pitch in 1.0 marketing.

## Pre-upload verification

- [ ] Release build: `isLoginEnabled == false`
- [ ] Fresh install: no push permission prompt on launch
- [ ] Privacy + Support links load in Safari
- [ ] Unit tests green (`Puzzle BuddyTests`)
- [ ] UI accessibility suite green on iPhone 17 sim
