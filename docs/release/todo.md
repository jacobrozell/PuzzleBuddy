# Puzzle Buddy — release todo

Status legend: `[ ]` todo · `[x]` done

Strategy: [`../roadmap.md`](../roadmap.md) · Shipped scope: [`../features.md`](../features.md) · Inventory: [`../feature-inventory.md`](../feature-inventory.md)

## 1.1.0 App Store — shipped

- [x] **Released** — 1.1.0 build 5 approved and live on the App Store (2026-11-02)
- [x] **iPhone Duo readiness** — size-class layout + top-edge fill; Xcode 27.1; Duo sim smoke — [`../../ongoing/iphone-duo-1.1.0.md`](../../ongoing/iphone-duo-1.1.0.md)
- [x] Review-lane fixes — [`../../ongoing/1.1.0-review-fixes.md`](../../ongoing/1.1.0-review-fixes.md)
- [x] **Connect version** `1.1.0`. Build 4 stayed internal-only / unattached. Release run 5 (`9cec6b98-935e-4e8d-978e-35dfb48a0439`) was the App Store archive.
- [x] **Select build 5 and submit** — submitted 2026-11-02; approved and released same day. Minimum iOS 18.0.
- [x] **Notes for Review / What’s New / description** — pasted from [`1.1.0-connect-paste.md`](1.1.0-connect-paste.md)
- [x] **Screenshots** — Duo set processed: 6 outer (1398×2034) and inner list, duplicate check, stats, Floral Arch (2853×2007). Inner on-loan and settings hit the 10-image cap. iPhone 6.5" and iPad 13" left as already in Connect. First frame is the catalog list.
- [x] **Privacy + support Pages** — live and matching 1.1 (timer bucket, borrower names, Delete All Data)
- [x] **Nutrition / privacy label** — leave the accepted 1.0 label: Product Interaction, Performance Data, Crash Data. Not linked, not tracking. Photos and borrower names stay on device, so they are not collected.
- [x] **Age 4+** and export-compliance exemption — re-confirm, no change expected
- [x] AppUITests on iPhone 17 · units cover migrate / history / loan

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

- [ ] **Landscape + iPad** — quick wins + split view shipped (see [`../../ongoing/landscape-ui.md`](../../ongoing/landscape-ui.md)); manual sign-off still recommended
- [x] **Generic UPC API lookup** — evaluated and removed; barcode enrichment is on-device only
- [x] **Onboarding** — update after sprint for IPDb import + new features
- [x] **Unit tests** — 163+ passing

## Removed from 1.0 scope (moved into expanded sprint)

- ~~IPDb CSV import / collection export~~ → **1.0 expanded sprint**

## Still post-1.1

- 1.1.1 file split — [`../implementation/1.1.1-file-split.md`](../implementation/1.1.1-file-split.md)
- Timer sessions / Focus / forgot-to-pause (→ next version) — [`../implementation/1.2.0-timer-redesign.md`](../implementation/1.2.0-timer-redesign.md)
- Box photo OCR (→ later)
- JSON backup restore UI (deferred; not in 1.1.0)
