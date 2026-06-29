# Barcode metadata strategy

Puzzle Buddy’s core barcode value is **offline duplicate checking** (Phases A–C). Optional title/brand/pieces enrichment is **nice-to-have** and should stay cheap.

## Cost reality

| Approach | Cost | Puzzle hit rate |
|----------|------|-----------------|
| **Local duplicate check** | Free | 100% for barcodes you’ve saved |
| **On-device cache** (`BarcodeMetadataCache`) | Free | 100% for barcodes you’ve saved before |
| **Paid UPC APIs** (Barcode Lookup, Go-UPC, UPCitemdb paid tier, etc.) | $99+/mo typical | Unknown; not justified for 1.0 |
| **[IPDb](https://www.ipdb.plus/)** | Free to users | High for puzzles — **no public API** |

**Decision:** Do not depend on paid or trial UPC APIs (free tiers are too restrictive for real use). Prefer local data and IPDb through **partnership** and **user-initiated exports** for migration.

## Shipped today

1. **Barcode field + duplicate guard** — exact UPC match against your collection (SwiftData).
2. **Shopping mode** — scan → instant match / no-match, fully offline.
3. **Local metadata cache** — when you save a puzzle with a barcode, name/pieces/source are cached on-device for future scans (no network).
4. **Soft similar-match hints** — name + brand/pieces warnings in quick-add (IPDb-inspired, offline).
5. **Inline scan on add/edit form** — barcode row scan button on device.
6. **IPDb CSV import** — shipped in Settings (gated for 1.0 App Store). See [ipdb-csv-import.md](ipdb-csv-import.md).

Lookup is **on-device only**: `BarcodeMetadataCache` from puzzles you have already saved.

## IPDb (Internet Puzzle Database)

[IPDb](https://www.ipdb.plus/) is the most relevant **puzzle-native** catalog on the web. It is a **community archive**, not a commercial UPC feed — and that is exactly why it matters for metadata strategy.

IPDb also ships [iOS/iPad](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560) and [Android](https://ipdb.tawk.help/article/accessing-downloading-installing-ipdb) apps. Their [help center](https://ipdb.tawk.help/article/accessing-downloading-installing-ipdb) describes IPDb as **built on web technology** with the same experience across web and app stores (~3.3 MB on iOS). The team is volunteer-run and engages actively with the puzzle community (e.g. [r/Jigsawpuzzles app-launch thread](https://www.reddit.com/r/Jigsawpuzzles/comments/1gn6xxv/the_internet_puzzle_database_is_now_available_in/)). Puzzle Buddy is **not** pitching to replace that stack — it targets **offline shopping duplicate-check**, **local-first collection**, and **native iOS accessibility** as a complement, with partnership focused on API access, deep links, and attribution.

### How they reached ~40k puzzles

IPDb launched in **October 2023** (after Jigsaw Wiki went unsupported) and grew through volunteer contribution, not purchased data:

| Driver | Detail |
|--------|--------|
| **Community vacuum** | Collectors needed a shared reference; ~1,500+ contributors from 109+ countries in the first few years |
| **Two-sided catalog** | Users add **new** puzzles to the global DB *and* copy existing records into personal libraries |
| **Digital Assistant** | Box photo → title, pieces, brand in under 60s; IPDb reports **95%+ of new entries** use it |
| **Barcode-first workflow** | Scan or enter UPC before creating a record; duplicate checks before publish |
| **Free, ad-free, donation-funded** | Cloud-hosted; no subscription wall for basic use |

Every saved puzzle enriches the shared index (barcode, manufacturer ID, box photos, tags). That flywheel is why generic UPC APIs fail for jigsaws while IPDb succeeds.

### What IPDb records contain (vs Puzzle Buddy)

Full comparison with backlog mapping: [competitive-gap-analysis.md](competitive-gap-analysis.md#ipdb--feature-comparison).

| IPDb field / feature | Puzzle Buddy 1.0 | Backlog / decision |
|----------------------|------------------|-------------------|
| Title, brand, piece count | ✅ Name, source, pieces | — |
| Barcode | ✅ | — |
| Manufacturer ID / SKU | ⚠️ Barcode only; SKU → notes on CSV import | 1.2.0 — first-class field |
| Tags | ✅ User tags + filters | — |
| Shape, dimensions, cut type | ❌ | Defer — use tags/notes |
| Multiple box images, completed photo | ❌ Single cover | 1.2.0 — multi-photo gallery |
| Personal rating / difficulty / time | ✅ | — |
| Community ratings & reviews | ❌ | Won't do — personal catalog |
| Progress over days | ✅ `startDate` | — |
| Digital Assistant (box photo → fields) | ❌ | 1.2.0 — [box-photo-ocr.md](../specs/planned/box-photo-ocr.md) |
| AI image descriptions (searchable) | ❌ | Won't do |
| Social hub, messaging, games | ❌ | Won't do |
| CSV import/export | ✅ Built; **gated** for 1.0 App Store | 1.1.0 — re-enable flag |

IPDb optimizes for **shared reference + community** (web + mobile app). Puzzle Buddy optimizes for **private collection + offline shopping checks + native accessibility**.

### IPDb duplicate logic (ideas we adopted)

IPDb warns on three checks before allowing a “new” global record:

1. **Barcode** exact match  
2. **Brand + manufacturer ID + piece count**  
3. **Brand + title**

Puzzle Buddy ships **(1)** as a hard guard and **(2)/(3)** as soft “looks similar” hints in quick-add — offline, non-blocking.

### How Puzzle Buddy integrates with IPDb

| Path | Status | Notes |
|------|--------|-------|
| **User CSV export → import** | **Shipped** | Settings → Import from IPDb CSV. See [ipdb-csv-import.md](ipdb-csv-import.md). |
| **Read-only barcode/title lookup API** | Proposed | Requires partnership; no public API today |
| **Deep link to IPDb detail** | Future | Scan in Puzzle Buddy → open reviews/images on IPDb app or web |
| **Partnership / API integration** | Proposed | Read-only lookup + attribution; see [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) |

**Legitimate migration flow:** user exports **their own** collection from IPDb (Listview → Export → CSV) and imports into Puzzle Buddy. Images are not in CSV — users re-attach photos locally after import.

### What to learn from IPDb (not clone)

| IPDb pattern | Puzzle Buddy response |
|--------------|----------------------|
| Barcode-first add + duplicate checks | Shipped (form, FAB scan, shopping mode) |
| Digital Assistant (box photo → fields) | **1.2.0** — [box-photo-ocr.md](../specs/planned/box-photo-ocr.md) |
| Fuzzy duplicate hints | Shipped in quick-add |
| Reuse existing record vs create new | CSV import shipped; live lookup needs partnership |
| Hardware Link (phone scan → desktop) | Out of scope |
| Social hub, games, cloud-only account | Out of scope for 1.0 |

### IPDb vs paid UPC APIs

| | IPDb | Paid UPC APIs |
|--|------|----------------|
| Puzzle hit rate | High (puzzle-specific) | Low / unknown |
| Cost to Puzzle Buddy | Partnership or free user export | $99+/mo typical |
| Offline shopping duplicate check | N/A (online DB) | N/A |
| Fits local-first 1.0 | CSV yes; API only with consent + attribution | Poor value for jigsaws |

**Strategy:** Prefer IPDb-shaped enrichment (community puzzle data, box OCR) over generic UPC lookups. Generic UPC APIs were evaluated and **not pursued** (trial limits too restrictive; paid tiers not justified for jigsaw hit rates).

### Integration principles

- **Partnership-first** for any live IPDb data or branded experience  
- **User-initiated exports** for one-time migration (CSV from their own collection)  
- **Clear attribution** if we ever surface IPDb data (“Data from IPDb”)  
- **Formal agreement** before enabling live lookup in production  

### Brand & trademark disclaimer (IPDb-inspired)

Puzzle Buddy shows manufacturer **names** (source field, lookup, CSV import). Like IPDb, we surface a clear footer:

> All brand names and logos are trademarks of their respective owners. Their use in Puzzle Buddy is for identification and personal cataloging only. Puzzle Buddy is not affiliated with, endorsed by, or sponsored by any puzzle manufacturer or retailer.

**UI:** Settings → Help & Legal (always); form footers when entering/displaying brands; IPDb import flows. Full spec: [spec-brand-disclaimer.md](spec-brand-disclaimer.md). Copy lives in `LegalCopy.swift`.

## Recommended next steps (no API bill)

| Priority | Idea | Effort | Notes |
|----------|------|--------|-------|
| **1** | Box photo OCR (Vision) | Medium | 1.2.0 — [box-photo-ocr.md](../specs/planned/box-photo-ocr.md) |
| **2** | IPDb partnership / read-only API | Small–Large | See [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) |
| **3** | IPDb CSV import (user-facing) | Shipped (gated 1.0) | 1.1.0 un-gate — Settings → Collection |
| **4** | Manufacturer ID / SKU field | Low | 1.2.0 — replace notes hack on import |

## What we are not doing

- Embedding paid or trial UPC API keys in the app
- Requiring network for duplicate checks
- Auto-saving puzzles from lookup without user confirmation

## Related docs

- [spec-barcode-scanner.md](spec-barcode-scanner.md) — full phased spec
- [competitive-gap-analysis.md](competitive-gap-analysis.md) — IPDb + Puzzle Tracker tables
- [roadmap.md](roadmap.md) — release strategy + positioning
- [ipdb-csv-import.md](ipdb-csv-import.md) — user migration guide
- [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) — partnership email draft
- [spec-brand-disclaimer.md](spec-brand-disclaimer.md) — trademark footer spec & placement
