# Puzzle Buddy — GA4 analytics & reporting spec

Product-health analytics for Puzzle Buddy (iOS + Android). Defines **what to measure**, **how to report it in GA4**, and **which events/parameters to add over time** — all without PII.

**Implementation reference:** [telemetry.md](telemetry.md) (allowlists, code paths)  
**Console checklist:** [release/ga4-phase-b-console-checklist.md](release/ga4-phase-b-console-checklist.md)  
**Dart Buddy pattern:** [`DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md`](../../DartBuddy/docs/release/1.1.0-ga4-custom-dimensions.md)

**Last updated:** 2026-06-29

---

## 1. Goals

Answer these questions with GA4 Explorations, funnels, and retention reports:

| Theme | Questions |
|-------|-----------|
| **Activation** | Do new users finish onboarding and add their first puzzle? |
| **Core loop** | Add → start (In-Progress) → complete — where do users drop off? |
| **Feature adoption** | Barcode scan, shopping duplicate-check, pick-next, import/export, redo — who uses what? |
| **Collection depth** | How large are collections? How often do users complete vs. abandon? |
| **Quality** | Local store failures (`puzzle_load_failed`, container errors) — rate vs. active users |
| **Retention** | Do users who complete a puzzle return within 7 / 30 days? |

We do **not** profile individuals, track puzzle titles, or build marketing audiences from catalog content.

---

## 2. Privacy rules (non-negotiable)

### Never send to Firebase

| Category | Examples |
|----------|----------|
| Identity / contact | email, name, account id, Firebase Auth uid on events |
| User-entered text | puzzle name, brand (`source`), notes, tags, purchase location, dimensions text |
| Identifiers | barcode value, IPDb row id, file paths, URLs |
| Media | photo bytes, OCR text, image filenames |

Existing blocklist in code: `email`, `uid`, `password`, `token`, `name`, `displayName` ([telemetry.md](telemetry.md)).

### Safe metadata patterns

| Pattern | Example |
|---------|---------|
| **Enums** | `puzzle_status`: `To-Do`, `In-Progress`, `Completed`, `Wishlist`, `Abandoned` |
| **Buckets** | `piece_count_bucket`: `under_500`, `500`, `1000`, `1500_plus`, `unknown` |
| **Booleans as strings** | `has_photo`: `true` / `false` |
| **Counts (not identities)** | `puzzle_count`, `completion_number`, `photo_count` |
| **Source enums** | `add_source`: `manual`, `barcode`, `import`, `demo` |
| **Coarse ratings** | `rating_bucket`: `none`, `1_2`, `3`, `4`, `5` (half-stars rounded down) |

**Rule:** If a parameter could re-identify a specific puzzle or person when combined with other fields, do not ship it.

---

## 3. Current state (shipped)

These events are **already allowlisted** and fire in Release builds. GA4 receives them; **breakdowns in Explorations require registering custom dimensions** (§5).

| Event | Key parameters today | Primary reports |
|-------|---------------------|-----------------|
| `app_bootstrap_ready` → `app_open` | `app_version`, `log_category` | DAU, version mix |
| `onboarding_completed` | — | Activation |
| `puzzle_list_refreshed` | `puzzle_count` | Collection size at launch |
| `puzzle_added` | `puzzle_status` | New puzzle rate, status at add |
| `puzzle_updated` | `puzzle_status` | Edit frequency |
| `puzzle_deleted` | — | Churn signal |
| `puzzle_import_completed` | `puzzle_count`, `import_policy` | Import adoption |
| `puzzle_backup_restored` | `puzzle_count` | Restore adoption |
| `puzzle_redo_started` | `completion_count` | Re-play behavior |
| `puzzle_completion_recorded` | `completion_number` | Completions per puzzle |
| `settings_collection_exported` | `format` | Export format mix |
| `shopping_scan_match` | — | Shopping mode hit rate |
| `shopping_scan_no_match` | — | Shopping mode miss rate |
| `puzzle_load_failed` | `puzzle_status` | Reliability (also Crashlytics 2001) |

**Gap:** High-value flows (pick-next, barcode add, search/filter, status transitions, stats tab) have **no dedicated events yet** — see §7.

---

## 4. Recommended GA4 reports

Build these in **Explore → Free form** or **Funnel exploration**. Allow **24–48h** after registering custom dimensions (§5).

### 4.1 Activation funnel

**Question:** Do installs become active collectors?

```
app_open  →  onboarding_completed  →  puzzle_added
```

| Step | Filter / breakdown |
|------|-------------------|
| `app_open` | First visit only (GA4 segment) |
| `onboarding_completed` | Within 1 session of first open |
| `puzzle_added` | Within 7 days of first open |

