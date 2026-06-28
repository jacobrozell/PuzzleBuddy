# Puzzle Buddy — release todo

Status legend: `[ ]` todo · `[x]` done

Strategy: [`../roadmap.md`](../roadmap.md) · Shipped scope: [`../features.md`](../features.md) · Inventory: [`../feature-inventory.md`](../feature-inventory.md)

## 1.0.0 App Store

- [x] **`isLoginEnabled = false`** — verified in Release (no login surfaces)
- [x] **`isCollectionImportExportEnabled = false`** — IPDb import + JSON/CSV export hidden (dogfood: `-enable_collection_import_export`)
- [x] **Pick my next puzzle** — shipped; dice on collection list
- [x] **Wishlist + progress over days** — shipped
- [x] **GitHub Pages** — privacy + support URLs live
- [ ] **Marketing screenshots** — local-first, barcode shopping, pick-next, stats
- [ ] **Device smoke** — add puzzle → filters → pick-next → detail → stats
- [ ] **WCAG core journey** — VoiceOver manual audit ([`../accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md))
- [ ] **App Store Connect** — see [`app-store-connect.md`](app-store-connect.md)

## Pre-submit

- [ ] **Landscape + iPad** — Phase 2 layout sign-off
- [x] **Generic UPC API lookup** — evaluated and removed; barcode enrichment is on-device only
- [x] **Onboarding** — no IPDb/import claims in 1.0 copy
- [x] **Unit tests** — 174+ passing

## Removed from 1.0 scope

- IPDb CSV import / collection export (→ 1.1.0, [`../../specs/planned/collection-import-export.md`](../../specs/planned/collection-import-export.md))
