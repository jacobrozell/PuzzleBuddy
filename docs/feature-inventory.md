# Feature inventory — Puzzle Buddy

**What exists in the build today.** For behavior detail see [features.md](features.md). For future work see [FutureIdeas/backlog.md](../FutureIdeas/backlog.md). For competitor gaps see [competitive-gap-analysis.md](competitive-gap-analysis.md).

**Last updated:** 2026-09-25  
**Target:** 1.1.0 on `release/1.1.0`

---

## In build (1.1.0)

| Area | Feature | Code paths |
|------|---------|------------|
| Launch | Splash → onboarding → main tabs | `SplashView`, `RootView`, `OnboardingView` |
| Launch | **What's New (1.1)** one-time sheet for 1.0 upgraders | `WhatsNewPrompt`, `WhatsNewView` |
| Catalog | Add / edit / delete puzzle | `PuzzleForm`, `PuzzleStore`, `PuzzleRecord` |
| Catalog | Status: Wishlist, To-Do, In-Progress, Completed, **Abandoned** | `Puzzle.Status`, list filters |
| Catalog | **On loan** + local Friends model (Friends list UI flagged off) | `FriendRecord`, loan fields, list filter |
| Catalog | Tags, notes, brand, purchase location, year, type, material, disposition, **shape, cut type, dimensions, price** | `PuzzleForm`, `PuzzleDetail`, `PuzzleMetadataEnums` |
| Catalog | **Multi-photo gallery** (max 5, cover = first) | `PuzzlePhotoGalleryEditor`, `PuzzlePhotoRecord` |
| Catalog | **Redo + completion history** | `PuzzleCompletionRecord`, `PuzzleStore.startRedo` |
| Catalog | **Manual start date** on In-Progress / Completed | `PuzzleForm`, `PuzzleDateSemantics` |
| Catalog | **Undo completion** banner (5 min / same session) | `CompletionUndoSemantics`, `PuzzleStore.undoLastCompletion` |
| Catalog | Search, status tabs, sort, filters (incl. **type / material / disposition**, **Overdue**) | `PuzzleList`, `PuzzleListFilter` |
| Catalog | Half-star ratings on form + list | `RatingsView`, `PuzzleCell` |
| Shopping | Barcode scan, shopping duplicate-check | `BarcodeScannerSheet`, `ShoppingModeView` |
| Shopping | Local barcode metadata from saved puzzles | `BarcodeMetadataCache` |
| Organize | **Pick my next puzzle** (list + **Stats tab**) | `PickNextPuzzleView`, `PuzzleRandomPicker` |
| Tracking | **Progress over days** (`startDate`) | `PuzzleDateSemantics`, detail stats |
| Stats | Collection stats + **wishlist / abandoned / avg days / favorite type / top stores** | `CollectionStatsView`, `CollectionStats` |
| Stats | **Completion milestones** banner | `CollectionMilestones` |
| Stats | Per-puzzle pace metrics | `PuzzleDetailMetrics` |
| Stats | Share collage | `PuzzleShareMenu` |
| Settings | Appearance, demo data, legal links, **Write a Review** | `SettingsView`, `AppLinks.appStoreWriteReview` |
| Settings | One-time StoreKit review prompt after scan or edit | `StoreReviewPrompt` |
| Observability | Allowlisted Analytics + Crashlytics | `AppLog`, [telemetry.md](telemetry.md) |
| A11y | Phase 1 + automated audits | `A11yID`, `PuzzleAccessibilityUITests` |

---

## Gated off

| Feature | Flag | Notes |
|---------|------|-------|
| Friends / People list UI | `isFriendsListEnabled = false` | Model + On loan live; Settings entry hidden |

---

## Removed from app (not gated)

| Feature | Status | Notes |
|---------|--------|-------|
| Login + Firestore sync | **Removed** June 2026 | Future: [specs/planned/auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md) |
| Push / FCM | **Removed** | No Messaging SDK |
| Settings collection import/export UI | **Removed** 1.1.0 | Helpers kept; re-ship later — [FutureIdeas/backlog.md](../FutureIdeas/backlog.md) |

---

## Planned (specced)

See [FutureIdeas/backlog.md](../FutureIdeas/backlog.md) and `specs/planned/`.

---

## Release surface

| Decision | Choice |
|----------|--------|
| Account required | **No** |
| Import/export Settings UI | **Off** (removed 1.1.0; helpers in tree) |
| Pick-next | **On** |
| Min iOS | 18.0 |
| Locales | English only |

---

## Verification

| Release | Last verified | Tests |
|---------|---------------|-------|
| 1.1.0 branch | 2026-09-21 | AppTests green for on-loan / migration suites |
| 1.0.0 pre-ship | 2026-06-29 | 163+ unit tests green |
