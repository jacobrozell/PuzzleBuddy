# Puzzle Buddy — future ideas

Prioritized backlog. Shipped behavior: [`docs/feature-inventory.md`](../docs/feature-inventory.md).

**Active:** [`docs/implementation/1.1.0-completion-history.md`](../docs/implementation/1.1.0-completion-history.md) on `release/1.1.0`

**Competitor gaps:** [`docs/competitive-gap-analysis.md`](../docs/competitive-gap-analysis.md)

**Last updated:** 2026-09-21

---

## Deferred — collection import / export

Settings UI **removed in 1.1.0** (GA4: zero `puzzle_import_completed` / `settings_collection_exported` / `puzzle_backup_restored` since launch).

| Keep for now | Re-ship later |
|--------------|---------------|
| `IPDbCSVImporter`, exporters, JSON backup parsers + `PuzzleStore` import APIs | Settings entry points + summary sheet |

**Spec:** [`specs/planned/collection-import-export.md`](../specs/planned/collection-import-export.md) · also [`json-backup-restore.md`](../specs/planned/json-backup-restore.md)

- [ ] Revisit when there is clear demand (support / research / dogfood)
- [ ] Or delete helpers entirely if the feature stays unused for another major release

---

## 1.1.0 — in progress

| Idea | Spec | Notes |
|------|------|-------|
| **Completion history edit/delete** | [`1.1.0-completion-history.md`](../docs/implementation/1.1.0-completion-history.md) | Accidental-finish recovery |
| **Analytics depth** | [`ga4-analytics-spec.md`](../docs/ga4-analytics-spec.md) | User properties, session snapshot (code on branch) |
| **Onboarding + review prompt** | — | Less skippable onboarding; App Store review popup |

---

## 1.1.x / 1.2.0 — timer & enrichment

| Idea | Spec | Notes |
|------|------|-------|
| **In-app timer (pause)** | [`in-app-timer.md`](../specs/planned/in-app-timer.md) | Puzzle Tracker core loop |
| **Re-ship import/export UI** | [`collection-import-export.md`](../specs/planned/collection-import-export.md) | Helpers already in tree |
| **Attach barcode to existing puzzle** | [`barcode-scan-polish.md`](../ongoing/barcode-scan-polish.md) §13 | |
| **Tappable similar-match prefills** | Same §8 | |
| **Box photo OCR (Vision)** | [`box-photo-ocr.md`](../specs/planned/box-photo-ocr.md) | |
| **Artist field** | Roadmap | Separate from brand |
| **Manufacturer ID / SKU field** | Roadmap | First-class vs notes hack |
| **On loan / leased out** | [`on-loan-friends.md`](../docs/implementation/on-loan-friends.md) | Shipped foundation on 1.1.0 branch (Friends UI hidden). |
| **Preset color themes** | [`color-themes.md`](../specs/planned/color-themes.md) | Free Settings presets (Classic / Sunset / Forest / Midnight). iOS only; separate from review thank-you unlock. |

---

## Later

| Idea | Spec | Notes |
|------|------|-------|
| **Auth + cloud sync** | [`auth-cloud-sync.md`](../specs/planned/auth-cloud-sync.md) | Removed from app — future only |
| **Push notifications** | — | Prerequisite for remote nudges; FCM was removed with Auth |
| **Friends / People list UI** | — | Model + `FriendStore` may ship with On loan (flagged off). Enable Settings entry when ready; no cloud stubs until Auth. |
| Year in review (full) | [`milestones-year-in-review.md`](../specs/planned/milestones-year-in-review.md) | |
| Home screen widget | [`home-screen-widget.md`](../specs/planned/home-screen-widget.md) | |
| **Cosmetic thank-you after App Store review** | — | Optional unlock only (extra theme/style beyond free presets, alternate app icon, higher progress-photo limit). Never gate core catalog features. Design so it does not look like “pay with a review” (Guideline 5.6 / review-manipulation risk) — e.g. thank-you after Settings write-review, or honor-system toggle, not a star-gate. |

### After friends + push — loan poke

| Idea | Depends on | Notes |
|------|------------|-------|
| **Loan poke / nudge** | Linked friends (`remoteId`) + **push notifications** | Facebook-style poke: remind a friend they still have your puzzle. Uses reserved `lastLoanNudgeAt`; overdue can use `dueBackDate`. Rate-limit / cooldown. Not in local On loan v1. |

### Organize polish

- Tag cloud in Collection Stats
- Favorites on brand / tag lists
- `urlLink` (manufacturer / review URL)
