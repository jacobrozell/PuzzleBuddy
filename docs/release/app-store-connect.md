# Puzzle Buddy — App Store Connect checklist

Use this when submitting. Aligns with [`todo.md`](todo.md) and [`../privacy.html`](../privacy.html).

## 1.1.0 package

| Field | Value |
| ----- | ----- |
| **Version** | 1.1.0 |
| **Minimum OS** | iOS 18.0 |
| **Privacy URL** | https://jacobrozell.github.io/PuzzleBuddy/privacy.html |
| **Support URL** | https://jacobrozell.github.io/PuzzleBuddy/support.html |

### 1.1.0 Notes for Review

> Puzzle Buddy 1.1.0 is a local-first jigsaw catalog. No account or login. Requires iOS 18.
>
> **Demo data:** Settings → Collection → Load Demo Data (adds 13 sample puzzles; existing user puzzles are kept). Remove Demo Data removes only those samples.
>
> **New in 1.1 (how to review):**
> - Completion history: open **Floral Arch** (completed twice) → edit or delete a finish.
> - Undo complete: mark a puzzle Complete, then use the undo banner (same session).
> - On loan: **Paris in a Day** is already on loan to “Mom.” Filters: On loan. To see **Overdue**, edit that puzzle and set Due back to a past date.
> - What’s New sheet appears only for users who already finished 1.0 onboarding. A fresh install sees 1.1 features in onboarding instead.
> - StoreKit `requestReview` may appear once after a barcode scan or after saving a non-demo edit. Settings → Write a Review opens the App Store write-review URL.
>
> **Not shipped (do not look for these):** People / Friends list UI is off. Settings import/export was removed. There is no barcode product-lookup toggle or network catalog. Barcodes are on-device only (duplicate check + suggestions from saved puzzles). Camera required for scan; simulators show “Scanner unavailable” and manual barcode entry still works.
>
> **Privacy:** Collection, photos, notes, and optional borrower names stay on device. Firebase Analytics and Crashlytics only (allowlisted events; no titles, photos, or names). Privacy: https://jacobrozell.github.io/PuzzleBuddy/privacy.html
>
> Brand names in the catalog are for identification only. Settings → Help & Legal has the manufacturer disclaimer.

### 1.1.0 What’s New (App Store)

> Track every finish. 1.1 adds completion history (edit or delete a log), a same-session undo after you mark a puzzle complete, and On loan / overdue filters. What’s New notes appear if you already used 1.0.

### 1.1.0 screenshots

Recapture at least: list with On loan / overdue chips, detail + completion history, iPad / sidebar tabs. First frame still reads as a catalog, not a kids’ game. Do not advertise import/export or a People list.

### Privacy nutrition (1.1.0)

Product interaction: `session_snapshot`, `milestone_reached`. Friend / borrower names: Other user content (not Contacts / Name).

---

## 1.0.0 App information (historical)

## App information


