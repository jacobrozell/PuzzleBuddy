# Puzzle physical metadata — shape, dimensions, cut type

**Status:** Planned · **Target:** 1.0.0  
**Sprint:** [1.0.0-expanded-feature-sprint.md](../../docs/implementation/1.0.0-expanded-feature-sprint.md)

## Problem

IPDb and serious collectors record box shape, finished dimensions, and cut style. Puzzle Buddy has type and material but not these optional physical attributes.

## Scope

| Field | Storage | UI |
|-------|---------|-----|
| `puzzleShape` | `PuzzleShape` enum → string on `PuzzleRecord` | Picker on form; detail row when not `.none` |
| `cutType` | `PuzzleCutType` enum → string | Picker on form; detail row when not `.none` |
| `dimensionsText` | Optional string, max 80 chars | TextField; free-form (`68 × 49 cm`) |

All optional — empty/none hides rows on detail (same pattern as material, type).

## Enums

**PuzzleShape:** none, rectangular, square, round, irregular  

**PuzzleCutType:** none, ribbon, grid, random, unknown  

Add to `PuzzleMetadataEnums.swift` with `selectableCases`, `displayLabel`, `accessibilityDescription` matching existing enums.

## Export

- JSON export: include all three fields
- IPDb CSV: append to Notes or dedicated columns if we extend export format without breaking re-import

## Out of scope

- Parsed width/height numerics with unit conversion
- Filter chips on list for shape/cut (defer unless trivial after form ships)

## Tests

- Round-trip persistence for each field
- Detail hides rows when unset
