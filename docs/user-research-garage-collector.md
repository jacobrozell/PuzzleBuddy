# User research: Garage collector (1,000 puzzles)

**Date:** 2026-06-16  
**Method:** Simulator walkthrough (seeded collection), code review, and filter/stats benchmarks at n=1,000  
**Persona:** Alex — owns ~1,000 jigsaw puzzles stored in a garage. Mix of unopened boxes, half-finished works on puzzle boards, and completed puzzles kept or donated. Several thrift-store finds are missing edge pieces. Wants one place to answer: *what do I own, where is it, what's on the table, and what's incomplete?*

---

## Scenario walkthrough

| Step | Goal | What happened | Severity |
|------|------|---------------|----------|
| 1 | Open app, see collection overview | Stats tab shows completed count and backlog, but not total owned or in-progress | Medium |
| 2 | Find "that winter cabin 1000pc" in garage | Search works by name only; no brand, piece-count filter, or location | High |
| 3 | See what's actively being worked on | In-Progress tab exists (good); list row still shows a completion **date**, not status badge | Medium |
| 4 | Log a thrift find missing 3 pieces | No missing-pieces field, no notes, no condition flags | **Critical** |
| 5 | Catalog 50 boxes after organizing shelves | One-tap add form is fine for 1–2 puzzles; no barcode scan, bulk import, or duplicate check | **Critical** |
| 6 | Avoid rebuying a duplicate at a flea market | Name search helps if title is exact; no barcode, brand, or "possible duplicate" hint | High |
| 7 | Pick something from the backlog tonight | No "pick my next puzzle" or filters by piece count / tag | Medium |
| 8 | Understand garage inventory health | Stats omit in-progress, missing-piece, and total-collection counts | Medium |
| 9 | Back up 1,000 records | Local SwiftData only; no export in Settings | High |
| 10 | Scroll through full catalog | Pure filter/sort on 1,000 items is fast (~0.75 ms/op); loading all images into memory is the risk | Medium |

---

## Pain points (ranked)

### P0 — Blockers for this persona

#### 1. No missing-pieces or condition tracking
**Observed:** `Puzzle` model has no `hasMissingPieces`, `notes`, or condition fields. Thrift finds and incomplete donations cannot be recorded.

**User quote (synthetic):** *"I have 40 puzzles I'll never finish because pieces are gone — the app treats them like normal To-Do."*

**Spec: `field-missing-material` (slice 1)**
- Add `hasMissingPieces: Bool` (default `false`) and `notes: String?` to `PuzzleRecord` / `Puzzle`.
- Form: toggle "Missing pieces" + multiline Notes section.
- List: small warning icon or "Missing pieces" subtitle when flag is set.
- Filter: chip or status filter "Missing pieces" on `PuzzleList`.
- Stats: card "With missing pieces" count.
- Migration: lightweight SwiftData schema bump; default `false` / `nil`.
- A11y: `A11yID.puzzleFormMissingPiecesToggle`, VoiceOver on list rows.

#### 2. No fast cataloging path (barcode / bulk / duplicate check)
**Observed:** Add flow is a full manual form per puzzle (`PuzzleForm`). No barcode field, no "add from photo of box", no CSV import.

**User quote:** *"I can't tap through 1,000 forms. I need to scan the UPC and move on."*

**Spec: `barcode-scan` + duplicate guard (phased)**
- **Phase A:** `barcode: String?` on model; manual entry field on form; duplicate alert if barcode or normalized name matches existing puzzle (search local store).
- **Phase B:** `AVCaptureSession` scanner sheet from add button menu ("Scan barcode").
- **Phase C (stretch):** Import CSV columns `name,pieces,barcode,status,notes` via Files picker in Settings.
- Entry point: long-press `+` → "Quick add (scan)" vs "Full add".

#### 3. Completion date semantics confuse non-completed puzzles
**Observed:** List rows and detail always show `completionDate` (e.g. "June 16, 2026") even for To-Do and In-Progress. Detail stats row label is **"Completed"** for all statuses. VoiceOver reads "Completed Jun 16, 2026" for in-progress puzzles.

**Files:** `PuzzleCell.swift`, `PuzzleDetail.swift` (`detailRow(label: "Completed", ...)`), `PuzzleForm.swift` (section header "When did you finish").

**Spec: status-aware dates (no schema change)**
| Status | List row (right side) | Detail label | Form section |
|--------|----------------------|--------------|--------------|
| To-Do | Hide date or "Added {date}" | "Added" / optional target date | "Target date (optional)" |
| In-Progress | "Started {startDate}" once `startDate` ships; until then show status pill | "Started" | "Started on" |
| Completed | Completion date | "Completed" | "When did you finish?" |

- Add visible **status pill** on `PuzzleCell` (e.g. teal "In progress", gray "To-Do").
- Fix VoiceOver label to stop saying "Completed" for non-completed statuses.

---

### P1 — High friction at scale

#### 4. Find & filter too narrow for a garage
**Observed:** Search is name-only (`PuzzleListQuery.search`). Sort lacks **name** (A–Z). No filter by piece count, brand, or tags. Four-option segmented control is crowded ("In-Progress" truncates on smaller phones).

**Spec: `list-search-sort` v2**
- Add sort option: **Name (A–Z)**.
- Add filter sheet (toolbar button): piece count ranges (300, 500, 1000, 1500+), `hasMissingPieces`, brand (when `field-brand` ships).
- Show **result count** under search field: "Showing 12 of 1,000".
- Consider replacing 4-segment control with scrollable filter chips for scalability.

