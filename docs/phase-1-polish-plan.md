# Phase 1 polish plan

**Goal:** Demo-ready app before TestFlight outreach to IPDb and the puzzle community.  
**Strategy:** [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) — polish first, then TestFlight with migration path.

**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done

---

## Sprint order

| # | Item | Effort | Status | Notes |
|---|------|--------|--------|-------|
| 1 | [Search: brand, barcode, source](#1-search-brand-barcode-source) | S | [x] | `PuzzleListQuery` |
| 2 | [Import UX: photo reminder + needs-photo filter](#2-import-ux-photo-reminder) | S | [x] | Summary sheet + list filter |
| 3 | [Onboarding refresh](#3-onboarding-refresh) | S | [x] | Barcode, shopping, IPDb import |
| 4 | [IPDb export fixture + import mapping tests](#4-ipdb-export-fixture) | S | [x] | `Fixtures/ipdb-sample-export.csv` |
| 5 | [Collection export (backup)](#5-collection-export) | M | [x] | JSON + IPDb-compatible CSV |
| 6 | [List polish](#6-list-polish) | S | [x] | Brand on row, sort defaults per tab |
| 7 | [Filter: piece-count chips](#7-piece-count-filter) | M | [x] | Menu on collection list |
| 8 | [Shopping → quick-add handoff](#8-shopping-quick-add) | S | [x] | Already shipped |
| 9 | [Box photo OCR (Vision)](#9-box-photo-ocr) | L | | Post-1.0 stretch if time runs out |
| 10 | [Pre-ship hygiene](#10-pre-ship-hygiene) | M | [x] | Docs synced, UI smoke tests, device QA matrix |

---

## 1. Search: brand, barcode, source

**Problem:** Search is name-only; IPDb migrants and shoppers search by brand and UPC.

**Deliverables:**
- [ ] `PuzzleListQuery.search` matches `name`, `source`, and `barcode` (case-insensitive; barcode digit-normalized)
- [ ] Search field hint/label: "Search name, brand, or barcode"
- [ ] Unit tests in `PuzzleListFilterTests` or `PuzzleListQueryTests`

**Files:** `PuzzleListQuery.swift`, `PuzzleList.swift`, tests

---

## 2. Import UX: photo reminder

**Problem:** IPDb CSV has no images; users don't know to re-add photos.

**Deliverables:**
- [ ] `IPDbImportSummarySheet` — section when `imported > 0`: photos not in CSV; add from puzzle detail
- [ ] List filter **Needs photo** (`imageData == nil`) alongside missing-pieces toggle
- [ ] `PuzzleListQuery.filterNeedsPhoto`
- [ ] A11y IDs for new controls

**Files:** `IPDbImportSummarySheet.swift`, `PuzzleList.swift`, `PuzzleListQuery.swift`, `DesignTokens.swift`

---

## 3. Onboarding refresh

**Problem:** Onboarding describes 2022 catalog only; misses barcode, shopping, import.

**Deliverables:**
- [ ] Update or add onboarding page: offline duplicate-check, IPDb CSV import, local-first
- [ ] Keep 4-page flow; refresh copy on existing pages where needed

**Files:** `OnboardingView.swift`

---

## 4. IPDb export fixture

**Problem:** Unit tests use synthetic CSV; real IPDb column names may differ.

**Deliverables:**
- [ ] `Puzzle BuddyTests/Fixtures/ipdb-sample-export.csv` (anonymized realistic export)
- [ ] Tests: parse fixture, map status/progress/rating, end-to-end import
- [ ] Fix any mapping gaps (in-progress `progressPercent`, wishlist → To-Do)

**Files:** `IPDbCSVImporter.swift`, `IPDbCSVImporterTests.swift`, `PuzzleStoreTests.swift`

---

## 5. Collection export

**Problem:** No backup path for large collections (user research P1).

**Deliverables:**
- [ ] Settings → **Export collection** (JSON primary; CSV optional for spreadsheets)
- [ ] Share sheet via `ShareLink` / `UIActivityViewController`
- [ ] Export includes all puzzle fields except raw image bytes in CSV (or base64 in JSON)
- [ ] Unit tests for export encoder
- [ ] Doc: `docs/collection-export.md` (brief)

**Files:** new `PuzzleCollectionExporter.swift`, `SettingsView.swift`, tests

---

## 6. List polish

**Deliverables:**
- [ ] `PuzzleCell` — show `source` under name when set
- [ ] Default sort: **Name** when status filter is To-Do or In-Progress; **Date** for Completed / All (or persist per-tab)

**Files:** `PuzzleCell.swift`, `PuzzleList.swift`

---

## 7. Piece-count filter

**Deliverables:**
- [ ] Filter chips or menu: Any, ≤500, 1000, 1500+
- [ ] Wire through `PuzzleListQuery.apply`
- [ ] Result count reflects active piece filter

**Files:** `PuzzleListQuery.swift`, `PuzzleList.swift`

---

## 8. Shopping → quick-add

**Deliverables:**
- [ ] `ShoppingModeView` no-match state: **Add to collection** opens quick-add with barcode prefilled
- [ ] Dismiss shopping sheet or stack quick-add sheet

**Files:** `ShoppingModeView.swift`, `PuzzleList.swift` (if callback needed)

---

## 9. Box photo OCR (Vision)

**Stretch** — see [barcode-metadata-strategy.md](barcode-metadata-strategy.md).

**Deliverables:**
- [ ] Scan box photo → suggest title, pieces, brand on add form
- [ ] On-device `VNRecognizeTextRequest`; no network
- [ ] Spec stub: `docs/spec-box-ocr.md` when started

---

## 10. Pre-ship hygiene

| Task | Status |
|------|--------|
| Sync `features.md`, `roadmap.md`, `ipdb-partnership-outreach.md` with shipped behavior | [x] |
| UI test: Settings import button present | [x] |
| UI test: export button present | [x] |
| Device QA matrix (camera, Files, VoiceOver) | [x] — [device-qa-matrix.md](device-qa-matrix.md) |
| App Store screenshots (shopping, import, collection) | Owner |
| WCAG: form VO labels, Reduce Motion on brand chrome | [x] — ratings/shopping/import done |

---

## Verification

After each sprint item:

```bash
xcodegen generate
xcodebuild -scheme "Puzzle Buddy" -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Puzzle BuddyTests" test
```

Manual smoke:

1. Import sample IPDb CSV → see photo reminder
2. Filter **Needs photo** → only puzzles without images
3. Search by brand and barcode
4. Export collection → open in Files
5. Shopping mode no-match → quick-add

---

## Progress log

| Date | Item | Commit / notes |
|------|------|----------------|
| 2026-06-17 | Plan created | `docs/phase-1-polish-plan.md` |
| 2026-06-17 | Items 1–8 (except OCR) | Search, import UX, onboarding, fixture tests, export, list polish, filters, shopping already had quick-add |
| 2026-06-17 | Item 10 + Phase 2 landscape/a11y | Docs sync, UI smoke tests, device QA matrix, landscape detail/filters, a11y sweep |
