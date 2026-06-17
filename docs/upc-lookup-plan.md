# UPC lookup plan

**Goal:** Optional barcode enrichment (title, brand, piece count) without compromising offline duplicate-check or running up API bills.  
**Status:** Phase 0 shipped · Phase 1 complete · Phases 2–3 planned  
**Related:** [barcode-metadata-strategy.md](barcode-metadata-strategy.md), [spec-barcode-scanner.md](spec-barcode-scanner.md) §10

---

## What “UPC lookup” means in Puzzle Buddy

When a user scans or enters a barcode while **adding** a puzzle (not shopping mode), the app can suggest metadata to pre-fill the form:

| Field | Source today |
|-------|----------------|
| Title | UPC API `title`, cleaned by `BarcodeTitleParser` |
| Brand | API `brand` → `source` field |
| Pieces | Parsed from title (e.g. “1000 Pieces”) |
| Photo | API image URL returned but **not auto-downloaded** |

**Shopping mode never calls lookup** — it only checks your local collection offline.

---

## Shipped today (Phase 0)

| Piece | Implementation |
|-------|------------------|
| Toggle | Settings → **Look up product from barcode** (`UserPreferences`, default **off**) |
| Lookup order | Session cache → `BarcodeMetadataCache` (your saved puzzles) → UPCitemdb trial API |
| API | `https://api.upcitemdb.com/prod/trial/lookup` — no API key; ~100 requests/day |
| Parser | `BarcodeTitleParser` strips junk, extracts piece count from title strings |
| UX | `QuickAddPuzzleSheet` shows source label (“From your saved puzzles” / “From online product lookup”) |
| Kill switch | Launch arg `-disable_barcode_lookup` for tests |

**Key files:** `BarcodeLookupService.swift`, `BarcodeMetadataCache.swift`, `BarcodeProductMetadata.swift`, `ProductService.isBarcodeLookupEnabled`, `PuzzleList` scan → lookup → quick-add flow.

---

## Why this stays optional

| Constraint | Implication |
|------------|-------------|
| Generic UPC DBs mislabel jigsaws | Hit rate likely low; users must confirm every field |
| UPCitemdb trial limits | 100 req/day shared per IP — easy to exhaust in QA |
| Paid APIs ($99+/mo) | Not justified for 1.0; no embedded paid keys |
| IPDb has puzzle-native data | No public API yet — partnership path, not UPC |
| Local-first promise | Duplicate check and shopping work with zero network |

**Principle:** Lookup is a **suggestion layer**. Never auto-save without user confirmation.

---

## Phase 1 — Harden what we have (S)

Polish the shipped trial integration before expanding providers.

| # | Task | Status |
|---|------|--------|
| 1.1 | **Rate-limit UX** — quick-add notice for 429 / errors | [x] |
| 1.2 | **Lookup loading state** — overlay + VoiceOver | [x] |
| 1.3 | **Persist successful API hits** — `storeLookup` | [x] |
| 1.4 | **Unit tests** — HTTP mapping, cache-first, storeLookup | [x] |
| 1.5 | **Privacy copy** — `privacy.html` + Settings footer | [x] |
| 1.6 | **Analytics** — no raw barcode in events | [x] |

**Exit criteria:** Toggle on/off is trustworthy; failures are visible; tests cover parser and gating.

---

## Phase 2 — Validate hit rate (S)

Decide whether to invest beyond UPCitemdb.

| # | Task | Notes |
|---|------|-------|
| 2.1 | **Corpus test** | [~] | 12 seeded UPCs in `fixtures/upc-corpus.tsv`; expand to 50 from your boxes |
| 2.2 | **Score results** | [~] | `Scripts/upc-lookup-spike.py` auto-scores; preliminary 83% on 6 OK rows |
| 2.3 | **Document findings** | [x] | [upc-lookup-spike-results.md](upc-lookup-spike-results.md) |
| 2.4 | **Go / no-go** | | Pending full corpus; interim: keep UPCitemdb optional fallback |

**Exit criteria:** Data-driven decision on whether generic UPC APIs are worth more engineering.

---

## Phase 3 — Better enrichment sources (M–L)

Only after Phase 2 justifies it or IPDb partnership opens.

| Priority | Source | Effort | Notes |
|----------|--------|--------|-------|
| **A** | **IPDb read-only API** | L (partnership) | Puzzle-native; requires agreement + attribution UI — see [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) |
| **B** | **Box photo OCR** | M | On-device Vision; no network — see phase-1 §9 / [barcode-metadata-strategy.md](barcode-metadata-strategy.md) |
| **C** | **Server proxy for UPC** | M | If a paid API is ever used, key lives server-side — never in the app binary |
| **D** | **Community cache (opt-in)** | L | Post-1.0; privacy review required |

**Not planned:** Embedding Barcode Lookup / Go-UPC keys in the client; requiring network for core flows.

---

## Lookup flow (target architecture)

```
Scan / enter barcode
        │
        ▼
┌───────────────────┐
│ Duplicate in       │──yes──► Shopping: match card / Add: warn similar
│ local collection?  │
└─────────┬─────────┘
          │ no
          ▼
┌───────────────────┐
│ BarcodeMetadataCache│──hit──► Quick-add with local metadata
└─────────┬─────────┘
          │ miss
          ▼
┌───────────────────┐
│ Toggle on?         │──no───► Quick-add (barcode only)
└─────────┬─────────┘
          │ yes
          ▼
┌───────────────────┐
│ Provider lookup    │──hit──► Quick-add + source label + disclaimer
│ (UPCitemdb → IPDb)│
└─────────┬─────────┘
          │ miss / error
          ▼
    Quick-add (barcode only) + optional “no details found” copy
```

---

## IPDb vs UPC lookup

| | Generic UPC (UPCitemdb) | IPDb (future API) |
|--|------------------------|-------------------|
| Data quality for jigsaws | Poor–mixed | High |
| Cost | Free trial / paid tiers | Partnership terms |
| Offline | No | No (unless cached) |
| Attribution | Product DB TOS | IPDb branding required |
| Status | Shipped (trial) | Outreach / partnership |

**Strategy:** Keep UPCitemdb as a free, off-by-default fallback. Pursue IPDb for puzzle-native enrichment. Box OCR covers barcodes missing from any database.

---

## Sprint order (recommended)

| Sprint | Scope |
|--------|--------|
| **Next** | Phase 1.1–1.4 (UX + cache + tests) |
| **Then** | Phase 2 spike (50 UPC corpus) |
| **If GO** | Phase 1.5–1.6 + consider IPDb API integration |
| **If NO-GO** | Box photo OCR spec; reduce Settings copy emphasis on online lookup |

---

## Verification

```bash
xcodegen generate
xcodebuild -scheme "Puzzle Buddy" -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:"Puzzle BuddyTests/BarcodeMetadataCacheTests" \
  -only-testing:"Puzzle BuddyTests/BarcodeTitleParserTests" test
```

Manual:

1. Settings → turn lookup **off** → scan unknown barcode → no network call, empty suggestions
2. Turn lookup **on** → scan barcode from a saved puzzle → “From your saved puzzles” without API
3. Turn lookup **on** → scan new retail UPC → optional online suggestion or graceful empty
4. Shopping mode → airplane mode → duplicate check still works

---

## Progress log

| Date | Item | Notes |
|------|------|-------|
| 2026-06-17 | Plan created | Phase 0 documented; Phases 1–3 defined |
| 2026-06-17 | Phase 1 complete | Rate-limit UX, cache persistence, tests, privacy copy |
| 2026-06-17 | Phase 2 started | Corpus, spike script, preliminary results (see spike-results doc) |
