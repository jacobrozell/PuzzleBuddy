# VoiceOver script — Puzzle form

Expected reading order for `PuzzleForm` / `PuzzleFormInternal`.

## Preconditions

- User signed in
- Add puzzle sheet open or edit flow active

## Reading order (target)

| # | Element | Expected announcement | Status |
|---|---------|----------------------|--------|
| 1 | Image picker | "Add photo" or equivalent | Planned |
| 2 | Name field | "Name, text field" + value | Partial |
| 3 | Pieces field | "Pieces, text field" | Partial |
| 4 | Rating | "Rating, X out of 5 stars" | Planned |
| 5 | Difficulty | "Difficulty, level X" | Planned |
| 6 | Time spent | Hours/minutes fields labeled | Partial |
| 7 | Completion date | Date picker labeled | Partial |
| 8 | Status | "Status, To-Do" / "Completed" | Partial |
| 9 | Save / Add button | Action button label | Partial |

## Pass criteria

- Every form field has a discernible name before editing
- Custom controls announce current value on focus
- Submit button reachable without leaving form context

## Known issues

- `RatingsView` uses star images without `accessibilityValue`
- `DifficultyView` may not expose selected level to VoiceOver
- Image picker button needs explicit label (Phase 2)
