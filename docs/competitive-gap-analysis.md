# Competitive gap analysis — Puzzle Buddy 1.0.0

**Purpose:** Side-by-side comparison of Puzzle Buddy against IPDb and Puzzle Tracker. Use when prioritizing work or writing App Store copy.

**Baseline:** [feature-inventory.md](feature-inventory.md) · **Backlog:** [FutureIdeas/backlog.md](../FutureIdeas/backlog.md) · **Active build plan:** [1.0.0-expanded-feature-sprint.md](implementation/1.0.0-expanded-feature-sprint.md)

**Last updated:** 2026-06-29

| Reference app | Role | App Store |
|---------------|------|-----------|
| **IPDb** (Internet Puzzle Database) | Community puzzle archive + personal lists on their platform | [The Internet Puzzle Database](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560) |
| **Puzzle Tracker** | Mature personal collection tracker (freemium) | [Puzzle Tracker](https://apps.apple.com/us/app/puzzle-tracker/id1561473799) |

Puzzle Buddy is **not** trying to replace IPDb’s global catalog or Puzzle Tracker’s full premium matrix at 1.0. We complement IPDb (offline shopping, native iOS, local-first) and compete with Puzzle Tracker on simplicity, accessibility, and privacy.

---

## Puzzle Buddy differentiators (1.0.0)

Ship these in marketing — competitors do not match on all of these:

| Capability | Puzzle Buddy | IPDb | Puzzle Tracker |
|------------|--------------|------|----------------|
| **Offline shopping duplicate-check** | ✅ Dedicated shopping mode | ❌ Online DB | ⚠️ Scan; cloud-oriented |
| **No account required** | ✅ | ⚠️ Account for full use | ⚠️ Premium cloud |
| **WCAG / VoiceOver target** | ✅ In progress | ❌ Not listed | ❌ Not listed |
| **Allowlisted analytics only** | ✅ | N/A | Collects linked data |
| **Abandoned + disposition tracking** | ✅ | Partial via folders | ✅ |
| **Pick random from backlog + filters** | ✅ | ❌ | ✅ Wheel |
| **Milestone celebrations** | ✅ Basic banner | ❌ | ⚠️ Stats only |

---

## IPDb — feature comparison

IPDb optimizes for **shared reference + community contribution**. Puzzle Buddy optimizes for **private collection + offline thrift-store checks**.

| IPDb capability | Puzzle Buddy 1.0 | Backlog / decision |
|-----------------|------------------|-------------------|
| Title, brand, piece count | ✅ | — |
| Barcode | ✅ | — |
| Manufacturer ID / SKU (first-class) | ⚠️ Barcode only; SKU → notes on CSV import | **1.2.0** — roadmap model extensions; [`barcode-metadata-strategy.md`](barcode-metadata-strategy.md) |
| Tags | ✅ User tags + filters | — |
| Shape, dimensions, cut type | ❌ today | **1.0 sprint** — [`puzzle-physical-metadata.md`](../specs/planned/puzzle-physical-metadata.md) |
| Multiple box + completed photos | ❌ Single cover today | **1.0 sprint** — [`multi-photo-gallery.md`](../specs/planned/multi-photo-gallery.md) |
| Personal rating / difficulty / time | ✅ | — |
| Community ratings & reviews | ❌ | **Won't do** — personal catalog, not social |
| Progress over days | ✅ `startDate` | — |
| **Digital Assistant** (box photo → fields) | ❌ | **1.2.0** — [`box-photo-ocr.md`](../specs/planned/box-photo-ocr.md) |
| Global browse (~40k puzzles) | ❌ | **Won't do** — IPDb owns canonical catalog |
| Live barcode/title lookup vs global DB | ❌ | **Partnership** — [`ipdb-partnership-outreach.md`](ipdb-partnership-outreach.md) |
| Deep link → IPDb detail (reviews, images) | ❌ | **Partnership** — same doc |
| Contribute new puzzles back to IPDb | ❌ | **Partnership** — optional post-agreement |
| AI image descriptions (searchable) | ❌ | **Won't do** — requires IPDb-scale infra |
| Social hub, messaging, games | ❌ | **Won't do** — out of scope |
| Hardware Link (phone scan → desktop) | ❌ | **Won't do** |
| CSV import/export (user collection) | ✅ Built; gated today | **1.0 sprint** — un-gate [`collection-import-export.md`](../specs/planned/collection-import-export.md) |
| Duplicate checks (barcode / brand+title) | ✅ Local hard + soft hints | — |
| Attach barcode to existing puzzle | ❌ | **1.1.x polish** — [`barcode-scan-polish.md`](../ongoing/barcode-scan-polish.md) §13 |
| Tappable similar-match prefills in quick-add | ❌ Partial | **1.1.x polish** — same doc §8 |

**Strategy:** [`barcode-metadata-strategy.md`](barcode-metadata-strategy.md) · Migration: [`ipdb-csv-import.md`](ipdb-csv-import.md)

---

## Puzzle Tracker — feature comparison

Puzzle Tracker is the closest **personal collection tracker** competitor. Rows marked **1.0 sprint** are in [`1.0.0-expanded-feature-sprint.md`](implementation/1.0.0-expanded-feature-sprint.md).

| Puzzle Tracker capability | Puzzle Buddy today | Backlog / decision |
|---------------------------|-------------------|-------------------|
| Status folders (wishlist, waiting, in progress, completed, abandoned) | ✅ | — |
| Photo gallery per puzzle | ❌ Single cover | **1.0 sprint** — [`multi-photo-gallery.md`](../specs/planned/multi-photo-gallery.md) |
| Progress by photos + days | Days ✅; photos ❌ | **1.0 sprint** multi-photo |
| Progress % on in-progress puzzle | ✅ | — |
| Built-in timer (pause) | ❌ Manual time entry | **1.1.0** — [`in-app-timer.md`](../specs/planned/in-app-timer.md) |
| Search, filter, sort | ✅ | — |
| Exclude-mode filter chips | ❌ | **Defer** |
| Barcode scan | ✅ Single + shopping mode | **Defer** bulk batch scan |
| Tags | ✅ | **1.2.x polish** — tag cloud, favorites |
| Brand / manufacturer | ✅ `source` field | — |
| Artist (separate from brand) | ❌ | **1.2.0** |
| Purchase location | ✅ | — |
| Purchase price | ❌ | **1.0 sprint** |
| Release year, puzzle type, material | ✅ | — |
| Disposition after complete | ✅ | — |
| Missing pieces flag | ✅ | — |
| Notes | ✅ | — |
| Wheel / random pick | ✅ Pick my next puzzle | — |
| Re-do / multiple timed attempts | ❌ | **1.0 sprint** — [`puzzle-redo-completions.md`](../specs/planned/puzzle-redo-completions.md) |
| Share collage / stats | ✅ | **1.3.0** year-in-review |
| Friend sharing / copy from friend | ❌ | **Defer** |
| Custom fields / premium folders | ❌ | **Defer** |
| Statistics screen | ✅ Stats tab + milestones | — |
| Favorites on brand/tag lists | ❌ | **1.2.x polish** |
| Swipe between puzzles on detail | ❌ | **Defer** |
| Adjustable font size (S/M/L) | ❌ Uses Dynamic Type | **Won't do** |
| Import / export / backup | Built; gated | **1.0 sprint** un-gate |
| Account / cloud sync | ❌ Removed from app | **Future** |
| Premium IAP tier | ❌ | **Won't do** at 1.0 |
| Accessibility statement | Not indicated | ✅ **Differentiator** |
| Dedicated offline shopping mode | ❌ | ✅ **Differentiator** |

**Positioning detail:** [roadmap.md — Puzzle Tracker](roadmap.md#competitive-positioning--puzzle-tracker)

---

## Gap summary by release

| Release | Theme | Closes gaps vs |
|---------|-------|----------------|
| **1.0.0 (expanded sprint)** | Ship before submit | IPDb: shape/dimensions/cut, multi-photo, CSV migration. PT: multi-photo, price, redo, import |
| **1.0.0 (baseline)** | Already built | Core catalog, stats, shopping, pick-next |
| **1.1.0** | Timer + restore | PT timer; JSON restore UI |
| **1.2.0** | Enrichment | Box OCR, artist, manufacturer ID |
| **1.3.0** | Delight + platform | Widget, year-in-review, iPad sidebar |
| **Partnership** | IPDb integration | Live lookup, deep links |
| **Defer / won't do** | — | Social, custom fields, bulk scan, AI descriptions |

---

## Maintenance

Update this file when:

- A competitor ships a major feature (check App Store release notes)
- Puzzle Buddy ships or reprioritizes a row in the comparison tables
- A new reference app becomes primary (e.g. My Puzzle Cabinet)

Also update [FutureIdeas/backlog.md](../FutureIdeas/backlog.md) and [roadmap.md](roadmap.md) model extensions when adding rows here.
