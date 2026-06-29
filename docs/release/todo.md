# Puzzle Buddy — release todo

Status legend: `[ ]` todo · `[x]` done

Strategy: [`../roadmap.md`](../roadmap.md) · Shipped scope: [`../features.md`](../features.md) · Inventory: [`../feature-inventory.md`](../feature-inventory.md)

## 1.0.0 App Store

- [x] **No login / cloud sync** — Auth, Firestore, FCM removed from app (June 2026)
- [ ] **Expanded feature sprint** — see [`../implementation/1.0.0-expanded-feature-sprint.md`](../implementation/1.0.0-expanded-feature-sprint.md)
  - [ ] Un-gate IPDb import/export
  - [ ] Purchase price
  - [ ] Shape, dimensions, cut type
  - [ ] Multi-photo gallery
  - [ ] Redo + completion history
- [x] **`isCollectionImportExportEnabled = false`** — **changing:** un-gate in expanded sprint
- [x] **Pick my next puzzle** — shipped; dice on collection list
- [x] **Wishlist + progress over days** — shipped
- [x] **GitHub Pages** — privacy + support URLs live
- [x] **Marketing screenshots** — captured in `marketing-screenshots/` (Connect upload still required)
- [ ] **Device smoke** — add puzzle → filters → pick-next → detail → stats
- [ ] **WCAG core journey** — VoiceOver manual audit ([`../accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md))
- [ ] **App Store Connect** — see [`app-store-connect.md`](app-store-connect.md)
  - [x] App name confirmed: **Puzzle Buddy: Jigsaw Tracker** (see naming section in checklist)
  - [x] Verify exact name accepted when creating Connect app record
  - [ ] Paste subtitle, keywords, promotional text, description (ASO section)
  - [ ] Upload screenshots; first frame reads as catalog app

## Pre-submit

- [ ] **Landscape + iPad** — Phase 2 layout sign-off
- [x] **Generic UPC API lookup** — evaluated and removed; barcode enrichment is on-device only
- [x] **Onboarding** — update after sprint for IPDb import + new features
- [x] **Unit tests** — 163+ passing

## Removed from 1.0 scope (moved into expanded sprint)

- ~~IPDb CSV import / collection export~~ → **1.0 expanded sprint**

## Still post-1.0

- In-app timer (→ 1.1.0)
- JSON backup restore UI (→ 1.1.0)
- Box photo OCR (→ 1.2.0)
