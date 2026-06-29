# Roadmap and Future Plans

This document consolidates planned work across releases, accessibility phases, and model extensions. It is the single reference for what ships in **1.0.0** (inaugural App Store release) versus what comes next.

For **current shipped behavior**, see [features.md](features.md) and [feature-inventory.md](feature-inventory.md). For agents: [AGENTS.md](../AGENTS.md).

**Last updated:** 2026-06-29

**Versioning:** Puzzle Buddy has never been released publicly. The first App Store version is **1.0.0** (`MARKETING_VERSION` in `project.yml`, `Puzzle_BuddyApp.version`). Follow-on releases use semver: **1.1.0** (import/export, polish), **1.2.0+**, etc. Account sync is **not** scheduled for 1.1 — see [Future: auth + cloud sync](#future-auth--cloud-sync).

### Contents

- [Release strategy](#release-strategy)
- [Future: auth + cloud sync](#future-auth--cloud-sync)
- [Puzzle model extensions](#puzzle-model-extensions)
- [Find & organize](#find--organize--user-driven-product-strategy)
- [Stats and collection insights](#stats-and-collection-insights)
- [Competitive positioning](#competitive-positioning--puzzle-tracker)
- [Accessibility roadmap](#accessibility-roadmap)
- [Testing and infrastructure roadmap](#testing-and-infrastructure-roadmap)
- [Observability roadmap](#observability-roadmap)
- [Infrastructure and platform](#infrastructure-and-platform)

---

## Release strategy

Puzzle Buddy uses **staged releases** controlled by `ProductService` feature flags (not separate product branches).

| Release | Theme | Gated features | Data store |
|---------|-------|----------------|------------|
| **1.0.0** (inaugural) | Local-first catalog | Import/export off | SwiftData on device |
| **1.1.0** (target) | Import/export + polish | `isCollectionImportExportEnabled` | SwiftData on device |
| **Future** | Richer metadata, widgets, optional accounts | TBD | SwiftData; cloud TBD |

Firebase in all releases: **Analytics + Crashlytics only** ([telemetry.md](telemetry.md)). No Auth, Firestore, or push in the app today.

### Enabling features during development

| Flag | Default | Override |
|------|---------|----------|
| `isCollectionImportExportEnabled` | `false` | `-enable_collection_import_export` |
| `isBarcodeScanEnabled` | device capability | — |
| `isPickNextEnabled` | `true` | — |

Remote Config for flags is a future option — not implemented.

---

## Future: auth + cloud sync

**Not in the app.** Login, Firestore sync, FCM push, and related code were **removed June 2026**. Firebase Console Auth/Firestore were decommissioned for this project.

If accounts return, treat it as a **new implementation** guided by [specs/planned/auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md), not a flag flip on old code.

High-level requirements if revisited:

| Area | Notes |
|------|-------|
| Product | Optional account; full offline catalog without sign-in |
| Migration | Upload SwiftData puzzles on first sign-in; conflict UI TBD |
| Backend | Re-create Firestore + rules; Cloud Storage for images (not Base64 in docs) |
| Telemetry | New allowlisted auth funnel events; same PII rules as [telemetry.md](telemetry.md) |
| Testing | Firebase Emulator, login UI tests, multi-device QA |

Historical implementation notes (pre-removal) live in git history and the spec doc — do not assume `-enable_login` or `isLoginEnabled` still exist.

---

## Puzzle model extensions

Many fields below **shipped in 1.0** — see [feature-inventory.md](feature-inventory.md). This section tracks remaining gaps vs. competitor and backlog.

### Shipped in 1.0 (reference)

Tags, barcode, notes, brand (`source`), start date, wishlist/abandoned/in-progress statuses, missing pieces, material, disposition, purchase location, release year, puzzle type, progress percent — all on `Puzzle` / `PuzzleRecord`.

### Still planned / backlog

| Field / feature | Description | Complexity |
|-----------------|-------------|------------|
| In-app timer | Background timer, optional Live Activity | Medium |
| `price` | Purchase price tracking | Low |
| `urlLink` | Link to manufacturer or review | Low |
| Reverse image search | Auto-fill from photo | High — ML or external API |
| `progressPhotos` | Gallery beyond cover image | Medium |
| Multi-photo gallery | Several photos per puzzle | Medium |

### Status enum

**Shipped:** Wishlist, To-Do, In-Progress, Completed, Abandoned.

New statuses in the future require SwiftData migration planning (none implemented yet).

### UI improvements (near-term)

| Item | Status |
|------|--------|
| Editable `RatingsView` on form | ✅ Shipped |
| Search / filter / sort on list | ✅ Shipped |
| Pick my next puzzle | ✅ Shipped |
| JSON backup / restore | Planned — [specs/planned/json-backup-restore.md](../specs/planned/json-backup-restore.md) |
| Home screen widget | Planned — [specs/planned/home-screen-widget.md](../specs/planned/home-screen-widget.md) |

---

## Find & organize — user-driven product strategy

Product thinking for collectors with growing libraries. **Steps 1–3 below shipped in 1.0** (search, status tabs, sort, tags, pick-next). Remaining polish: tag cloud in stats, favorites on brands/tags, exclude-mode filters.

### Custom tags — recommendation

**Yes — ship user-defined tags**, but as part of a **find & organize bundle**, not in isolation. Tags without search and filter feel broken; search without tags still helps, but tags unlock seasonal stash picks and random selection.

**Tags are strong for:**

- Personal organization — `winter`, `gift-from-mom`, `hard`, `thrift-find`
- Artists and themes — `Wysocki`, `cats`, `gradient`
- Situational filters — `1000pc`, `weekend-project`, `kids-room`
- **"What should I do next?"** — random pick from To-Do filtered by tag or piece count (see [pick-next](implementation-playbook.md#feature-backlog-implement-all-cut-later))

**Design constraints for tags:**

- **User-defined, multi-select** — not a fixed taxonomy; users label puzzles how they think about their collection
- Chip picker on add/edit; filter chips on `PuzzleList`; optional tag cloud in Collection Stats
- Preset **category** (landscape, mystery, gradient) can follow later for users who prefer structured types over free-form labels

### Tags vs category vs brand

| Approach | User mental model | Example | When to ship |
|----------|-------------------|---------|--------------|
| **Tags** (multi, user-defined) | "How I think about my collection" | `cozy`, `Wysocki`, `2024` | ✅ Shipped |
| **Category** (single, preset enum) | "What kind of puzzle is this?" | Landscape, Mystery, Gradient | ✅ `puzzleType` enum |
| **Brand** (structured field) | "Who made it?" | Ravensburger, Galison | ✅ `source` field |

### Recommended build order (find & organize)

Ship in this order so each layer makes the next feel valuable:

| Step | Features | Status |
|------|----------|--------|
| 1 | Search, status tabs, sort | ✅ Shipped |
| 2 | Custom tags + filter by tag | ✅ Shipped |
| 3 | Pick my next puzzle | ✅ Shipped |

Backlog IDs: `list-search-sort`, `list-status-tabs`, `field-tags`, `pick-next` in [implementation-playbook.md](implementation-playbook.md).

### Feature tiers (user impact)

**High value — users would notice immediately**

| Feature | User need | Backlog ID / field |
|---------|-----------|-------------------|
| In Progress status | Puzzle on the table right now | ✅ Shipped |
| Notes | Missing pieces, lent to someone, thrift price | ✅ Shipped |
| Pick my next puzzle | Random from backlog, filtered | ✅ Shipped |
| Duplicate check | "Do I already own this?" while shopping | ✅ Barcode + search |
| Wishlist | Want to buy, don't own yet | ✅ Shipped |

**Medium value — deep collectors**

| Feature | User need | Backlog ID / field |
|---------|-----------|-------------------|
| Brand / manufacturer | Search, favorites, stats by brand | ✅ `source`; favorites list optional |
| Barcode scan | Fast add + duplicate prevention | ✅ Shipped |
| Missing pieces flag | Common for thrift finds; filterable | ✅ Shipped |
| Start date + timer | Actual time vs manual estimate | ✅ Start date; timer planned |
| Progress photos | WIP shots, not just finished box | Planned |

**Delight — retention, not core loop**

| Feature | User need | Backlog ID |
|---------|-----------|------------|
| Widgets | In-progress or random To-Do on home screen | `widget` |
| Milestones | "50th puzzle completed" | `milestones` |
| Share card | Finished puzzle image + stats for social | ✅ Share collage; year-in-review planned |

### What not to chase (yet)

- **Full Puzzle Tracker filter matrix** — brand + year + purchase location + exclude mode + every metadata dimension at once; overwhelming until base list UX is solid
- **Fixed tag taxonomy only** — prefer free-form tags; optional presets can supplement later
- **Custom fields / folders** — power-user complexity; defer unless users ask

### Smallest high-impact slice

Steps 1–3 above are **done**. Next incremental wins: milestones banner polish, tag cloud on stats, import/export in 1.1.

---

## Stats and collection insights

Collection Stats tab and per-puzzle pace metrics **shipped in 1.0**. Pieces-per-minute was removed. Remaining work is phased below.

### Phase A — Aggregate from existing fields (no schema change) ✅ Shipped

**Collection Stats** screen (Stats tab) with hero cards computed from `PuzzleStore.puzzles`:

| Stat | Source fields | Notes |
|------|---------------|-------|
| Puzzles completed | `status == Completed` | Headline number |
| Total pieces assembled | sum of `pieces` (completed) | Milestone-friendly ("100,000 pieces!") |
| Total time puzzling | sum of `estimatedTimeSpent` (completed) | "142 hours at the table" |
| Backlog size | `status == To-Do` | Queue depth |
| Average rating | mean of `rating` (completed, non-zero) | Collection quality signal |
| Favorite piece count | median/mode of `pieces` (completed) | "I usually do 1000-piece puzzles" |
| Completions this month / year | `completionDate` | Natural period summaries |
| Biggest / smallest completed | min/max `pieces` (completed) | Fun bragging rights |

Implemented in `CollectionStats.swift` + `CollectionStatsView.swift`. See [features.md](features.md#collection-stats-collectionstatsview).

**Detail view cleanup:** ✅ Shipped — pieces-per-minute removed; puzzle pace bucket + hours per 1,000 pieces on detail. See [features.md](features.md#per-puzzle-detail-metrics).

### Per-puzzle derived metrics (detail view) ✅ Shipped

| Metric | Formula / rule | When to show |
|--------|----------------|--------------|
| Hours per 1,000 pieces | `(estimatedMinutes / 60) / (pieces / 1000)` | When pieces and time are set |
| Time bucket label | Under 4h → "Quick finish"; 4–12h → "Weekend puzzle"; 12h+ → "Marathon project" | When hours and minutes are both set |
| Days to complete | `completionDate − startDate` | After `startDate` ships |
| Difficulty vs. rating | Subjective mismatch (e.g. high difficulty + low rating) | Optional insight row; no single "score" |

Implemented in `PuzzleDetailMetrics.swift` + `PuzzleDetail` stats panel.

### Phase B — List and navigation polish (minimal schema change)

| Item | Description |
|------|-------------|
| Status tabs | To-Do / In-Progress / Completed / All segments on `PuzzleList` ✅ |
| Rating on list rows | Show `RatingsView` or star summary on `PuzzleCell` ✅ |
| Search and sort | Wire existing `searchText`; sort by date, rating, difficulty, piece count ✅ |
| Milestones | Lightweight celebrations at thresholds (50 puzzles, 10k pieces, etc.) |

### Phase C — Richer tracking (schema + UX)

| Item | Unlocks | Notes |
|------|---------|-------|
| `In-Progress` status | Active puzzle on the table | ✅ Shipped (`status-in-progress`) |
| Start date | Days to complete, pace over time | Pair with `completionDate` |
| In-app timer with pause | Accurate time instead of manual estimate | Roadmap `timer` field; Live Activity optional |
| Notes | Personal memories per puzzle | Roadmap `notes` field |
| Brand / category / tags | Filter and stats by theme or manufacturer | Extends roadmap `category` |

### Phase D — Delight (optional, higher effort)

| Item | Description |
|------|-------------|
| Year in review | Shareable summary card (completions, pieces, hours, top ratings) |
| Widget | Backlog count + recent completions |
| Activity heatmap | Completion calendar (GitHub-style) |
| Shareable stats collage | Completed puzzle grid image for social |

### Deprioritized

- **Pieces per minute** as a primary metric — too niche; deprioritize or remove
- **Leaderboards / social comparison** — off-brand for a personal catalog
- **Heavy gamification** (XP, streak pressure) — milestones only, not grind mechanics

---

## Competitive positioning — Puzzle Tracker

Reference: [Puzzle Tracker on the App Store](https://apps.apple.com/us/app/puzzle-tracker/id1561473799) (Dawid Kurek). Mature competitor (~600+ ratings, 4.7★, freemium premium). Use this section to decide what to match, differentiate, or skip.

### Feature comparison

| Capability | Puzzle Tracker | Puzzle Buddy (1.0) | Opportunity |
|------------|----------------|---------------------|-------------|
| Photo gallery per puzzle | ✅ | Single cover photo | Multi-photo progress shots |
| Status folders | Wishlist, Waiting, Completed, Abandoned, In progress | ✅ Wishlist, To-Do, In-Progress, Completed, Abandoned | — |
| Built-in timer (pause) | ✅ Core feature | ❌ Manual time only | High-value match; pairs with In-Progress |
| Progress by photos + days | ✅ | Start date + days on detail ✅ | Progress photos |
| Filtering and sorting | ✅ Extensive | ✅ Search, status tabs, sort, filters, tags | Incremental polish |
| Barcode scan | ✅ Bulk + manual | ✅ Scan + shopping duplicate-check | Bulk scan optional |
| Tags | ✅ | ✅ User tags + filters | Tag cloud / favorites |
| Custom fields / folders | ✅ Premium | ❌ | Defer |
| Brand, artist, manufacturer | ✅ | ✅ `source` field | Favorites list optional |
| Purchase location / price | ✅ | ✅ Location; price not shipped | Price field |
| Disposition after complete | ✅ | ✅ Shipped | — |
| Puzzle material | ✅ | ✅ Shipped | — |
| Missing pieces flag | ✅ | ✅ Shipped | — |
| Wheel / random pick | ✅ | ✅ Pick my next puzzle | — |
| Re-do / multiple attempts | ✅ | ❌ | Defer |
| Share results / collages | ✅ | ✅ Share collage | Year-in-review |
| Friend sharing / social | ✅ v7.3+ | ❌ | Defer; optional cloud later |
| Statistics screen | ✅ | ✅ Collection Stats tab | Milestones, year-in-review |
| Favorites on metadata lists | ✅ | ❌ | After tag/brand polish |
| Accessibility statement | Not indicated | ✅ WCAG work in progress | **Differentiator** |
| Account required | Premium cloud | ❌ Local-only | **Differentiator** |
| Privacy pitch | Collects linked data | Allowlisted analytics only | **Differentiator** |

### Brainstorm — how Puzzle Buddy can win

**1. Nail the jobs puzzlers actually hire the app for**

Reviews on Puzzle Tracker repeatedly mention: *avoid buying duplicates while shopping*, *track shelf vs table*, *pick what to do next*. Puzzle Buddy should optimize for:

- **Duplicate check** — fast search by name + barcode scan before buying (even offline)
- **Clear lifecycle** — Wishlist → To-Do → In Progress → Completed (optionally Abandoned)
- **"What should I do next?"** — random pick from backlog, optionally filtered by tags or piece count

**2. Stats that feel personal, not athletic**

Puzzle Tracker leans timer-heavy; Puzzle Buddy can lean **collection pride**:

- Total puzzles, total pieces, hours this year
- Milestones and year-in-review share cards
- Skip speed metrics unless timer ships for that audience

**3. Differentiate on trust and craft**

| Angle | Puzzle Buddy play |
|-------|-------------------|
| Local-first, no account | Core catalog works offline forever; cloud is a future spec only |
| Accessibility | WCAG 2.1 AA target; VoiceOver, Dynamic Type, Reduce Motion — market this |
| Native SwiftUI polish | Fast, simple flows vs feature-bloated competitor |
| Privacy-safe analytics | Allowlisted events only; no PII — contrast in App Store copy |

**4. Suggested build order vs competitor gaps**

| Priority | Feature | Rationale |
|----------|---------|-----------|
| P0 | Collection stats screen | ✅ Shipped |
| P0 | Status tabs + search | ✅ Shipped |
| P1 | In-Progress + timer | In-Progress ✅; timer planned |
| P1 | Barcode scan | ✅ Shipped |
| P1 | Tags or categories | ✅ Shipped |
| P2 | Wheel / pick next | ✅ Shipped |
| P2 | Brand / manufacturer field | Search + favorites + duplicate check |
| P2 | Notes + disposition | Journaling and "what happened to this puzzle" |
| P3 | Multi-photo progress | Progress-over-days without full attempt model |
| P3 | Share collage / year in review | Premium-feeling polish |
| Defer | Friend sharing, custom fields, bulk AI scan, re-do attempts | High complexity; competitor's long tail |

**5. What not to chase (yet)**

- Feature parity with Puzzle Tracker's entire filter matrix — overwhelming for v1.x
- Premium tier / IAP until core loop beats free competitor on simplicity + a11y
- Social graph before core import/export and backup story is solid

### Competitor user research themes

Recurring themes from [Puzzle Tracker App Store reviews](https://apps.apple.com/us/app/puzzle-tracker/id1561473799) (paraphrased). Use these to validate feature priority:

| Theme | User need | Puzzle Buddy response |
|-------|-----------|----------------------|
| Duplicate prevention | Check collection while shopping so they don't rebuy | Barcode scan + fast name search (offline) |
| Shelf vs. table | Know what's owned vs. actively being worked | Status lifecycle + In-Progress |
| What to do next | Pick randomly from backlog, sometimes by season/tag | "Pick my next puzzle" + tag filters |
| Post-completion tracking | What happened to the puzzle (kept, donated, sold) | `disposition` field |
| Material / condition | Cardboard vs. wood; missing pieces on thrift finds | `material`, `hasMissingPieces` |
| Household sharing | Separate profiles or times per person | Defer — multi-profile is niche; notes field as lighter alternative |
| Speed puzzling | Multiple timed attempts per puzzle | Defer — re-do/attempts model |

### Adapt from competitor (our spin)

| Puzzle Tracker feature | Puzzle Buddy approach |
|------------------------|----------------------|
| Wheel of Fortune | **"Pick my next puzzle"** — random from To-Do; filter by tag or piece count |
| Progress photos + days | **Start date** + optional 2–3 progress photos; skip full re-do attempt table |
| Disposition | Simple enum after complete: Kept / Donated / Sold / Gifted / Trashed |
| Abandoned folder | `Abandoned` status for puzzles you'll never finish |
| Missing pieces filter | Single `hasMissingPieces` toggle on puzzle |
| Statistics + collages | Collection stats screen (Phase A) + year-in-review share card (Phase D) |
| Friend sharing (v7.3+) | Defer; optional cloud sync only if [auth spec](../specs/planned/auth-cloud-sync.md) ships |
| Custom fields / folders | Skip for v1.x — power-user complexity |
| Bulk AI barcode scan | Start with single scan + manual entry; bulk later |

### Product positioning summary

Puzzle Buddy competes on **simplicity, local-first trust, accessibility, and collection pride** — not feature parity with a mature freemium CRM-style tracker.

| Pillar | Message |
|--------|---------|
| Simplicity | Fewer taps to log a puzzle; no premium wall for core catalog |
| Local-first | Full catalog offline; no account; Firebase telemetry only |
| Accessibility | WCAG 2.1 AA — market VoiceOver, Dynamic Type, Reduce Motion |
| Collection pride | Total puzzles, pieces, hours — not speed metrics |
| Privacy | Allowlisted analytics only; no PII in telemetry |

---

## Accessibility roadmap

Tracked in detail in [../accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) and [wcag.md](wcag.md). Summary by phase:

### Phase 1 — Done ✅

- VoiceOver labels on primary actions (puzzle form, list, detail, settings)
- `A11yID` identifiers for UI tests
- Reduce Motion on brand gradient and splash
- GitHub Pages accessibility statement
- `XCUIAccessibilityAudit` suite on list, form, settings, stats, detail

### Phase 2 — Next

| Work item | WCAG criteria | Screens |
|-----------|---------------|---------|
| Puzzle form VoiceOver audit | 4.1.2 Name, Role, Value | Form — name, pieces, rating, difficulty, date, status, photo |
| Puzzle detail reading order | 1.3.2 Meaningful Sequence | Detail view |
| Rating/difficulty value announcements | 4.1.2 | `RatingsView`, `DifficultyView` |
| Delete confirmation labels | 4.1.2 | List swipe delete |
| Dynamic Type audit | 1.4.4 Resize Text | `PuzzleCell`, form, tab bar |
| Contrast verification | 1.4.3, 1.4.11 | Accent on card, star inactive states, placeholders |
| Import/export sheet audit | 4.1.2 | When `-enable_collection_import_export` ships to production |

### Phase 3 — Polish

| Work item | Description |
|-----------|-------------|
| Localization | `Localizable.strings` for all user-facing copy |
| Manual evidence | Screenshots and VoiceOver recordings under `accessibility/wcag-2.1-aa/` |
| Voice Control audit | Label compatibility with Voice Control |
| Bold Text / Increase Contrast | System setting compatibility checks |

### Conformance target

**WCAG 2.1 Level AA** on iOS. Current status: **Partial** — 3 criteria Planned, remainder Supports or Partial. See [../accessibility/wcag-2.1-aa/conformance-matrix.md](../accessibility/wcag-2.1-aa/conformance-matrix.md).

---

## Testing and infrastructure roadmap

From [testing.md](testing.md) and engineering notes:

| Item | Status | Benefit |
|------|--------|---------|
| `XCUIAccessibilityAudit` suite | ✅ Done | Automated WCAG checks on key screens |
| Firebase Emulator tests | Future | Only if auth/cloud sync spec is approved |
| Snapshot tests | Optional | Visual regression for key screens |
| Landscape layout tests | ✅ Done | Puzzle list and form |
| Codemagic CI | Config present | Additional CI path via `codemagic.yaml` |

---

## Observability roadmap

Current implementation: [telemetry.md](telemetry.md) (Dart Buddy–aligned allowlists, Release-only collection, Crashlytics breadcrumbs).

| Item | Status | Notes |
|------|--------|-------|
| Screen-level UI analytics | Optional | Add allowlisted `LogCategory.ui` events as needed |
| Remote Config for feature flags | Future | Replace static `ProductService` flags |
| Custom GA4 dimensions | Future | Mirror Dart Buddy release checklist pattern if funnels grow |

No push notification telemetry — FCM removed from app.

---

## Infrastructure and platform

| Item | Notes |
|------|-------|
| **Cloud Storage for images** | Only relevant if [auth + cloud sync](../specs/planned/auth-cloud-sync.md) returns |
| **iPad-optimized navigation** | Adaptive layouts exist; consider sidebar on regular size class |
| **Widgets / Live Activities** | Puzzle timer or backlog widget — [spec](../specs/planned/home-screen-widget.md) |
| **Share extension** | Add puzzle from Safari or Photos share sheet |
| **macOS / visionOS** | Not planned; iOS 17+ iPhone and iPad only |
| **Android** | Out of scope |

---

## How to propose or track new work

1. **Accessibility** — update [accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) and the [conformance matrix](../accessibility/wcag-2.1-aa/conformance-matrix.md)
2. **Features** — add to this document under the appropriate release section
3. **Architecture / telemetry changes** — update [architecture.md](architecture.md) and [telemetry.md](telemetry.md)
4. **Shipped features** — update [features.md](features.md) when behavior changes

When closing a roadmap item, remove or mark it done here and reflect the change in the relevant technical doc.

For **implementation sessions** (build all features, cut 1.0.0 later), see [implementation-playbook.md](implementation-playbook.md).

---

## Related documentation

| Document | Topic |
|----------|-------|
| [features.md](features.md) | Current shipped features (verbose) |
| [architecture.md](architecture.md) | System design and data flow |
| [accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) | WCAG engineering phases |
| [wcag.md](wcag.md) | WCAG 2.1 AA criteria mapping |
| [telemetry.md](telemetry.md) | Logging, Analytics, Crashlytics allowlists |
| [firebase-setup.md](firebase-setup.md) | Firebase Console — Analytics + Crashlytics only |
| [specs/planned/auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md) | Future accounts (not in app) |
| [testing.md](testing.md) | Test strategy and CI |
