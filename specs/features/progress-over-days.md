# Progress over days

**Shipped:** 1.0.0

## Behavior

- `startDate` on puzzle record; auto-set when entering In-Progress
- Detail shows “X days puzzling” (in progress) or “Finished in X days” (completed)
- Legacy puzzles without `startDate` fall back to completion/started date field

## Code

- `PuzzleDateSemantics.swift`, `PuzzleObject.noteStatusChanged(from:to:)`
- Tests: `PuzzleDateSemanticsTests.swift`
