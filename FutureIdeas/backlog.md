# Puzzle Buddy — future ideas

Prioritized backlog from product review (2026-06-27). Shipped behavior lives in [`docs/feature-inventory.md`](../docs/feature-inventory.md).

## 1.0.0 (inaugural — pre-ship)

Not yet on the App Store. See [`docs/implementation/1.0.0-pre-ship-sprint.md`](../docs/implementation/1.0.0-pre-ship-sprint.md).

| Item | Status | Notes |
|------|--------|-------|
| Pick my next puzzle | ✅ In build | Dice on collection list + Stats tab; filters by tag + piece count |
| Wishlist status | ✅ In build | Separate from owned To-Do; excluded from random pick |
| Progress over days | ✅ In build | `startDate` + “days puzzling” / “finished in N days” on detail |
| Abandoned status + start-date picker | ✅ In build | Quit tab; manual start date on form |
| Stats: wishlist, avg days, milestones | ✅ In build | Collection stats cards + milestone banner |
| Metadata: purchase location, year, type, material, disposition | ✅ In build | Form, detail, list filters, stats |
| Collection import/export | ⏸ Gated | Off for 1.0.0; launch arg `-enable_collection_import_export` for dogfood |

## 1.1.0 — migration & backup

| Idea | Spec | Notes |
|------|------|-------|
| **IPDb CSV import + JSON/CSV export** | [`specs/planned/collection-import-export.md`](../specs/planned/collection-import-export.md) | Re-enable `ProductService.isCollectionImportExportEnabled` |
| **JSON backup restore** | [`specs/planned/json-backup-restore.md`](../specs/planned/json-backup-restore.md) | Pair export with import; include photos in v2 |
| **Auth + cloud sync** | [`specs/planned/auth-cloud-sync.md`](../specs/planned/auth-cloud-sync.md) | **Removed from app** — spec only for future |
| **In-app timer (pause)** | [`specs/planned/in-app-timer.md`](../specs/planned/in-app-timer.md) | Competitor core loop; accurate time stats |

## 1.2.0 — richer catalog

| Idea | Spec | Notes |
|------|------|-------|
| **Multi-photo gallery** | [`specs/planned/multi-photo-gallery.md`](../specs/planned/multi-photo-gallery.md) | Cover + WIP/progress shots |
| **Artist field** | In roadmap | Separate from brand; not in 1.0.0 |

## 1.3.0 — delight & platform

| Idea | Spec | Notes |
|------|------|-------|
| **Year in review (full)** | [`specs/planned/milestones-year-in-review.md`](../specs/planned/milestones-year-in-review.md) | Basic milestones in 1.0.0; share cards / annual recap later |
| **Home screen widget** | [`specs/planned/home-screen-widget.md`](../specs/planned/home-screen-widget.md) | In-progress puzzle or random To-Do |
| **Localization** | Roadmap Phase 3 | English-only in 1.0.0 |
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