| Field                | Value                                        |
| -------------------- | -------------------------------------------- |
| **Name**             | Puzzle Buddy: Jigsaw Tracker                 |
| **Subtitle**         | Collection Catalog & Organizer               |
| **Primary category** | Lifestyle (or Entertainment)                 |
| **Bundle ID**        | `com.jacobrozell.Puzzle-Buddy`               |
| **SKU**              | `a001puzzlebuddy`                            |
| **Apple ID**         | `1642548378`                                 |
| **Version**          | 1.0.0                                        |
| **Build**            | 1                                            |
| **Keywords**         | See [ASO](#app-store-optimization-aso) below |




## App name (confirmed)

Ship on App Store Connect as **Puzzle Buddy: Jigsaw Tracker** (28/30 chars). Plain **Puzzle Buddy** and **Puzzle Pal** were unavailable at record creation; the colon subtitle keeps the “Buddy” brand while adding discoverability keywords. Still aligns with the personal “Buddy” app family (Dart Buddy, etc.).

**Home screen:** keep `Puzzle Buddy` (`CFBundleDisplayName` in `project.yml`) — shorter icon label; App Store name can differ.

**Before submit:** App Store Connect app record created with exact name **Puzzle Buddy: Jigsaw Tracker** (globally unique — reserved or deleted-app names also block).

## Naming & trademark hygiene

Not legal advice. Informal pre-ship review (June 2026):


| Check                | Finding                                                                                                                                                                                                                                    |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Exact App Store name | **Puzzle Buddy** and **Puzzle Pal** taken at Connect record creation (June 2026). Shipped as **Puzzle Buddy: Jigsaw Tracker**. Nearest catalog collision remains kids game **Puzzles for Kids: PuzzleBuddy** (different name and category) |
| Primary competitor   | **Puzzle Tracker** — different name; owns the “puzzle tracker” head term                                                                                                                                                                   |
| Physical goods       | [The Puzzle Buddy](https://puzzlebuddy.com/) — puzzle roll-up mats; same hobby, different product class. Revisit if trademarking or expanding brand                                                                                        |
| USPTO (informal)     | No strong registered software mark for “Puzzle Buddy” found; descriptive phrase → lower infringement risk, harder to register ourselves                                                                                                    |
| Puzzle manufacturers | `[../spec-brand-disclaimer.md](../spec-brand-disclaimer.md)` — separate from app name                                                                                                                                                      |


Legacy internal name **PuzzlePal** (`PuzzlePal_Onboarding_Complete` in onboarding) — retired; do not use on the storefront.

## App Store optimization (ASO)



### Name + subtitle


| Field                   | Value                          | Rationale                                                                                                            |
| ----------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| **Name** (30 chars)     | Puzzle Buddy: Jigsaw Tracker   | Brand + jigsaw + tracker; 28/30 chars; only format Apple accepted after **Puzzle Buddy** / **Puzzle Pal** collisions |
| **Subtitle** (30 chars) | Collection Catalog & Organizer | Discoverability without repeating name tokens (jigsaw, tracker, buddy, puzzle)                                       |


We do **not** chase “Puzzle Tracker” as the primary title. Compete on positioning: local-first, accessibility, simplicity — see `[../roadmap.md](../roadmap.md#competitive-positioning--puzzle-tracker)`.

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

See `[../../marketing-screenshots/README.md](../../marketing-screenshots/README.md)`.

## URLs (GitHub Pages)


| Purpose        | URL                                                                                                                          |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Privacy Policy | [https://jacobrozell.github.io/PuzzleBuddy/privacy.html](https://jacobrozell.github.io/PuzzleBuddy/privacy.html)             |
| Support        | [https://jacobrozell.github.io/PuzzleBuddy/support.html](https://jacobrozell.github.io/PuzzleBuddy/support.html)             |
| Accessibility  | [https://jacobrozell.github.io/PuzzleBuddy/accessibility.html](https://jacobrozell.github.io/PuzzleBuddy/accessibility.html) |
| Marketing      | [https://jacobrozell.github.io/PuzzleBuddy/](https://jacobrozell.github.io/PuzzleBuddy/)                                     |


Push updated `docs/*.html` to `main` on GitHub before submit so hosted copy matches the build.

## Privacy nutrition label (1.0 local-first)

Declare what **actually ships** in 1.0.0 (local-first, no account, no Auth/Firestore in app).


| Data type                                    | Collected | Linked to user | Used for tracking | Notes                                                                          |
| -------------------------------------------- | --------- | -------------- | ----------------- | ------------------------------------------------------------------------------ |
| **Product interaction** (Firebase Analytics) | Yes       | No             | No                | Allowlisted events only (`app_open`, puzzle CRUD counts); no email in payloads |
| **Crash data** (Firebase Crashlytics)        | Yes       | No             | No                | Crash logs and non-PII warnings                                                |
| **Photos / user content**                    | Yes       | No             | No                | Puzzle cover images stored **on device** only in 1.0                           |
| **Other user content**                       | Yes       | No             | No                | Puzzle titles, ratings, tags — on device                                       |
| **Identifiers** (UPC barcode digits)         | No        | No             | No                | Stored on device only; not sent to third parties                               |


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

