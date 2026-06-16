# Implementation playbook

How to build roadmap features in bulk, then cut a marketing **1.0.0** and plan follow-on releases.

**Source of truth:** [roadmap.md](roadmap.md) (stats, competitive positioning, model extensions).

---

## Strategy

1. **Build phase** — Implement roadmap items one at a time on `main` (or feature branches). Ship complete, tested slices. Mark items done in `roadmap.md` when merged.
2. **Cut phase** — When enough is built, choose what ships as **1.0.0** for App Store marketing. Hide or flag the rest via `ProductService` or `#if` only if needed for the cut; prefer leaving code in and gating UI if incomplete.
3. **Release drafting** — Everything not in 1.0.0 becomes **1.1**, **1.2**, etc. Update `roadmap.md` release table and App Store "What's New" drafts as you market.

Current app version constant: `Puzzle_BuddyApp.version` in `Puzzle_BuddyApp.swift` (also `CFBundleShortVersionString` in `Puzzle-Buddy-Info.plist`).

---

## Feature backlog (implement all, cut later)

Check off in `roadmap.md` as each ships. Suggested build order:

| # | ID | Feature | Roadmap | Schema change |
|---|-----|---------|---------|---------------|
| 1 | `stats-collection` | Collection Stats screen (hero cards from existing data) | Phase A ✅ | No |
| 2 | `detail-metrics` | Replace PPM with hours/1k pieces + time bucket labels | Phase A ✅ | No |
| 3 | `list-status-tabs` | To-Do / In-Progress / Completed / All segments on `PuzzleList` | Phase B ✅ | No |
| 4 | `list-search-sort` | Wire `searchText`; sort by date, rating, difficulty, pieces | Phase B ✅ | No |
| 5 | `list-rating-stars` | Rating summary on `PuzzleCell` | Phase B ✅ | No |
| 6 | `form-ratings-ui` | Editable `RatingsView` on `PuzzleForm` | UI improvements ✅ | No |
| 7 | `status-in-progress` | `In-Progress` status + form/detail/list support | Status extension ✅ | No* |
| 8 | `field-notes` | Free-text notes on puzzle | Model extensions | Yes |
| 9 | `field-brand` | Brand / manufacturer field | Model extensions | Yes |
| 10 | `field-start-date` | Start date + days-to-complete on detail | Model extensions | Yes |
| 11 | `timer` | In-app timer with pause (pairs with In-Progress) | Model extensions | Yes |
| 12 | `field-tags` | User-defined multi-select tags + filter chips on list + tag stats | [Find & organize](roadmap.md#find--organize--user-driven-product-strategy) | Yes |
| 13 | `pick-next` | "Pick my next puzzle" (random from filtered backlog) | [Find & organize](roadmap.md#find--organize--user-driven-product-strategy) | No* |
| 14 | `barcode-scan` | Barcode field + scanner for duplicate check | Model extensions | Yes |
| 15 | `status-wishlist-abandoned` | Wishlist + Abandoned statuses | Status extension | Yes |
| 16 | `field-disposition` | Post-completion disposition enum | Model extensions | Yes |
| 17 | `field-missing-material` | `hasMissingPieces`, `material`, `purchaseLocation`, `price` | Model extensions | Yes |
| 18 | `milestones` | Threshold celebrations (50 puzzles, 10k pieces) | Phase B | No |
| 19 | `year-in-review` | Shareable year summary card | Phase D | No |
| 20 | `widget` | Backlog + recent completions widget | Phase D | No |
| 21 | `heatmap` | Completion activity heatmap | Phase D | No |
| 22 | `share-collage` | Completed puzzle grid share image | Phase D | No |
| 23 | `progress-photos` | Optional progress photos (2–3 per puzzle) | Model extensions | Yes |
| 24 | `login-ship` | Enable login + cloud sync (separate release track) | Release 1.x | N/A |

\* `pick-next` needs status tabs; tag filters need `field-tags`. `status-in-progress` uses the existing `PuzzleRecord.status` string — no SwiftData migration. Per [find & organize strategy](roadmap.md#find--organize--user-driven-product-strategy), ship `list-search-sort` + `list-status-tabs` before or with `field-tags`; bundle tags with pick-next for maximum impact.

**Defer (not in build-all list):** friend sharing, custom fields/folders, bulk AI barcode, re-do attempts, IAP/premium tier.

---

## Suggested 1.0.0 marketing cut (draft — revise after build phase)

| Ship in 1.0.0 | Hold for 1.1+ |
|---------------|---------------|
| Collection stats | Timer + Live Activity |
| Status tabs + search + sort + In-Progress | Barcode scan |
| Rating on list + form star control | Tags + pick-next |
| Remove/hide PPM; friendly time labels | Wishlist / Abandoned |
| Local-first, no account | Notes, brand, disposition, metadata fields |
| Accessibility polish | Widget, year-in-review, collage |

Revise this table once features exist and you can demo the app.

---

## Copy-paste agent query

Use this in Cursor to start a session. Replace `FEATURE_ID` or say "pick the next incomplete item."

```
Implement one roadmap feature for Puzzle Buddy.

## Context
- Repo: Puzzle Buddy (SwiftUI, SwiftData, iOS 17+)
- Strategy: Build ALL roadmap items, then cut marketing 1.0.0 later. Do not scope-down unless I say so.
- Read first: docs/roadmap.md, docs/implementation-playbook.md, docs/architecture.md, docs/features.md
- Match existing conventions: Brand/DS tokens, A11yID identifiers, PuzzleStore CRUD, SwiftData via PuzzleRecord

## Pick feature
[ Choose one:
  - "Next" → first incomplete item from docs/implementation-playbook.md backlog table (by #)
  - Or explicit ID, e.g. FEATURE_ID=stats-collection
]

## Requirements for this slice
1. Implement end-to-end (model if needed → store → UI → tests)
2. SwiftData migration if schema changes; update PuzzleRecord init/apply/toPuzzle + Firestore getDataFields when applicable
3. VoiceOver labels and A11yID on new interactive UI
4. Unit tests for logic; UI test or accessibility identifier if new primary screen
5. Update docs/features.md (shipped behavior) and mark item done in docs/roadmap.md
6. Do NOT bump marketing version or create git commits unless I ask
7. Build and run tests via XcodeBuildMCP when done

## Out of scope this session
Login/cloud sync (unless FEATURE_ID=login-ship), friend sharing, IAP, deferred items in roadmap

When finished, summarize: what shipped, how to try it in the simulator, what's next in the backlog, and any 1.0.0 vs later release note.
```

---

## Shorter "next item" query

```
Puzzle Buddy — implement the next incomplete feature from docs/implementation-playbook.md (backlog table, top to bottom). Read roadmap + architecture first. Full slice: code, tests, a11y, doc updates. No commits. Tell me what's next when done.
```

---

## After each feature

- [ ] `roadmap.md` — mark section done or move to "Shipped in build"
- [ ] `features.md` — document user-facing behavior
- [ ] `architecture.md` — if schema or navigation changed
- [ ] Run unit + UI tests locally or CI

## Release cut checklist (when ready to market 1.0.0)

- [ ] Finalize 1.0.0 feature table in this doc
- [ ] Set `Puzzle_BuddyApp.version` and `CFBundleShortVersionString` to `1.0.0`
- [ ] App Store screenshots reflect shipped features only
- [ ] `docs/roadmap.md` — split "Shipped 1.0.0" vs "1.1+"
- [ ] Draft What's New for 1.0.0; keep 1.1+ bullets from held features
