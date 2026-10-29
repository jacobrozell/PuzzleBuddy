# Puzzle Buddy — GA4 console checklist (Phase B + 1.1.0 depth)

Register **custom dimensions** (and user properties) in Firebase Console so events and parameters appear in Explorations and funnels.

**Property:** Puzzle Buddy Firebase project (Analytics → select Puzzle Buddy app)  
**Spec:** [ga4-analytics-spec.md](../ga4-analytics-spec.md)  
**Code:** iOS allowlists in `AppLogging.swift`; Android twins in `FirebaseAnalyticsEventMapping.kt` / `AnalyticsMetadataKeys.kt`

**Last updated:** 2026-09-21

---

## Do this now — 1.1.0 analytics depth

New on `release/1.1.0`: `session_snapshot`, `milestone_reached`, collection count params, and user properties.

### A. Custom definitions → Event-scoped dimensions

For each row: **Create custom dimension** → **Scope = Event** → Event parameter = name exactly (snake_case).

| Done | Parameter name | Display name | Events that send it |
|------|----------------|--------------|---------------------|
| [ ] | `count_wishlist` | Count wishlist | `puzzle_list_refreshed`, `session_snapshot` |
| [ ] | `count_todo` | Count to-do | same |
| [ ] | `count_in_progress` | Count in-progress | same |
| [ ] | `count_completed` | Count completed | same |
| [ ] | `count_abandoned` | Count abandoned | same |
| [ ] | `collection_size_bucket` | Collection size bucket | `session_snapshot`, `puzzle_list_refreshed` |
| [ ] | `completed_count_bucket` | Completed count bucket | same |
| [ ] | `days_since_last_open_bucket` | Days since last open | `session_snapshot` |
| [ ] | `milestone_id` | Milestone id | `milestone_reached` |

**Expected values (QA):**

| Parameter | Values |
|-----------|--------|
| `collection_size_bucket` | `0`, `1`, `2_5`, `6_20`, `21_50`, `51_plus` |
| `completed_count_bucket` | `0`, `1`, `2_5`, `6_plus` |
| `days_since_last_open_bucket` | `first_open`, `0`, `1`, `2_7`, `8_30`, `31_plus` |
| `milestone_id` | e.g. `first_puzzle`, `first_completion`, `ten_completed` (see code) |

### B. Custom definitions → User-scoped properties

**Create custom dimension** → **Scope = User** → User property = name exactly.

| Done | Property name | Display name | Values |
|------|---------------|--------------|--------|
| [ ] | `onboarding_complete` | Onboarding complete | `true`, `false` |
| [ ] | `collection_size_bucket` | Collection size bucket | same buckets as event param |
| [ ] | `completed_count_bucket` | Completed count bucket | same as above |
| [ ] | `has_completed_puzzle` | Has completed puzzle | `true`, `false` |

> Same string can exist as **Event** and **User** dimensions — register both scopes separately.

### C. Events — no Console “create event” step

Confirm in **DebugView** / **Realtime** (do not register as custom metrics):

| Done | Event | How to trigger |
|------|-------|----------------|
| [ ] | `session_snapshot` | Cold launch → wait for puzzle list load |
| [ ] | `milestone_reached` | First add / first completion / stats milestone banner |
| [ ] | `puzzle_list_refreshed` | Launch / refresh list (should include count_* params) |

### D. DebugView smoke (same day)

1. [ ] Release / TestFlight build, **or** Debug with `-firebase_analytics_debug` + `-FIRAnalyticsDebugEnabled`
2. [ ] Firebase Console → **Analytics** → **DebugView** → select your device
3. [ ] Journey: cold launch → complete or skip onboarding → add puzzle → complete a puzzle → open Stats
4. [ ] Confirm `session_snapshot` + user properties update; `milestone_reached` when thresholds fire
5. [ ] Wait **24–48h**, then use dimensions in **Explore**

### E. Sign-off

| Step | Done | Date |
|------|------|------|
| 1.1.0 event dimensions (9) | [ ] | |
| 1.1.0 user properties (4) | [ ] | |
| DebugView smoke | [ ] | |
| Explore free-form using `session_snapshot` | [ ] | |

---

## Before you start (any phase)

1. Open [Firebase Console](https://console.firebase.google.com/) → **Puzzle Buddy** project.
2. Go to **Analytics** → **Custom definitions**.
3. Use **Create custom dimension** for each row.
4. Allow **24–48 hours** after registration before breakdowns populate in Explorations.
5. This is **separate from Dart Buddy** — register per Firebase project.

---

## Phase A — existing parameters (register if not done yet)

These parameters were already sent before Phase B. Skip any that show **Active**.

| # | Scope | Parameter name | Display name | Example events |
|---|-------|----------------|--------------|----------------|
| 1 | Event | `puzzle_status` | Puzzle status | `puzzle_added`, `puzzle_updated` |
| 2 | Event | `puzzle_count` | Puzzle count | `puzzle_list_refreshed`, `demo_data_loaded` |
| 3 | Event | `import_policy` | Import policy | `puzzle_import_completed`, `puzzle_backup_restored` |
| 4 | Event | `format` | Export format | `settings_collection_exported` *(legacy; Settings export UI removed)* |
| 5 | Event | `completion_number` | Completion number | `puzzle_completion_recorded` |
| 6 | Event | `completion_count` | Prior completion count | `puzzle_redo_started` |

---

## Phase B — earlier parameters (register if not Active)

For each: **Scope = Event**, **Event parameter** = name exactly as shown (snake_case).

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

Rows for counts / buckets / `milestone_id` are under **Do this now** above.

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

## Phase B — events to confirm in DebugView

| Event | How to trigger |
|-------|----------------|
| `puzzle_status_changed` | Edit puzzle → change status |
| `tab_selected` | Switch Puzzles / Stats / Settings tabs |
| `pick_next_puzzle_selected` | Pick next → Spin |
| `barcode_scan_completed` | Scan barcode in list or shopping mode |
| `onboarding_skipped` | Skip onboarding on page 1 |
| `demo_data_loaded` / `demo_data_removed` | Settings demo controls |
| `session_snapshot` | Cold launch after list load |
| `milestone_reached` | First puzzle / first completion / stats banner |

---

## Related

- [ga4-analytics-spec.md](../ga4-analytics-spec.md) — full report catalog
- [telemetry.md](../telemetry.md) — code allowlists
- [firebase-setup.md](../firebase-setup.md) — project / plist setup
- Dart Buddy reference: [`DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md`](../../DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md)