**Success metric:** % of new users with ≥1 `puzzle_added` in first 7 days.

### 4.2 Core catalog loop

**Question:** Do users progress puzzles through the lifecycle?

```
puzzle_added  →  puzzle_updated (status = In-Progress)  →  puzzle_completion_recorded
```

Register `puzzle_status` as an event-scoped dimension. For `puzzle_updated`, filter or segment where status transitions to `In-Progress` once §7 ships `status_from` / `status_to`.

**Secondary:** `puzzle_deleted` rate among users who added ≥3 puzzles.

### 4.3 Feature adoption (once §7 events ship)

| Feature | Event(s) | Metric |
|---------|----------|--------|
| Barcode add | `barcode_scan_completed` + `add_source=barcode` | % of `puzzle_added` with barcode source |
| Shopping mode | `shopping_scan_match` + `shopping_scan_no_match` | Match rate = match / (match + no_match) |
| Pick next | `pick_next_puzzle_selected` | Users / week |
| Import | `puzzle_import_completed` | Imports / active user |
| Export | `settings_collection_exported` | By `format` |
| Redo | `puzzle_redo_started` | % of completed users |
| Stats tab | `tab_selected` where `tab=stats` | Tab engagement |

### 4.4 Collection health

**Question:** What does a typical collection look like?

- **Line chart:** `puzzle_list_refreshed` — median `puzzle_count` over time (requires dimension)
- **Pie:** `puzzle_added` broken down by `puzzle_status` at add time
- **Histogram (future):** `piece_count_bucket` on `puzzle_added` and `puzzle_completion_recorded`

### 4.5 Reliability dashboard

| Signal | Source |
|--------|--------|
| Load failures | `puzzle_load_failed` count / `app_open` users |
| Store bootstrap | Crashlytics non-fatals 2002, 2003 |
| Import failures | `puzzle_import_failed` (future) |

Compare failure spikes with app version (`app_version` param, auto-collected).

### 4.6 Retention cohorts

**GA4 built-in:** Retention by **first_open** cohort.

**Custom (Exploration):** Cohort where first event = `puzzle_completion_recorded`; return event = `app_open` or `puzzle_updated` — measures “completed at least one puzzle” retention.

---

## 5. GA4 custom definitions checklist

Register in Firebase Console → **Analytics → Custom definitions** for the **Puzzle Buddy** property only (separate from Dart Buddy).

### 5.1 Phase A — register now (existing parameters)

No code changes required. Register after first TestFlight traffic.

**Event-scoped**

| Parameter | Display name | Priority events |
|-----------|--------------|-----------------|
| `puzzle_status` | Puzzle status | `puzzle_added`, `puzzle_updated`, `puzzle_load_failed` |
| `puzzle_count` | Puzzle count | `puzzle_list_refreshed`, import/restore |
| `import_policy` | Import policy | `puzzle_import_completed`, `puzzle_backup_restored` |
| `format` | Export format | `settings_collection_exported` |
| `completion_number` | Completion number | `puzzle_completion_recorded` |
| `completion_count` | Prior completion count | `puzzle_redo_started` |
| `log_category` | Log category | All (debug only — optional) |

**User-scoped:** none yet (app does not call `setUserProperty`).

### 5.2 Phase B — register when §7 Phase 1 ships

| Parameter | Display name | Events |
|-----------|--------------|--------|
| `add_source` | Add source | `puzzle_added` |
| `piece_count_bucket` | Piece count bucket | `puzzle_added`, `puzzle_completion_recorded` |
| `has_photo` | Has photo | `puzzle_added`, `puzzle_updated` |
| `photo_count` | Photo count | `puzzle_updated` |
| `status_from` | Status before | `puzzle_status_changed` |
| `status_to` | Status after | `puzzle_status_changed` |
| `scan_context` | Scan context | `barcode_scan_completed`, shopping events |
| `filter_kind` | Filter kind | `catalog_filter_applied` |
| `sort_key` | Sort key | `catalog_sort_changed` |
| `tab` | Tab id | `tab_selected` |
| `puzzle_type` | Puzzle type enum | `puzzle_added`, `puzzle_completion_recorded` |
| `difficulty` | Difficulty enum | `puzzle_completion_recorded` |
| `rating_bucket` | Rating bucket | `puzzle_completion_recorded` |
| `has_missing_pieces` | Missing pieces flag | `puzzle_completion_recorded` |

### 5.3 Phase C — user-scoped (optional, mirror Dart Buddy subset)

