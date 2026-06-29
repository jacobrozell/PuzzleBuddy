# Puzzle Buddy — App Store Connect checklist (1.0.0)

Use this when creating the app record and submitting build **1.0.0 (1)**. Aligns with [`todo.md`](todo.md) and [`../privacy.html`](../privacy.html).

## App information

| Field | Value |
|-------|-------|
| **Name** | Puzzle Buddy: Jigsaw Tracker |
| **Subtitle** | Collection Catalog & Organizer |
| **Primary category** | Lifestyle (or Entertainment) |
| **Bundle ID** | `com.jacobrozell.Puzzle-Buddy` |
| **SKU** | `a001puzzlebuddy` |
| **Version** | 1.0.0 |
| **Build** | 1 |
| **Keywords** | See [ASO](#app-store-optimization-aso) below |

## App name (confirmed)

Ship on App Store Connect as **Puzzle Buddy: Jigsaw Tracker** (28/30 chars). Plain **Puzzle Buddy** and **Puzzle Pal** were unavailable at record creation; the colon subtitle keeps the “Buddy” brand while adding discoverability keywords. Still aligns with the personal “Buddy” app family (Dart Buddy, etc.).

**Home screen:** keep **`Puzzle Buddy`** (`CFBundleDisplayName` in `project.yml`) — shorter icon label; App Store name can differ.

**Before submit:** App Store Connect app record created with exact name **Puzzle Buddy: Jigsaw Tracker** (globally unique — reserved or deleted-app names also block).

## Naming & trademark hygiene

Not legal advice. Informal pre-ship review (June 2026):

| Check | Finding |
|-------|---------|
| Exact App Store name | **Puzzle Buddy** and **Puzzle Pal** taken at Connect record creation (June 2026). Shipped as **Puzzle Buddy: Jigsaw Tracker**. Nearest catalog collision remains kids game **Puzzles for Kids: PuzzleBuddy** (different name and category) |
| Primary competitor | **Puzzle Tracker** — different name; owns the “puzzle tracker” head term |
| Physical goods | [The Puzzle Buddy](https://puzzlebuddy.com/) — puzzle roll-up mats; same hobby, different product class. Revisit if trademarking or expanding brand |
| USPTO (informal) | No strong registered software mark for “Puzzle Buddy” found; descriptive phrase → lower infringement risk, harder to register ourselves |
| Puzzle manufacturers | [`../spec-brand-disclaimer.md`](../spec-brand-disclaimer.md) — separate from app name |

Legacy internal name **PuzzlePal** (`PuzzlePal_Onboarding_Complete` in onboarding) — retired; do not use on the storefront.

## App Store optimization (ASO)

### Name + subtitle

| Field | Value | Rationale |
|-------|-------|-----------|
| **Name** (30 chars) | Puzzle Buddy: Jigsaw Tracker | Brand + jigsaw + tracker; 28/30 chars; only format Apple accepted after **Puzzle Buddy** / **Puzzle Pal** collisions |
| **Subtitle** (30 chars) | Collection Catalog & Organizer | Discoverability without repeating name tokens (jigsaw, tracker, buddy, puzzle) |

We do **not** chase “Puzzle Tracker” as the primary title. Compete on positioning: local-first, accessibility, simplicity — see [`../roadmap.md`](../roadmap.md#competitive-positioning--puzzle-tracker).

### Keywords (100 characters)

Apple: for max discoverability, prioritize adjacent search terms not already in **name** or **subtitle** (avoid repeating `puzzle`, `buddy`, `jigsaw`, `tracker`, `collection`, `catalog`, `organizer`).

```text
inventory,library,wishlist,barcode,scanner,stats,pieces,completed,puzzler,duplicate,shelf,offline
```

Character count: **98/100**

After launch, tune using App Store Connect → **Analytics → Acquisition → App Store Search**.

### Promotional text (170 chars, optional)

> Jigsaw puzzle tracker for collectors: catalog your collection, organize wishlist and completed puzzles, run duplicate barcode checks, and view stats. Offline, private, no account.

### Description (opening — visible before “more”)

Lead with the **catalog/organizer** job, not puzzle gameplay.

Recommended opening:

> Puzzle Buddy is a jigsaw puzzle tracker app for collectors. Catalog puzzles with photos, piece counts, and status from wishlist to completed. Search your library fast, check duplicates before you buy, and view collection stats. No account required—your data stays on your device.

Suggested body bullets (paste into Description after the opening):

- Catalog your shelf with photos, piece counts, ratings, tags, and notes
- Organize puzzles by status: Wishlist, To-Do, In Progress, Completed, Abandoned
- Check duplicates quickly with barcode matching and search
- Track milestones and collection stats to see your progress over time
- Pick your next puzzle from your backlog when you are undecided
- Built for accessibility: Dynamic Type, VoiceOver labels, reduced-motion friendly
- Local-first by default: no login, no cloud account required for core use

### Screenshot messaging

First screenshots should read as a **collection app**, not a kids’ puzzle game. Use short, high-contrast headline copy:

1. Jigsaw Puzzle Tracker
2. Catalog your puzzle collection
3. Barcode duplicate check
4. Wishlist to completed
5. Search and filter your library
6. Collection stats and milestones
7. Private and offline by default

See [`../../marketing-screenshots/README.md`](../../marketing-screenshots/README.md).

## URLs (GitHub Pages)

| Purpose | URL |
|---------|-----|
| Privacy Policy | https://jacobrozell.github.io/PuzzleBuddy/privacy.html |
| Support | https://jacobrozell.github.io/PuzzleBuddy/support.html |
| Accessibility | https://jacobrozell.github.io/PuzzleBuddy/accessibility.html |
| Marketing | https://jacobrozell.github.io/PuzzleBuddy/ |

Push updated `docs/*.html` to `main` on GitHub before submit so hosted copy matches the build.

## Privacy nutrition label (1.0 local-first)

Declare what **actually ships** in 1.0.0 (local-first, no account, no Auth/Firestore in app).

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

> Puzzle Buddy 1.0 is a local-first puzzle catalog. No account is required. Optional barcode product lookup is off by default (Settings → Barcode & cataloging). Demo data: Settings → Collection → Load Demo Data. Firebase is used for Analytics and Crashlytics only.

## Accessibility URL

App Store Connect → App Accessibility → URL:

https://jacobrozell.github.io/PuzzleBuddy/accessibility.html

## Screenshots

Capture on **iPhone 17 Pro** and **iPad Pro 13-inch** using the marketing scripts:

Upload from the sorted folders (no device bezels):

- **iPhone:** `marketing-screenshots/iphone/{dark,light}/{portrait,landscape}/`
- **iPad:** `marketing-screenshots/ipad/{dark,light}/{portrait,landscape}/`

```bash
./Scripts/capture-marketing-screenshots.sh          # iphone/dark/{portrait,landscape}
APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh
./Scripts/capture-ipad-marketing-screenshots.sh     # ipad/dark/{portrait,landscape}
./Scripts/capture-all-marketing-screenshots.sh      # full matrix

# Migrate legacy flat raw/ layout
./Scripts/sort-marketing-screenshots.sh
```

See [`marketing-screenshots/README.md`](../../marketing-screenshots/README.md).

Screens emphasized (automated by the script):

1. Puzzle list with demo collection
2. Barcode duplicate check sheet
3. Collection stats
4. Add puzzle form
5. Puzzle detail (completed puzzle)
6. Settings (local-first, export/import gated off in 1.0)
7. Onboarding welcome + barcode pitch

No login or account pitch in 1.0 marketing.

## Pre-upload verification

- [x] App Store Connect accepts exact name **Puzzle Buddy: Jigsaw Tracker**
- [ ] Subtitle, keywords, promotional text, and description pasted per [ASO](#app-store-optimization-aso)
- [ ] First screenshot clearly signals catalog/organizer (not kids’ game)
- [ ] Release build: no login UI; puzzle data local-only (SwiftData)
- [ ] Fresh install: no push permission prompt on launch
- [ ] Privacy + Support links load in Safari
- [ ] Unit tests green (`AppTests`)
- [ ] UI accessibility suite green on iPhone 17 sim
