# Puzzle Buddy — future ideas

Prioritized backlog from product review (2026-06-27). Shipped behavior lives in [`docs/feature-inventory.md`](../docs/feature-inventory.md).

## 1.0.0 (shipping now)

| Item | Status | Notes |
|------|--------|-------|
| Pick my next puzzle | ✅ Shipped | Dice button on collection list; filters by tag + piece count |
| Wishlist status | ✅ Shipped | Separate from owned To-Do; excluded from random pick |
| Progress over days | ✅ Shipped | `startDate` + “days puzzling” / “finished in N days” on detail |
| Collection import/export | ⏸ Gated | Off in 1.0; launch arg `-enable_collection_import_export` for dogfood |

## 1.0.1 — shipped (dev)

See [`docs/implementation/1.0.1-metadata-sprint.md`](../docs/implementation/1.0.1-metadata-sprint.md).

| Item | Status |
|------|--------|
| Abandoned status + start-date picker | ✅ Shipped |
| Stats: wishlist, avg days, milestones | ✅ Shipped |
| Pick-next on Stats tab | ✅ Shipped |
| Metadata: purchase location, year, type, material, disposition | ✅ Shipped |
| List filters: type, material, disposition | ✅ Shipped |

## 1.1.0 — migration & backup

| Idea | Spec | Notes |
|------|------|-------|
| **IPDb CSV import + JSON/CSV export** | [`specs/planned/collection-import-export.md`](../specs/planned/collection-import-export.md) | Re-enable `ProductService.isCollectionImportExportEnabled` |
| **JSON backup restore** | [`specs/planned/json-backup-restore.md`](../specs/planned/json-backup-restore.md) | Pair export with import; include photos in v2 |
| **Auth + cloud sync** | [`specs/planned/auth-cloud-sync.md`](../specs/planned/auth-cloud-sync.md) | `isLoginEnabled` + local→cloud migration |
| **In-app timer (pause)** | [`specs/planned/in-app-timer.md`](../specs/planned/in-app-timer.md) | Competitor core loop; accurate time stats |

## 1.2.0 — richer metadata

| Idea | Spec | Notes |
|------|------|-------|
| **Multi-photo gallery** | [`specs/planned/multi-photo-gallery.md`](../specs/planned/multi-photo-gallery.md) | Cover + WIP/progress shots |
| **Purchase location** | [`specs/planned/purchase-location.md`](../specs/planned/purchase-location.md) | ✅ Shipped in 1.0.1 |
| **Year + puzzle type** | [`specs/planned/year-and-puzzle-type.md`](../specs/planned/year-and-puzzle-type.md) | ✅ Shipped in 1.0.1 |
| **Disposition after complete** | [`specs/planned/disposition-after-complete.md`](../specs/planned/disposition-after-complete.md) | ✅ Shipped in 1.0.1 |
| **Material + artist fields** | In roadmap | Material ✅ in 1.0.1; artist still deferred |

## 1.3.0 — delight & platform

| Idea | Spec | Notes |
|------|------|-------|
| **Milestones + year in review** | [`specs/planned/milestones-year-in-review.md`](../specs/planned/milestones-year-in-review.md) | Basic milestones ✅ in 1.0.1; year-in-review deferred |
| **Home screen widget** | [`specs/planned/home-screen-widget.md`](../specs/planned/home-screen-widget.md) | In-progress puzzle or random To-Do |
| **Localization** | Roadmap Phase 3 | English-only in 1.0 |
| **iPad sidebar navigation** | Roadmap | Regular size class polish |

## Defer (competitor long tail)

- Re-do / multiple timed attempts per puzzle
- Custom fields / folders (Puzzle Tracker premium)
- Friend sharing / social lists
- Bulk barcode batch entry
- Exclude-mode filter chips
- Box photo OCR (Vision)

## Related

- [`docs/roadmap.md`](../docs/roadmap.md) — release strategy + competitive positioning
- [`docs/release/todo.md`](../docs/release/todo.md) — App Store 1.0 checklist
