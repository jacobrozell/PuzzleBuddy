# Landscape UI plan

**Goal:** Make Puzzle Buddy usable and intentional in landscape — recover vertical space on iPhone landscape and use the width on iPad.
**Context:** Phase 2 added `AdaptiveLayout`, `readableContentWidth`, and side-by-side detail. The remaining pain is the collection list: the persistent filter header eats short landscape height (≈1 visible row), and iPad landscape leaves a narrow centered column with wasted side space.
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done

**Last updated:** 2026-06-29

---

## Fixes landed (out of band)

- [x] **Sticky filter band cut off in landscape** — the `statusFilterPicker` background + divider stopped at the horizontal safe-area inset (Dynamic Island side), leaving a white gutter. Background now `.ignoresSafeArea(edges: .horizontal)` so it bleeds edge-to-edge. Verified on iPhone 17 Pro real landscape. (`PuzzleList.swift`)
- [x] **iPad split sidebar filter clipping** — six-segment status control clipped in the narrow sidebar column; replaced with menu picker + filter sheet for secondary filters, inline search only. Unified flat `brandScreenChrome` on split columns (no gradient seam). (`PuzzleList.swift`, `PuzzleTabbar.swift`, `DesignTokens.swift`)
- [x] **iPad workflow sheets** — add puzzle, quick add, shopping mode, pick next, barcode scanner, and duplicate-scan result use `adaptiveLongFormSheet` (full-screen cover on iPad regular width; large sheet on iPhone). (`AdaptiveLayout.swift`, `PuzzleList.swift`, `CollectionStatsView.swift`, `PuzzleForm.swift`)

## Symptoms (current)