Set via `AnalyticsUserContext` / `AnalyticsAccessibilityContext` when implemented.

| User property | Display name | Purpose |
|---------------|--------------|---------|
| `onboarding_complete` | Onboarding complete | Segment new vs returning |
| `app_locale` | App locale | Locale adoption |
| `appearance_mode` | Appearance mode | Theme preference |
| `collection_size_bucket` | Collection size bucket | `0`, `1_10`, `11_50`, `51_plus` |
| `has_completed_puzzle` | Has completed puzzle | Power-user segment |
| `import_export_enabled` | Import/export enabled | Product surface flag |
| `voiceover_enabled` | VoiceOver enabled | A11y context |
| `reduce_motion_enabled` | Reduce Motion enabled | A11y context |
| `bold_text_enabled` | Bold Text enabled | A11y context |

**Do not register:** puzzle names, brands, barcodes, notes, tags, purchase locations.

---

## 6. Parameter catalog

Canonical keys for allowlists on iOS (`AppLogging.swift`) and Android (`AnalyticsMetadataKeys.kt`). Add to both in the same PR; run `check-firebase-parity.sh`.

### 6.1 Shipped

| Key | Values | Events |
|-----|--------|--------|
| `puzzle_status` | `Wishlist`, `To-Do`, `In-Progress`, `Completed`, `Abandoned` | add, update, load_failed |
| `puzzle_count` | `"0"`–`"9999"` (string) | list refresh, import, restore |
| `import_policy` | `merge`, `replace_all` | import, restore |
| `format` | `json`, `csv`, … | export |
| `completion_number` | `"1"`, `"2"`, … | completion_recorded |
| `completion_count` | prior count before redo | redo_started |

### 6.2 Proposed — Phase 1 (enrich existing events)

| Key | Values | Events |
|-----|--------|--------|
| `add_source` | `manual`, `barcode`, `import`, `demo` | `puzzle_added` |
| `piece_count_bucket` | `under_500`, `500`, `1000`, `1500_plus`, `unknown` | add, completion |
| `has_photo` | `true`, `false` | add, update |
| `photo_count` | `"0"`–`"5"` | update |

### 6.3 Proposed — Phase 2 (new events)

| Key | Values | Events |
|-----|--------|--------|
| `status_from`, `status_to` | status enum | `puzzle_status_changed` |
| `scan_context` | `shopping`, `quick_add`, `list_scan` | barcode / shopping |
| `scan_result` | `match`, `no_match`, `cancelled` | barcode flows |
| `filter_kind` | `status`, `piece_count`, `needs_photo`, `missing_pieces`, `type`, `material`, `disposition` | `catalog_filter_applied` |
| `filter_value` | enum per kind (e.g. `1000`, `needs_photo`) | `catalog_filter_applied` |
| `sort_key` | `name`, `date`, `rating`, `difficulty`, `piece_count` | `catalog_sort_changed` |
| `tab` | `puzzles`, `stats`, `settings` | `tab_selected` |
| `entry_point` | `list`, `stats`, `widget` (future) | `pick_next_puzzle_selected` |
| `puzzle_type` | `Landscape`, `Mystery`, …, `None` | add, completion |
| `difficulty` | app difficulty enum | completion |
| `rating_bucket` | `none`, `1_2`, `3`, `4`, `5` | completion |
| `has_missing_pieces` | `true`, `false` | completion |
| `milestone_id` | stable slug e.g. `first_completion`, `ten_completed` | `milestone_reached` |
| `import_source` | `ipdb_csv`, `json`, `unknown` | import events |
| `import_outcome` | `success`, `partial`, `failed` | import events |
| `items_imported` | count string | import success |
| `items_skipped` | count string | import success |

### 6.4 Proposed — Phase 3 (future features)

| Key | Events | Feature |
|-----|--------|---------|
| `timer_duration_bucket` | `puzzle_timer_stopped` | In-app timer |
| `ocr_outcome` | `box_photo_ocr_completed` | Box OCR |
| `widget_kind` | `widget_opened` | Home screen widget |
| `widget_action` | `widget_opened` | pick random / in-progress |

---

## 7. Event catalog — proposed additions

Add to allowlist + this doc + parity check in phased PRs. Prefer **one event per user-visible outcome**, not per tap.

### Phase 1 — low effort, high signal

Enrich existing call sites; add minimal new events.

