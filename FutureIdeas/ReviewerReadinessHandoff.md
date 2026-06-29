# Reviewer-Readiness Handoff — Puzzle Buddy

> Last updated: 2026-06-29 · Stage: Pre-ship polish (1.0.0 build 2)

## Shipped since last handoff

- **Pick my next puzzle** — dice on collection list (`PickNextPuzzleView`)
- **Wishlist status** — separate from To-Do; excluded from random pick
- **Progress over days** — `startDate` + detail metrics
- **Import/export gated** — `isCollectionImportExportEnabled = false` for 1.0
- **Auth/cloud removed** — local-first SwiftData only; Firebase Analytics + Crashlytics
- **Docs synced** — README, feature-inventory, backlog, specs
- **163 unit tests** passing

## Remaining (human / Connect-side)

1. **App Store Connect screenshot upload** — assets captured in `marketing-screenshots/`
2. **Device smoke** — add → filter → pick-next → detail → stats
3. **VoiceOver manual pass** — Phase 2
4. **App Store Connect** — privacy label (no import/export in 1.0)
5. **First TestFlight / App Review upload**

## Dogfood flags

| Flag | Launch arg |
|------|------------|
| Import/export | `-enable_collection_import_export` |
| Skip onboarding (UI tests) | `-ui_testing_bypass_onboarding` |
| Seed demo puzzles | `-ui_testing_seed_puzzles` |

## Key references

- [`docs/release/todo.md`](../docs/release/todo.md)
- [`FutureIdeas/backlog.md`](backlog.md)
- [`docs/feature-inventory.md`](../docs/feature-inventory.md)
