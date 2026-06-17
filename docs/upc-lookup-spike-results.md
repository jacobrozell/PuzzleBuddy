# UPC lookup spike — Phase 2 results

**API:** [UPCitemdb trial](https://www.upcitemdb.com/api/explorer) (`/prod/trial/lookup`, no key, ~100 req/day)  
**Corpus:** [`fixtures/upc-corpus.tsv`](fixtures/upc-corpus.tsv) (50 rows; 12 seeded UPCs + 38 placeholders to fill from your boxes)  
**Script:** [`Scripts/upc-lookup-spike.py`](../Scripts/upc-lookup-spike.py)  
**Plan:** [`upc-lookup-plan.md`](upc-lookup-plan.md) Phase 2

---

## How to run

```bash
# Query all seeded UPCs (use --delay 2.5+ to avoid TOO_FAST 429s)
python3 Scripts/upc-lookup-spike.py --delay 2.5

# Smaller batch while iterating
python3 Scripts/upc-lookup-spike.py --limit 6 --delay 3

# Re-score an existing output file
python3 Scripts/upc-lookup-spike.py --score-only docs/upc-lookup-spike-output.tsv
```

Output: `docs/upc-lookup-spike-output.tsv` (regenerated each run; safe to commit after a full pass).

### Expanding the corpus to 50 real UPCs

1. Photograph barcodes on your shelf (Ravensburger, Galison, Buffalo Games, Ceaco, Springbok, Eurographics, etc.).
2. Replace `TBD` rows in `upc-corpus.tsv` with `brand`, `expected_title`, `expected_pieces`, and `upc`.
3. Re-run the script in batches across days if you hit the daily cap.

---

## Scoring rubric

| Column | Meaning | Auto? |
|--------|---------|-------|
| **api_hit** | HTTP 200 and non-empty title or brand | Yes |
| **brand_match** | Expected brand appears in API title or brand | Yes (lenient) |
| **pieces_match** | `BarcodeTitleParser`-style regex on API title matches expected count | Yes |
| **title_usable** | `api_hit` and (title contains “puzzle” or brand matches) | Yes — review false positives manually |

**Go / no-go** (from plan): if **&lt;30% title_usable** across the full 50-UPC corpus, deprioritize generic UPC APIs; invest in box photo OCR or IPDb partnership instead.

---

## Preliminary run (2026-06-17)

Ran `python3 Scripts/upc-lookup-spike.py --limit 12 --delay 1.1` — **6 requests returned 429 `TOO_FAST`** (trial API pacing, not necessarily daily exhaustion). Use `--delay 2.5` or higher for a clean pass.

### Successful lookups (6 UPCs before throttle)

| Brand | UPC | Expected | API title (abridged) | Hit | Pieces OK |
|-------|-----|----------|----------------------|-----|-----------|
| Ravensburger | 4005555005049 | Super Mario Bros Challenge 1000 | Ravensburger Super Mario Challenge Jigsaw Puzzle 1000pc | Yes | Yes |
| Ravensburger | 4005555001256 | Forth Bridge at Sunset 1000 | *(empty)* | **No** | — |
| Galison | 9780735367524 | Cherry Blossoms 1000 | Michael Storrings Cherry Blossoms 1000 Piece Puzzle… | Yes | Yes |
| Galison | 9780735365315 | Classic Rewind 1000 | Galison Classic Rewind 1000 Piece Foil Puzzle… | Yes | Yes |
| Galison | 9780735364806 | Bouquet of Birds 750 | Chronicle Books Bouquet of Birds 750 Piece Shaped Puzzle | Yes | Yes |
| Galison | 9780735369542 | National Parks 1000 | Galison National Parks of America Puzzle, 1000 Pieces… | Yes | Yes |

**Early read (n=6, not final):**

| Metric | Rate |
|--------|------|
| API hit | 5/6 (83%) |
| Pieces match | 5/6 (83%) |
| Brand match | 4/6 (67%) |
| Title usable | 5/6 (83%) |

**Notable gaps:**

- One Ravensburger SKU returned no items — generic DB coverage is uneven even for major brands.
- Galison “Bouquet of Birds” lists **Chronicle Books** (parent publisher) instead of Galison — brand field empty; app still gets a usable title + piece count.
- Buffalo Games batch not scored yet — re-run with `--delay 3` starting at offset or after filling remaining corpus.

### Interim recommendation

**Do not expand paid UPC APIs yet.** Trial API is rate-sensitive and coverage is inconsistent. Next steps:

1. Finish corpus to 50 UPCs from real boxes (include thrift-store / older SKUs).
2. Re-run spike with `--delay 2.5` over 2–3 days if needed.
3. If full corpus **title_usable &lt; 30%**, treat UPCitemdb as optional fallback only (current product stance).
4. Parallel track: box photo OCR spec or IPDb outreach for puzzle-native metadata.

---

## Full results table

See generated [`upc-lookup-spike-output.tsv`](upc-lookup-spike-output.tsv). Update this section after a complete 50-UPC run:

| Date | Rows queried | API hit % | Title usable % | Decision |
|------|--------------|-----------|----------------|----------|
| 2026-06-17 | 12 (6 OK, 6 throttled) | 42% raw / 83% of OK | 42% raw / 83% of OK | **Pending** full corpus |

---

## Progress log

| Date | Notes |
|------|-------|
| 2026-06-17 | Corpus (12 seeded + 38 TBD), script, preliminary run — throttle lesson: use 2.5s+ delay |