| Event | When | Parameters |
|-------|------|------------|
| *(enrich)* `puzzle_added` | Save new puzzle | + `add_source`, `piece_count_bucket`, `has_photo` |
| *(enrich)* `puzzle_completion_recorded` | New completion row | + `piece_count_bucket`, `puzzle_type`, `difficulty`, `rating_bucket`, `has_missing_pieces` |
| `puzzle_status_changed` | Status field changes | `status_from`, `status_to`, `piece_count_bucket` |
| `tab_selected` | User switches tab | `tab` |
| `pick_next_puzzle_selected` | User confirms pick | `entry_point`, `piece_count_bucket` (filter context) |
| `barcode_scan_completed` | Scanner dismisses with result | `scan_context`, `scan_result` |
| `onboarding_skipped` | Skip on page 1 | `page_index` |
| `demo_data_loaded` | User loads demo collection | `puzzle_count` |
| `demo_data_removed` | User removes demo | — |

**Promote from log-only:** `demo_data_loaded`, `demo_data_removed` ([telemetry.md](telemetry.md)).

### Phase 2 — catalog UX

| Event | When | Parameters |
|-------|------|------------|
| `catalog_filter_applied` | Filter changes | `filter_kind`, `filter_value` |
| `catalog_sort_changed` | Sort changes | `sort_key` |
| `catalog_search_used` | Search submitted / debounced | `result_count_bucket` (`0`, `1_5`, `6_plus`) — **no query text** |
| `puzzle_import_started` | User confirms import | `import_source` |
| `puzzle_import_failed` | Import error | `import_source`, `error_code` (stable enum) |
| `milestone_reached` | Milestone banner first shown | `milestone_id` |

### Phase 3 — future product

| Event | Feature spec |
|-------|--------------|
| `puzzle_timer_started` / `puzzle_timer_stopped` | [in-app-timer.md](../specs/planned/in-app-timer.md) |
| `box_photo_ocr_completed` | [box-photo-ocr.md](../specs/planned/box-photo-ocr.md) |
| `widget_opened` | [home-screen-widget.md](../specs/planned/home-screen-widget.md) |
| `year_in_review_viewed` | [milestones-year-in-review.md](../specs/planned/milestones-year-in-review.md) |

### Keep log-only (do not promote without review)

| Event | Reason |
|-------|--------|
| `puzzle_collection_cleared` | Rare; high intent; log + breadcrumb sufficient unless support need |
| `model_container_*` | Errors only — Crashlytics non-fatals |
| Per-field `puzzle_updated` spam | Prefer `puzzle_status_changed` for lifecycle |

---

## 8. Implementation phases

| Phase | Scope | Console work | Code work |
|-------|-------|--------------|-----------|
| **A** | Ship 1.0 reporting baseline | Register §5.1 dimensions | None |
| **B** | Lifecycle + features | Register §5.2 as params ship | §7 Phase 1 + parameter enrichments |
| **C** | Catalog UX + import funnel | Update dimensions | §7 Phase 2 |
| **D** | User context | Register §5.3 | Port Dart Buddy `AnalyticsUserContext` subset |
| **E** | New features | Per-feature params | §7 Phase 3 |

**Android:** Every event and parameter key must land in `FirebaseAnalyticsEventMapping.kt` / `AnalyticsMetadataKeys.kt` the same commit as iOS.

---

## 9. Verification checklist

After each phase:

1. **DebugView** — TestFlight or `-firebase_analytics_debug` + `-FIRAnalyticsDebugEnabled`; confirm events and params.
2. **Realtime** — Smoke `puzzle_added` → `puzzle_completion_recorded` journey.
3. **Custom definitions** — Confirm dimensions show “Active” in Console.
4. **Exploration** — Re-run §4.1 and §4.2 funnels; confirm breakdowns populate (24–48h delay).
5. **Parity** — `~/Desktop/personal/scripts/check-firebase-parity.sh`
6. **Privacy** — Spot-check no blocked keys; no free text in params.

| Step | Done | Date | Notes |
|------|------|------|-------|
| Phase A dimensions registered | [ ] | | |
| Phase A Exploration smoke | [ ] | | |
| Phase B events shipped | [x] | 2026-06-29 | iOS + Android |
| Phase B dimensions registered | [ ] | | [Checklist](release/ga4-phase-b-console-checklist.md) |
| User properties (Phase D) | [ ] | | |

---

## 10. Related docs

| Doc | Role |
|-----|------|
| [telemetry.md](telemetry.md) | Code allowlists, Crashlytics, adding events |
| [analytics.md](analytics.md) | Developer quick reference |
| [roadmap.md § Observability](roadmap.md#observability-roadmap) | Release alignment |
| [features.md](features.md) | User flows to instrument |

When implementing events, update **telemetry.md § Analytics allowlist** and this doc in the same change.
