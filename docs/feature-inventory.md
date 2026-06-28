# Feature inventory — Puzzle Buddy

**What exists in the build today.** For behavior detail see [features.md](features.md). For future work see [FutureIdeas/backlog.md](../FutureIdeas/backlog.md).

**Last updated:** 2026-06-27  
**Target v1.0.1:** Local-first catalog — no account. Import/export gated off.

---

## Shipped (1.0.1 default build)

| Area | Feature | Code paths |
|------|---------|------------|
| Launch | Splash → onboarding → main tabs | `SplashView`, `RootView`, `OnboardingView` |
| Catalog | Add / edit / delete puzzle | `PuzzleForm`, `PuzzleStore`, `PuzzleRecord` |
| Catalog | Status: Wishlist, To-Do, In-Progress, Completed, **Abandoned** | `Puzzle.Status`, list filters |
| Catalog | Tags, notes, brand, **purchase location, year, type, material, disposition** | `PuzzleForm`, `PuzzleDetail`, `PuzzleMetadataEnums` |
| Catalog | **Manual start date** on In-Progress / Completed | `PuzzleForm`, `PuzzleDateSemantics` |
| Catalog | Search, status tabs, sort, filters (incl. **type / material / disposition**) | `PuzzleList`, `PuzzleListFilter` |
| Catalog | Half-star ratings on form + list | `RatingsView`, `PuzzleCell` |
| Shopping | Barcode scan, shopping duplicate-check | `BarcodeScannerSheet`, `ShoppingModeView` |
| Shopping | Optional UPC lookup (Settings toggle) | `BarcodeLookupService` |
| Organize | **Pick my next puzzle** (list + **Stats tab**) | `PickNextPuzzleView`, `PuzzleRandomPicker` |
| Tracking | **Progress over days** (`startDate`) | `PuzzleDateSemantics`, detail stats |
| Stats | Collection stats + **wishlist / abandoned / avg days / favorite type / top stores** | `CollectionStatsView`, `CollectionStats` |
| Stats | **Completion milestones** banner | `CollectionMilestones` |
| Stats | Per-puzzle pace metrics | `PuzzleDetailMetrics` |
| Stats | Share collage | `PuzzleShareMenu` |
| Settings | Appearance, demo data, legal links | `SettingsView` |
| Observability | Allowlisted Analytics + Crashlytics | `AppLog` |
| A11y | Phase 1 + automated audits | `A11yID`, `PuzzleAccessibilityUITests` |

---

## Gated off (1.0)

| Feature | Flag | Dogfood |
|---------|------|---------|
| IPDb CSV import | `isCollectionImportExportEnabled` | `-enable_collection_import_export` |
| JSON / CSV export | same | same |
| Login + Firestore sync | `isLoginEnabled` | `-enable_login` |

---

## Planned (specced)

See [FutureIdeas/backlog.md](../FutureIdeas/backlog.md) and `specs/planned/`.

---

## v1.0 release surface

| Decision | Choice |
|----------|--------|
| Account required | **No** |
| Import/export | **Off** until 1.1 |
| Pick-next | **On** |
| Min iOS | 17.0 |
| Locales | English only |

---

## Verification

| Release | Last verified | Tests |
|---------|---------------|-------|
| 1.0.1 metadata sprint | 2026-06-27 | 180 unit tests green |
