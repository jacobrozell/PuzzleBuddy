# Pick my next puzzle

**Shipped:** 1.0.0  
**Flag:** `ProductService.isPickNextEnabled` (default `true`)

## Behavior

- Collection toolbar → dice button → sheet
- Random from To-Do backlog; optional include In-Progress
- Filter by piece count and tag
- Excludes Wishlist and Completed
- Open picked puzzle from result card

## Code

- `PuzzleRandomPicker.swift`, `PickNextPuzzleView.swift`
- Tests: `PuzzleRandomPickerTests.swift`