- iPhone landscape: `statusFilterPicker` pinned as top `safeAreaInset` stacks 4 rows (segmented status, search, result count, filter chips) → list shows ~1 row; FAB + tab bar crowd the bottom. **Mitigated** by compact filter sheet.
- iPad landscape: list/detail centered to `contentMaxWidth` with large empty gutters; bottom `TabView` wastes the wide canvas. **Deferred** — see [1.1 backlog](#11-backlog-deferred).
- Filter/tag sheets on iPad still use standard sheet detents (low priority; filters are inline on regular width).

---

## Sprint order

| # | Item | Effort | Status | Phase |
|---|------|--------|--------|-------|
| 1 | [Condense list filter header at compact height](#1-condense-filter-header) | M | [x] | 1.0 (ship) |
| 2 | [FAB + tab-bar clearance in landscape](#2-fab-tab-bar-clearance) | S | [x] | 1.0 (ship) |
| 3 | [Multi-column puzzle list on regular width](#3-multi-column-list) | M | [x] | 1.0 (ship) |
| 4 | [Onboarding compact-height layout](#4-onboarding-compact-height) | S | [x] | 1.0 (ship) |
| 5 | [Sheet/keyboard scroll audit in landscape](#5-sheet-keyboard-audit) | S | [x] | 1.0 (ship) |
| 6 | [Stats grid scales to width](#6-stats-grid-width) | S | [x] | 1.0 (ship) |
| 7 | [`NavigationSplitView` list+detail on iPad](#7-split-view-ipad) | L | [x] | 1.0 (ship) |

---

## 1. Condense filter header

**Problem:** Header consumes most of landscape height; only ~1 list row remains.

**Deliverables:**
- [x] At `verticalSizeClass == .compact`, collapse the header to a single row: status `Picker` + a `filterSheetButton` that opens search + chips in a sheet, instead of always-on stacked rows.
- [x] Result count + clear move into the sheet; no separate header row when collapsed.
- [x] Preserve all existing accessibility identifiers; add `puzzleListFilterButton`.

**Files:** `PuzzleList.swift` (`compactFilterHeader`/`regularFilterHeader`/`filterSheet`), `DesignTokens.swift`

---

## 2. FAB + tab-bar clearance

**Problem:** FAB and floating tab bar overlap the last visible row in landscape.

**Deliverables:**
- [x] Bottom `safeAreaInset` reserves clearance at compact height so the last row clears the FAB.
- [ ] Verify FAB stays reachable above the tab bar at all Dynamic Type sizes (manual).

**Files:** `PuzzleList.swift`

---

## 3. Multi-column list

**Problem:** Single centered column wastes iPad/landscape width.

**Deliverables:**
- [x] On `horizontalSizeClass == .regular`, render puzzles in an adaptive `LazyVGrid` (min 320pt) instead of a single-column `List`; compact width keeps the `List`.
- [x] Delete moved to a `contextMenu` (plus existing VO action) so grid mode can delete.
- [x] Selection → detail navigation preserved (`PuzzleCell` `NavigationLink`).

**Files:** `PuzzleList.swift` (`puzzleCollection`/`puzzleGrid`/`puzzleListView`), `PuzzleCell.swift`

---

## 4. Onboarding compact-height

**Problem:** Hero (180pt) + copy + footer can overflow short landscape pages.

**Deliverables:**
- [x] Shrink hero and tighten spacers when `verticalSizeClass == .compact`; make page content scrollable so footer buttons stay reachable.

**Files:** `OnboardingView.swift`

---

## 5. Sheet/keyboard audit

**Problem:** Form / QuickAdd / Shopping / PickNext sheets unverified at compact height with keyboard up.

**Deliverables:**
- [x] iPad regular width: workflow modals use full-screen cover via `adaptiveLongFormSheet`.
- [x] `PuzzleFormInternal` uses `adaptiveScrollChrome` for compact-height keyboard scroll.
- [x] `QuickAddPuzzleSheet` already had `adaptiveScrollChrome`; `PickNextPuzzleView` uses `ScrollView`.

**Files:** `PuzzleForm.swift`, `QuickAddPuzzleSheet.swift`, `ShoppingModeView.swift`, `PickNextPuzzleView.swift`, `AdaptiveLayout.swift`, `PuzzleList.swift`, `CollectionStatsView.swift`

---

## 6. Stats grid width

**Deliverables:**
- [x] Use adaptive columns (`GridItem(.adaptive(minimum: 220))` at regular width; 2 flexible columns on compact) via `AdaptiveLayout.statsGridColumns`.

**Files:** `CollectionStatsView.swift`, `AdaptiveLayout.swift`

---

## 7. NavigationSplitView on iPad (1.0)

**Deliverables:**
- [x] On regular width, `PuzzleList` uses `NavigationSplitView` — collection list in sidebar, detail on the right.
- [x] Programmatic navigation (shopping mode, marketing snapshots) sets `selectedPuzzleID` on iPad.
- [x] iPhone keeps `NavigationStack` + `NavigationLink` push.
- [ ] Evaluate sidebar tabs vs. bottom `TabView` for iPad (deferred).

**Files:** `PuzzleTabbar.swift`, `PuzzleList.swift`, `PuzzleCell.swift`, `AdaptiveLayout.swift`

---

## 1.1 backlog (deferred)

| Item | Notes |
|------|--------|
| Sidebar-adaptable `TabView` (iOS 18+) | Less bottom chrome on iPad |
| Widen `contentMaxWidth` on 13" iPad | Stats/list feel letterboxed above ~1020pt |
| iPad filter/tag sheets | Inline filters on regular width today; sheet polish optional |
| Multi-column grid browse mode | Superseded by split list + detail; revisit if needed |

---

## Verification

```bash
cd PuzzleBuddy && xcodegen generate
xcodebuild -scheme PuzzleBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:"AppTests" test
```

Manual (rotate to landscape):

1. Collection list shows ≥3 rows; filters reachable; FAB clear of tab bar.
2. iPad landscape uses full width (multi-column list / split view).
3. Onboarding footer buttons reachable on every page.
4. Each add/scan sheet scrolls with keyboard up.
