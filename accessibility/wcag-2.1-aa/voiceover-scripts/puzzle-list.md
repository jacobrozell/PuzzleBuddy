# VoiceOver script — Puzzle list

Expected reading order for `PuzzleList` inside the Puzzles tab.

## Preconditions

- User signed in (or bypass mode with local data)
- Puzzles tab selected (`puzzles_tab`)
- At least one puzzle in list (for row tests)

## Reading order

| # | Element | Expected announcement | Identifier |
|---|---------|----------------------|------------|
| 1 | Navigation title | "Puzzles" or app section title | — |
| 2 | List container | "Puzzle collection" | `puzzle_list` |
| 3 | Row 1 | Puzzle name, pieces, rating (visible text) | — |
| 4 | … | Additional rows | — |
| 5 | Add puzzle | "Add puzzle, button" | `add_puzzle_button` |

## Actions

| Gesture | Expected |
|---------|----------|
| Double-tap row | Opens puzzle detail |
| Swipe up/down on row (VO) | May expose actions |
| Swipe left (touch) | Delete affordance |
| VO magic tap on delete | Removes puzzle |

## Pass criteria

- List label announced before or as part of list exploration
- Add button reachable after list or via rotor
- Row content includes puzzle name audibly

## Known issues

- Row may not announce rating as structured value (Phase 2)
- Image thumbnails may be announced without description
