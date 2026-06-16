# Spec: Garage collector scale-up

**Version:** 1.0 (implementation spec)  
**Persona:** Alex — ~1,000 puzzles in a garage; mixed statuses; some missing pieces  
**Research:** [user-research-garage-collector.md](user-research-garage-collector.md)  
**Status:** Phase 1 implemented (pending device QA sign-off)

---

## Goals

1. Track **condition** (missing pieces, notes) for thrift finds and incomplete puzzles.
2. Make **status and dates** trustworthy in list, detail, and form.
3. Surface **garage-relevant stats** (total owned, on the table, missing pieces).
4. Improve **findability** at scale (name sort, result count, missing-pieces filter).

Out of scope for Phase 1: barcode scan, export/import, location field, tags, pick-next, performance hardening.

---

## Phase 1 — Ship now

| ID | Feature | Schema | Files |
|----|---------|--------|-------|
| `status-dates` | Status-aware date labels + list status pill | No | `PuzzleDateSemantics`, `PuzzleCell`, `PuzzleDetail`, `PuzzleForm` |
| `field-notes-missing` | `hasMissingPieces` + `notes` | Yes | `PuzzleObject`, `PuzzleRecord`, form, list, detail |
| `stats-v2` | Total, in-progress, missing-piece counts | No* | `CollectionStats`, `CollectionStatsView` |
| `list-v2` | Name sort, result count, missing-pieces filter | No | `PuzzleListFilter`, `PuzzleList` |

\* `missingPiecesCount` uses new `hasMissingPieces` field.

### Phase 2 — Next

| ID | Feature |
|----|---------|
| `barcode-scan-a` | Barcode field + duplicate alert on save |
| `export-import` | JSON/CSV export from Settings |
| `field-location` | `storageLocation` + search |
| `list-filter-sheet` | Piece-count ranges, brand (when shipped) |
| `perf-images` | Lazy image load, search debounce |

### Phase 3 — Delight

| ID | Feature |
|----|---------|
| `pick-next` | Random from filtered backlog |
| `field-tags` | Multi-select tags + filter chips |
| `status-abandoned` | Abandoned / wishlist statuses |

---

## Data model

### New fields (`Puzzle` + `PuzzleRecord`)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `hasMissingPieces` | `Bool` | `false` | Filterable; shown on list/detail |
| `notes` | `String?` | `nil` | Free text; max 2,000 chars in UI |

Firestore / `getDataFields()` keys: `hasMissingPieces` (bool), `notes` (string or `"nil"`).

SwiftData: additive properties; existing rows default to `false` / `nil`.

---

## `status-dates` — Status-aware dates

### Semantics

`completionDate` remains the single date column. UI interprets by status until `startDate` ships:

| Status | List (right column) | Detail row label | Form section title |
|--------|---------------------|------------------|-------------------|
| To-Do | Hidden | "Added" | "Target date (optional)" |
| In-Progress | Hidden (pill only) | "Started" | "Started on" |
| Completed | Formatted date | "Completed" | "When did you finish {name}?" |

### List status pill

| Status | Label | Style |
|--------|-------|-------|
| To-Do | To-Do | `Brand.textSecondary` capsule |
| In-Progress | In progress | `Brand.accent` capsule |
| Completed | Completed | `Brand.accentSecondary` capsule |

### VoiceOver

- Do **not** say "Completed {date}" unless `status == .completed`.
- Include missing-pieces flag when set.

Implementation: `PuzzleDateSemantics` helper enum.

---

## `field-notes-missing`

### Form (`PuzzleFormInternal`)

New section **Condition**:

- Toggle: "Missing pieces" → `hasMissingPieces`
- `TextEditor` for notes (optional), 3–6 lines

### List (`PuzzleCell`)

- When `hasMissingPieces`: `exclamationmark.triangle.fill` + "Missing pieces" in footnote row
- Notes not shown on list (detail only)

### Detail (`DetailView`)

- Row: "Missing pieces" → Yes / No
- Row: "Notes" when non-empty

### Filter (`PuzzleList`)

- Toggle chip below search: **Missing pieces** — filters `hasMissingPieces == true` (works with status tabs + search)

---

## `stats-v2`

### New metrics (`CollectionStats`)

| Property | Formula |
|----------|---------|
| `totalCount` | `puzzles.count` |
| `inProgressCount` | `status == .inProgress` |
| `missingPiecesCount` | `hasMissingPieces == true` |
| `backlogCount` | unchanged — `status == .toDo` only |

### UI (`CollectionStatsView`)

Hero row (existing) unchanged. **Collection** section adds/reorders:

1. Total collection (`totalCount`)
2. On the table (`inProgressCount`) — subtitle: "In progress now"
3. On your shelf (`backlogCount`) — unchanged
4. Missing pieces (`missingPiecesCount`) — when > 0
5. Average rating, go-to piece count, hours — unchanged

New A11y IDs: `collection_stats_total_card`, `collection_stats_in_progress_card`, `collection_stats_missing_pieces_card`.

---

## `list-v2`

### Sort

Add `PuzzleListSortOption.name` — ascending A–Z (case-insensitive).

### Result count

Below search field when `puzzles.count > 0`:

- No filters: `"1,000 puzzles"`
- Filtered: `"Showing 12 of 1,000"`

### Missing-pieces filter

`PuzzleListQuery.apply(..., missingPiecesOnly: Bool)` — when true, keep only `hasMissingPieces`.

---

## Acceptance criteria (Phase 1)

- [ ] To-Do / In-Progress rows do not show a completion date in the list.
- [ ] Completed rows show completion date; detail uses "Completed" label.
- [ ] Status pill visible on every list row.
- [ ] Can set missing pieces + notes on add/edit; persists across restart.
- [ ] Missing-pieces filter shows only flagged puzzles.
- [ ] Stats show total, in-progress, and missing-piece counts.
- [ ] Sort by name works; result count updates with search/status/missing filter.
- [ ] Unit tests cover new stats, filter, sort, serialization, persistence.
- [ ] VoiceOver labels updated for date semantics and missing pieces.

---

## Test plan

1. Add puzzle with missing pieces + note → appears in list with indicator.
2. Filter Missing pieces → only flagged puzzles.
3. Stats tab → total matches list count; in-progress matches In-Progress tab.
4. Sort by name → alphabetical order.
5. Relaunch app → data persists.

---

## Related

- [implementation-playbook.md](implementation-playbook.md) — backlog IDs
- [roadmap.md](roadmap.md) — long-term features
