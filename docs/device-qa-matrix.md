# Device QA matrix

Manual checklist before TestFlight / App Store submission. Run on at least one **physical iPhone** (camera + Files) and one **simulator** (fast regression). Mark each row with date, device, and pass/fail.

Related: [agent-build-checklist.md](agent-build-checklist.md) Phase 16, [testing.md](testing.md).

---

## Core collection

| # | Scenario | iPhone device | Simulator | Notes |
|---|----------|---------------|-----------|-------|
| 1 | Cold launch → onboarding (fresh install) or puzzle list | | | |
| 2 | Add puzzle with photo (library) | | | |
| 3 | Add puzzle with camera | | | Required on device |
| 4 | Edit puzzle, change status In-Progress → Completed | | | |
| 5 | Swipe delete puzzle | | | |
| 6 | Status tabs + search by name, brand, barcode | | | |
| 7 | Piece-count / needs-photo / missing-pieces filters | | | |
| 8 | Pull to refresh | | | |

---

## Barcode & shopping

| # | Scenario | iPhone device | Simulator | Notes |
|---|----------|---------------|-----------|-------|
| 9 | Scan barcode from add form | | | Device only |
| 10 | Shopping mode → duplicate match → open puzzle | | | Device or injected test barcode |
| 11 | Shopping mode → no match → quick-add → save | | | |
| 12 | Shopping mode with airplane mode (offline duplicate check) | | | Device |

---

## Import / export

| # | Scenario | iPhone device | Simulator | Notes |
|---|----------|---------------|-----------|-------|
| 13 | Settings → Import IPDb CSV (sample fixture) | | | Files app / AirDrop |
| 14 | Import summary → Needs photo filter | | | |
| 15 | Settings → Export JSON → open in Files | | | |
| 16 | Export IPDb CSV → re-import round-trip | | | |

---

## Layout & accessibility

| # | Scenario | iPhone device | Simulator | Notes |
|---|----------|---------------|-----------|-------|
| 17 | iPhone landscape — puzzle detail side-by-side | | | |
| 18 | iPhone landscape — list filters visible | | | |
| 19 | Dynamic Type XXXL — list + form usable | | | Simulator |
| 20 | VoiceOver — add puzzle form | | | Device recommended |
| 21 | VoiceOver — shopping result card | | | |
| 22 | Reduce Motion on — splash + brand background | | | |

---

## Stats & settings

| # | Scenario | iPhone device | Simulator | Notes |
|---|----------|---------------|-----------|-------|
| 23 | Stats tab loads hero + grid cards | | | |
| 24 | Share collage from completed puzzle | | | |
| 25 | Legal links open in Safari | | | |
| 26 | Load / remove demo data | | | |

---

## Sign-off

| Role | Name | Date | Build # |
|------|------|------|---------|
| Developer | | | |
| Owner | | | |

**Automated coverage (CI):** `Puzzle BuddyTests` (unit), `PuzzleAccessibilityUITests` (WCAG audits, landscape, Dynamic Type, settings import/export presence).
