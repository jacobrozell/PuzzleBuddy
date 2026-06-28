# Reviewer-Readiness Handoff — Puzzle Buddy

> Last updated: 2026-06-27 · Stage: Pre-ship polish (1.0.0 build 1)

## Shipped since last handoff

- **Pick my next puzzle** — dice on collection list (`PickNextPuzzleView`)
- **Wishlist status** — separate from To-Do; excluded from random pick
- **Progress over days** — `startDate` + detail metrics
- **Import/export gated** — `isCollectionImportExportEnabled = false` for 1.0
- **Docs synced** — README, feature-inventory, backlog, specs
- **174 unit tests** passing

## Remaining (human / Connect-side)

1. **Marketing screenshots** — pick-next, shopping mode, stats, local-first
2. **Device smoke** — add → filter → pick-next → detail → stats
3. **VoiceOver manual pass** — Phase 2
4. **App Store Connect** — privacy label (no import/export in 1.0)
5. **Publish GitHub Pages** — push `docs/` (support.html updated)
6. **First TestFlight / App Review upload**

## Dogfood flags

| Flag | Launch arg |
|------|------------|
| Import/export | `-enable_collection_import_export` |
| Login | `-enable_login` |

## Key references

- [`docs/release/todo.md`](../docs/release/todo.md)
- [`FutureIdeas/backlog.md`](../FutureIdeas/backlog.md)
- [`docs/feature-inventory.md`](../docs/feature-inventory.md)
