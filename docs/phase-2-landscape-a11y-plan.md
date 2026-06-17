# Phase 2 — landscape & accessibility

**Goal:** Ship-ready layout on iPhone landscape and VoiceOver coverage on newer barcode/import flows.  
**Status:** Complete (2026-06-17)

---

## Landscape

| Item | Status | Notes |
|------|--------|-------|
| `usesWideDetailLayout` on iPhone landscape | [x] | `verticalSizeClass == .compact` |
| `readableContentWidth` on iPhone landscape | [x] | Same size-class rule as iPad |
| `PuzzleList` filter row wrap | [x] | Stacked layout in landscape; `ViewThatFits` for filter controls |
| `CollectionStatsView` grid | [x] | Already 2-column `LazyVGrid` |

**Files:** `AdaptiveLayout.swift`, `PuzzleList.swift`

**Tests:** `AdaptiveLayoutTests.swift` (unit), `testPuzzleListLandscapeLayout` (UI)

---

## Accessibility

| Screen | Status | Changes |
|--------|--------|---------|
| `QuickAddPuzzleSheet` | [x] | VO labels on fields/buttons; similar-match rows combined |
| `IPDbImportSummarySheet` | [x] | Done button ID; import-complete announcement |
| `ShoppingModeView` | [x] | Action button labels/hints; match announcements already present |
| `RatingsView` | [x] | Already exposes `accessibilityDescription` |
| `SplashView` | [x] | Already respects Reduce Motion |

**Files:** `QuickAddPuzzleSheet.swift`, `IPDbImportSummarySheet.swift`, `ShoppingModeView.swift`, `DesignTokens.swift`

**Tests:** `AccessibilityLabelTests`, `PuzzleAccessibilityUITests`

---

## Pre-ship hygiene (paired with phase 1 §10)

| Task | Status |
|------|--------|
| Sync `features.md`, `roadmap.md`, `ipdb-partnership-outreach.md` | [x] |
| Settings import/export UI smoke tests | [x] |
| Device QA matrix doc | [x] — [device-qa-matrix.md](device-qa-matrix.md) |
| Fix search field UI test label | [x] |
---

## Verification

```bash
xcodegen generate
xcodebuild -scheme "Puzzle Buddy" -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:"Puzzle BuddyTests" test
```

Manual:

1. Rotate iPhone to landscape on puzzle detail → summary + stats side by side
2. Rotate collection list → filters do not clip
3. VoiceOver through quick-add after shopping no-match
4. Import CSV → hear "Import complete" announcement
