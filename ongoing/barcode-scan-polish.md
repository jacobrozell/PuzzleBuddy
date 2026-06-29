# Barcode scan polish plan

**Goal:** Make local-only barcode flows feel intentional after removing generic UPC API lookup.  
**Context:** Duplicate check and quick-add suggestions use on-device data only (`BarcodeMetadataCache`).  
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done

**Last updated:** 2026-06-29

---

## Sprint order

| # | Item | Effort | Status | Phase |
|---|------|--------|--------|-------|
| 1 | [Copy & expectations](#1-copy--expectations) | S | [x] | Quick wins |
| 2 | [Source puzzle in cache + quick-add UI](#2-source-puzzle-in-cache) | S | [x] | Quick wins |
| 3 | [Unify duplicate UX (list scan)](#3-unify-duplicate-ux) | S | [x] | Quick wins |
| 4 | [Scan feedback (haptic)](#4-scan-feedback) | S | [x] | Quick wins |
| 5 | [Shared scan result card](#5-shared-scan-result-card) | S | [x] | Quick wins |
| 6 | [Torch toggle on scanner](#6-torch-toggle) | S | [x] | Quick wins |
| 7 | [Inline duplicate hint on form](#7-inline-duplicate-on-form) | M | [x] | Medium |
| 8 | [Tappable similar matches in quick-add](#8-tappable-similar-matches) | M | [ ] | Medium |
| 9 | [Clarify scan paths in UI](#9-clarify-scan-paths) | S | [x] | Medium |
| 10 | [Smarter title scrubbing + suggested badges](#10-smarter-scrubbing) | M | [~] | Medium |
| 11 | [Shopping session stats](#11-shopping-session-stats) | M | [x] | Medium |
| 12 | [Help: How barcodes work](#12-help-how-barcodes-work) | S | [x] | Medium |
| 13 | [Attach barcode to existing puzzle](#13-attach-barcode-to-existing) | M | [ ] | Post-1.0 |
| 14 | [Box photo OCR (Vision)](#14-box-photo-ocr) | L | [ ] | Post-1.0 |

---

## 1. Copy & expectations

**Problem:** Empty quick-add and shopping copy still read like a failed online lookup.

**Deliverables:**
- [x] `LegalCopy.barcodeScanDisclaimer` on quick-add and puzzle form
- [x] Shopping no-match header: **"Not in your collection"** (not "Safe to buy")
- [x] Quick-add first-scan section when cache misses
- [x] Remove "No product details found" API-era wording

**Files:** `ShoppingModeView.swift`, `QuickAddPuzzleSheet.swift`

---

## 2. Source puzzle in cache

**Problem:** "From your saved puzzles" is vague; users should see which entry prefilled the form.

**Deliverables:**
- [x] `CachedBarcodeEntry` stores `sourcePuzzleID` + `sourcePuzzleName`
- [x] `BarcodeProductMetadata` exposes source fields + dynamic label
- [x] Quick-add shows source name; thumbnail when puzzle still exists

**Files:** `BarcodeMetadataCache.swift`, `BarcodeProductMetadata.swift`, `QuickAddPuzzleSheet.swift`, tests

---

## 3. Unify duplicate UX

**Problem:** Toolbar scan shows alert on duplicate; shopping mode shows rich card with thumbnail.

**Deliverables:**
- [x] List scan duplicate → sheet with same result card as shopping
- [x] Actions: Open puzzle, Scan another

**Files:** `PuzzleList.swift`, `BarcodeScanResultCard.swift`

---

## 4. Scan feedback

**Deliverables:**
- [x] Success haptic when list scan proceeds to quick-add
- [x] Warning haptic on duplicate (shopping + list)

**Files:** `BarcodeScanFeedback.swift`, `PuzzleList.swift`, `BarcodeScannerSheet.swift`

---

## 5. Shared scan result card

**Deliverables:**
- [x] Extract `BarcodeScanResultCard` from `ShoppingModeView`
- [x] Used by shopping mode and list duplicate sheet

**Files:** `Views/Barcode/BarcodeScanResultCard.swift`

---

## 6. Torch toggle

**Deliverables:**
- [x] Torch button overlay on `BarcodeScannerSheet` + shopping scanner
- [x] Falls back gracefully when torch unavailable (simulator)

**Files:** `BarcodeScannerTorchButton.swift`, scanner sheets

---

## 7. Inline duplicate on form

**Deliverables:**
- [x] Live hint under barcode field when digits match an existing puzzle
- [x] Message naming the matching puzzle

**Files:** `PuzzleForm.swift`

---

## 8. Tappable similar matches

**Deliverables:**
- [ ] Quick-add "Looks similar" rows open existing puzzle or confirm keep adding
- [ ] Optional "Add barcode to this puzzle" when similar but barcode is new

**Files:** `QuickAddPuzzleSheet.swift`, `PuzzleList.swift`

---

## 9. Clarify scan paths

**Deliverables:**
- [x] FAB menu subtitle: scan to add vs toolbar icon for duplicate check
- [ ] Optional first-use tip (UserDefaults flag)

**Files:** `PuzzleList.swift`, `docs/support.html`

---

## 10. Smarter scrubbing

**Deliverables:**
- [x] Trailing jigsaw junk cleanup in `BarcodeTitleParser`
- [ ] Skip auto-fill piece count when parse confidence is low
- [ ] Visual "Suggested" treatment on prefilled fields

**Files:** `BarcodeTitleParser.swift`, `QuickAddPuzzleSheet.swift`, tests

---

## 11. Shopping session stats

**Deliverables:**
- [x] Running count in shopping mode: scanned / duplicates / new
- [x] Resets when sheet dismisses

**Files:** `ShoppingModeView.swift`

---

## 12. Help: How barcodes work

**Deliverables:**
- [x] Settings → Help footer: offline duplicate check, local suggestions, review before save
- [ ] Align `docs/support.html` with scan-path copy

**Files:** `SettingsView.swift`, docs

---

## 13. Attach barcode to existing puzzle

**Deliverables:**
- [ ] From quick-add similar match: "Use this puzzle" attaches barcode instead of creating duplicate entry

**Files:** `QuickAddPuzzleSheet.swift`, `PuzzleStore.swift`

---

## 14. Box photo OCR

**Target:** 1.2.0 · **Spec:** [`specs/planned/box-photo-ocr.md`](../specs/planned/box-photo-ocr.md)

**Deliverables:**
- [ ] On-device Vision OCR on box photo → suggest title / brand / pieces when barcode cache misses
- [ ] Barcode remains duplicate key; OCR fills form only

**Files:** new helper + form integration · See [`FutureIdeas/backlog.md`](../FutureIdeas/backlog.md)

---

## Related

- [barcode-metadata-strategy.md](../docs/barcode-metadata-strategy.md)
- [spec-barcode-scanner.md](../docs/spec-barcode-scanner.md)
- [specs/features/barcode-quick-add.md](../specs/features/barcode-quick-add.md)
