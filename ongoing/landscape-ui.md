# Landscape UI plan

**Goal:** Make Puzzle Buddy usable and intentional in landscape — recover vertical space on iPhone landscape and use the width on iPad.
**Context:** Phase 2 added `AdaptiveLayout`, `readableContentWidth`, and side-by-side detail. The remaining pain is the collection list: the persistent filter header eats short landscape height (≈1 visible row), and iPad landscape leaves a narrow centered column with wasted side space.
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done

**Last updated:** 2026-06-29

---

## Fixes landed (out of band)

- [x] **Sticky filter band cut off in landscape** — the `statusFilterPicker` background + divider stopped at the horizontal safe-area inset (Dynamic Island side), leaving a white gutter. Background now `.ignoresSafeArea(edges: .horizontal)` so it bleeds edge-to-edge. Verified on iPhone 17 Pro real landscape. (`PuzzleList.swift`)

## Symptoms (current)

- iPhone landscape: `statusFilterPicker` pinned as top `safeAreaInset` stacks 4 rows (segmented status, search, result count, filter chips) → list shows ~1 row; FAB + tab bar crowd the bottom.
- iPad landscape: list/detail centered to `contentMaxWidth` with large empty gutters; bottom `TabView` wastes the wide canvas.
- Onboarding / sheets (Form, QuickAdd, Shopping, PickNext) untested at compact height + keyboard.

---

## Sprint order

| # | Item | Effort | Status | Phase |
|---|------|--------|--------|-------|
| 1 | [Condense list filter header at compact height](#1-condense-filter-header) | M | [x] | 1.0 (ship) |
| 2 | [FAB + tab-bar clearance in landscape](#2-fab-tab-bar-clearance) | S | [x] | 1.0 (ship) |
| 3 | [Multi-column puzzle list on regular width](#3-multi-column-list) | M | [x] | 1.0 (ship) |
| 4 | [Onboarding compact-height layout](#4-onboarding-compact-height) | S | [ ] | 1.0 (ship) |
| 5 | [Sheet/keyboard scroll audit in landscape](#5-sheet-keyboard-audit) | S | [ ] | 1.0 (ship) |
| 6 | [Stats grid scales to width](#6-stats-grid-width) | S | [ ] | Polish |
| 7 | [`NavigationSplitView` list+detail on iPad](#7-split-view-ipad) | L | [ ] | 1.1 |

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
- [ ] Shrink hero and tighten spacers when `verticalSizeClass == .compact`; make page content scrollable so footer buttons stay reachable.

**Files:** `OnboardingView.swift`

---

## 5. Sheet/keyboard audit

**Problem:** Form / QuickAdd / Shopping / PickNext sheets unverified at compact height with keyboard up.

**Deliverables:**
- [ ] Confirm each sheet scrolls and the focused field stays visible above the keyboard in landscape; apply `adaptiveScrollChrome`/scroll where missing.

**Files:** `PuzzleForm.swift`, `QuickAddPuzzleSheet.swift`, `ShoppingModeView.swift`, `PickNextPuzzleView.swift`

---

## 6. Stats grid width

**Deliverables:**
- [ ] Use adaptive columns (`GridItem(.adaptive(minimum:))` or 3–4 columns at regular width) so stat cards fill iPad landscape instead of stretching 2 wide.

**Files:** `CollectionStatsView.swift`

---

## 7. NavigationSplitView on iPad (1.1)

**Deliverables:**
- [ ] On regular width, replace per-tab `NavigationStack` push with `NavigationSplitView` (collection list as sidebar, detail on the right) so landscape shows list + detail simultaneously.
- [ ] Evaluate sidebar tabs vs. bottom `TabView` for iPad.

**Files:** `PuzzleTabbar.swift`, `PuzzleList.swift`, `PuzzleDetail.swift`

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
