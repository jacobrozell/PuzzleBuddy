# Puzzle Buddy — GA4 Phase B console checklist

Register **custom dimensions** in Firebase Console so Phase B events and parameters appear in Explorations and funnels.

**Property:** Puzzle Buddy Firebase project (Analytics → select Puzzle Buddy app)  
**Spec:** [ga4-analytics-spec.md](../ga4-analytics-spec.md)  
**Code:** Phase B shipped in iOS + Android allowlists (`AppLogging.swift`, `FirebaseAnalyticsEventMapping.kt`)

**Last updated:** 2026-06-29

---

## Before you start

1. Open [Firebase Console](https://console.firebase.google.com/) → **Puzzle Buddy** project.
2. Go to **Analytics** → **Custom definitions**.
3. Use **Create custom dimension** for each row below.
4. Allow **24–48 hours** after registration before breakdowns populate in Explorations.
5. This is **separate from Dart Buddy** — repeat registration per Firebase project.

---

## Phase A — existing parameters (register if not done yet)

These parameters were already sent before Phase B. Skip any that show **Active**.

| # | Scope | Parameter name | Display name | Example events |
|---|-------|----------------|--------------|----------------|
| 1 | Event | `puzzle_status` | Puzzle status | `puzzle_added`, `puzzle_updated` |
| 2 | Event | `puzzle_count` | Puzzle count | `puzzle_list_refreshed`, `demo_data_loaded` |
| 3 | Event | `import_policy` | Import policy | `puzzle_import_completed`, `puzzle_backup_restored` |
| 4 | Event | `format` | Export format | `settings_collection_exported` |
| 5 | Event | `completion_number` | Completion number | `puzzle_completion_recorded` |
| 6 | Event | `completion_count` | Prior completion count | `puzzle_redo_started` |

---

## Phase B — new parameters (register all)

For each: **Scope = Event**, **Event parameter** = parameter name exactly as shown (snake_case).

| # | Parameter name | Display name | Priority events |
|---|----------------|--------------|-----------------|
| 7 | `add_source` | Add source | `puzzle_added` |
| 8 | `piece_count_bucket` | Piece count bucket | `puzzle_added`, `puzzle_completion_recorded`, `puzzle_status_changed`, `pick_next_puzzle_selected` |
| 9 | `has_photo` | Has photo | `puzzle_added`, `puzzle_updated` |
| 10 | `photo_count` | Photo count | `puzzle_updated` |
| 11 | `status_from` | Status before | `puzzle_status_changed` |
| 12 | `status_to` | Status after | `puzzle_status_changed` |
| 13 | `scan_context` | Scan context | `barcode_scan_completed` |
| 14 | `scan_result` | Scan result | `barcode_scan_completed` |
| 15 | `tab` | Tab | `tab_selected` |
| 16 | `entry_point` | Entry point | `pick_next_puzzle_selected` |
| 17 | `page_index` | Page index | `onboarding_skipped` |
| 18 | `puzzle_type` | Puzzle type | `puzzle_completion_recorded` |
| 19 | `difficulty` | Difficulty | `puzzle_completion_recorded` |
| 20 | `rating_bucket` | Rating bucket | `puzzle_completion_recorded` |
| 21 | `has_missing_pieces` | Missing pieces | `puzzle_completion_recorded` |

### Expected parameter values (for QA)

| Parameter | Values |
|-----------|--------|
| `add_source` | `manual`, `barcode`, `import`, `demo` |
| `piece_count_bucket` | `under_500`, `500`, `1000`, `1500_plus`, `unknown`, `any` |
| `has_photo` / `has_missing_pieces` | `true`, `false` |
| `status_from` / `status_to` / `puzzle_status` | `Wishlist`, `To-Do`, `In-Progress`, `Completed`, `Abandoned` |
| `scan_context` | `shopping`, `list_scan` |
| `scan_result` | `match`, `no_match` |
| `tab` | `puzzles`, `stats`, `settings` |
| `entry_point` | `list`, `stats` |
| `rating_bucket` | `none`, `1_2`, `3`, `4`, `5` |

---

## Phase B — new events (no separate registration)

Custom **events** do not need Console registration. Confirm they appear in **DebugView** or **Realtime** after a TestFlight smoke:

| Event | How to trigger |
|-------|----------------|
| `puzzle_status_changed` | Edit puzzle → change status |
| `tab_selected` | Switch Puzzles / Stats / Settings tabs |
| `pick_next_puzzle_selected` | Pick next → Spin (iOS) |
| `barcode_scan_completed` | Scan barcode in list or shopping mode |
| `onboarding_skipped` | Skip onboarding on page 1 |
| `demo_data_loaded` | Load demo data in Settings |
| `demo_data_removed` | Remove demo data in Settings |

Enriched existing events (`puzzle_added`, `puzzle_completion_recorded`) gain Phase B parameters automatically.

---

## Verification steps

### 1. DebugView smoke (same day)

1. Install a **Release** or TestFlight build (or Debug with `-firebase_analytics_debug` + `-FIRAnalyticsDebugEnabled`).
2. Firebase Console → **Analytics** → **DebugView**.
3. Run this journey:
   - Skip or complete onboarding
   - Add a puzzle manually
   - Change status To-Do → In-Progress → Completed
   - Switch to Stats tab
   - Scan a barcode (match or no match)
4. Confirm events above appear with expected parameters.

### 2. Custom definitions (same day)

In **Custom definitions**, each Phase A + B dimension shows **Active** (not Pending indefinitely).

### 3. Exploration smoke (24–48h later)

**Explore → Funnel exploration:**

```
app_open  →  onboarding_completed  →  puzzle_added
```

Add breakdown on step 3 by **Add source** (`add_source`).

**Explore → Free form:**

- Rows: `puzzle_status_changed`
- Columns: **Status after** (`status_to`)
- Values: Event count

---

## Sign-off

| Step | Done | Date | Notes |
|------|------|------|-------|
| Phase A dimensions (6) | [ ] | | |
| Phase B dimensions (15) | [ ] | | |
| DebugView smoke | [ ] | | |
| Funnel exploration | [ ] | | |

---

## Related

- [ga4-analytics-spec.md](../ga4-analytics-spec.md) — full report catalog
- [telemetry.md](../telemetry.md) — code allowlists
- [firebase-setup.md](../firebase-setup.md) — project / plist setup
- Dart Buddy reference: [`DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md`](../../DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md)