#### 5. Stats don't match garage mental model
**Observed:** `CollectionStats.backlogCount` counts only `To-Do`, not `In-Progress`. No "total puzzles owned". No missing-piece aggregate.

**Spec: stats v2 (no schema change for counts; missing pieces after P0)**
| Card | Formula |
|------|---------|
| Total collection | `puzzles.count` |
| On the table | `status == In-Progress` |
| On your shelf | `status == To-Do` |
| Missing pieces | `hasMissingPieces == true` |
| Puzzles completed | (existing) |

Tap a stat card → navigate to pre-filtered list.

#### 6. No physical location / shelf tracking
**Observed:** No field for garage shelf, bin, or room. At 1,000 puzzles, name search alone fails when the user is standing in front of Shelf C.

**Spec: `field-location` (new)**
- `storageLocation: String?` — free text or picker from user-defined locations.
- Quick-add: default location from last used.
- Search includes location substring.
- Future: QR labels on shelves linking to filtered list.

#### 7. Memory & load-all architecture
**Observed:** `PuzzleStore.loadLocalPuzzles()` maps every `PuzzleRecord` to a full `Puzzle` with `UIImage` hydrated in memory. At 1,000 × ~50 KB JPEG ≈ 50 MB+ RAM plus SwiftUI observable overhead.

**Spec: performance hardening**
- Lazy image loading: store thumbnail or load `imageData` only in detail/cell on appear.
- Consider `@Query` in `PuzzleList` with SwiftData predicates instead of in-memory `[Puzzle]` for filtering at scale.
- Fix O(n²) row binding: `PuzzleList` calls `firstIndex` per row — pass stable `Puzzle` + store lookup on delete only.
- Debounce search input (~150 ms) to avoid recomputing on every keystroke when n is large.

#### 8. No backup / export
**Observed:** `SettingsView` has legal links and version only. One phone loss = 1,000 records gone.

**Spec: `export-import`**
- Settings → "Export collection" → JSON or CSV to Files app.
- Optional import with merge (match on `id` or barcode).
- Copy: "Back up before deleting the app."

---

### P2 — Quality of life

#### 9. No "pick my next puzzle"
Backlog of hundreds makes choice paralysis real. Roadmap item `pick-next`: random puzzle from To-Do with optional filters (piece count, tag, exclude missing pieces).

#### 10. No tags / brand
Garage collectors think in themes (`Wysocki`, `Christmas stash`, `1000pc`). Ship `field-tags` + `field-brand` per roadmap find-and-organize bundle.

#### 11. Abandoned / wishlist statuses
Puzzles with missing pieces often become "will never finish." `Abandoned` status (roadmap) prevents inflating backlog stats.

#### 12. Add-form friction
- Long single form; completion date picker is graphical and heavy for quick adds.
- "Quick add" mode: name + pieces + photo + status only; expand for rating/time.
- No edit from list (must open detail → Edit).

#### 13. List information density
Rows are ~116 pt with large thumbnails but no status pill, missing-piece indicator, or brand. Compact row mode setting would fit more on screen when scrolling hundreds.

#### 14. Duplicate titles
Nothing prevents two "Winter Cabin" entries; normalized-name duplicate warning on save would help.

---

## What works well (keep)

- **Status tabs + search + sort** — right foundation for scale; search/filter logic is fast at 1,000 items.
- **In-Progress status** — matches "on the table" workflow.
- **Collection Stats tab** — motivating for completed work; extend for garage totals.
- **Local-first** — no account friction for bulk cataloging sessions in the garage (Wi‑Fi may be weak).
- **Accessibility** — VoiceOver labels on list rows and stats cards; status filter is labeled.
- **Pull-to-refresh** and swipe delete — familiar patterns.

---

## Recommended build order (garage collector)

| Priority | ID | Effort | Impact |
|----------|-----|--------|--------|
| 1 | Status-aware dates + list status pill | S | Fixes trust/confusion immediately |
| 2 | `field-missing-material` (missing pieces + notes) | M | Core persona need |
| 3 | Stats v2 (total, in-progress, missing) | S | Overview matches garage |
| 4 | `list-search-sort` v2 (name sort, result count, filter sheet) | M | Finding puzzles at scale |
| 5 | `barcode-scan` phase A (field + duplicate check) | M | Cataloging speed |
| 6 | `export-import` | M | Data safety for 1,000 records |
| 7 | `field-location` | M | Physical garage mapping |
| 8 | Performance hardening (lazy images, debounce) | M | Smooth scrolling with photos |
| 9 | `pick-next` | S | Backlog delight |
| 10 | `field-tags` + `field-brand` | L | Long-term organization |

---

## Open questions for product

1. **Photos at scale:** Require photo for every puzzle, or optional to speed bulk entry?
2. **Completed puzzles in garage:** Does Alex track completed boxes still stored, or only active/backlog?
3. **Household:** Single user or shared garage (multi-profile deferred on roadmap)?
4. **Import:** Would Alex accept a one-time CSV migration from a spreadsheet they've already started?

---

## Appendix: benchmark (n=1,000, no images)

| Operation | Result |
|-----------|--------|
| 100× filter + search + sort | 74.9 ms total (~0.75 ms/op) |
| 100× `CollectionStats.compute` | 31.9 ms total |
| Estimated image storage (50 KB × 1,000) | ~50 MB on disk |

CPU for list operations is not the bottleneck; **image hydration** and **lack of cataloging/metadata features** are.

---

## Related docs

- [roadmap.md](roadmap.md) — `field-missing-material`, `barcode-scan`, `field-tags`, `pick-next`
- [implementation-playbook.md](implementation-playbook.md) — backlog IDs and build order
- [features.md](features.md) — current shipped behavior
