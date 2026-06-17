# Roadmap and Future Plans

This document consolidates planned work across releases, accessibility phases, and model extensions. It is the single reference for what ships in **1.0** versus what comes next.

For current shipped behavior, see [features.md](features.md). For architecture of implemented-but-disabled features, see [architecture.md](architecture.md).

### Contents

- [Release strategy](#release-strategy)
- [Release 1.x — Authentication and cloud sync](#release-1x--authentication-and-cloud-sync)
- [Puzzle model extensions](#puzzle-model-extensions)
- [Find & organize — user-driven product strategy](#find--organize--user-driven-product-strategy)
- [Stats and collection insights](#stats-and-collection-insights)
- [Competitive positioning — Puzzle Tracker](#competitive-positioning--puzzle-tracker)
- [Accessibility roadmap](#accessibility-roadmap)
- [Testing and infrastructure roadmap](#testing-and-infrastructure-roadmap)
- [Observability roadmap](#observability-roadmap)
- [Infrastructure and platform](#infrastructure-and-platform)

---

## Release strategy

Puzzle Buddy uses **staged releases** controlled by `ProductService` feature flags rather than separate code branches.

| Release | Theme | Feature flags | Data store |
|---------|-------|---------------|------------|
| **1.0** (current) | Local-first catalog | `isLoginEnabled = false` | SwiftData on device |
| **1.x** (next) | Accounts and cloud sync | `isLoginEnabled = true` | SwiftData + Firestore |
| **Future** | Richer puzzle metadata, stats, competitive polish | TBD | Possibly Cloud Storage for images |

### Enabling features during development

| Flag | Default | Override |
|------|---------|----------|
| `isLoginEnabled` | `false` | Launch argument `-enable_login`, or change `ProductService.swift` |
| `isCloudSyncEnabled` | `false` | Automatically `true` when login is enabled and Firebase is configured |

When login ships to production, the flag will likely move to **Firebase Remote Config** so it can be rolled out gradually without an app update.

---

## Release 1.x — Authentication and cloud sync

Login and Firestore sync are **fully implemented** but disabled for 1.0. This section describes what exists and what remains before shipping.

### Ready for release

| Feature | Status | Notes |
|---------|--------|-------|
| Email/password sign-in | ✅ Implemented | `FirebaseAuthProvider.login()` |
| Email/password registration | ✅ Implemented | Creates Auth user + `/users/{email}` doc |
| Sign in with Apple | ✅ Implemented | Nonce-based OAuth via `AuthenticationServices` |
| Forgot password | ✅ Implemented | `ForgotPasswordView` |
| Firestore puzzle CRUD | ✅ Implemented | `PuzzleStore` dual-path local + cloud |
| Security rules | ✅ Implemented | `firestore.rules` — email must match `userId` |
| Sign out | ✅ Implemented | `SettingsView` when login enabled |
| Profile management | ✅ Partial | `ProfileView` — password reset, username change |

### Work remaining before shipping login

| Item | Priority | Description |
|------|----------|-------------|
| **Local-to-cloud migration** | High | On first sign-in, upload existing SwiftData puzzles to Firestore. Not yet implemented. |
| **Remote Config flag** | High | Replace static `isLoginEnabled` with Remote Config for gradual rollout |
| **`createAccountWithApple` stub** | Medium | Apple OAuth creates Auth user but dedicated account-creation helper is commented out; verify Firestore user doc is created for Apple-only sign-ups |
| **`ProfileView` integration** | Medium | Wire profile into navigation (tab or settings section); handle `// TODO else` when no user |
| **Firebase Emulator tests** | Medium | Isolated integration tests for Firestore paths and rules |
| **Manual QA checklist** | High | Full auth flow with `-enable_login`, multi-device sync, offline behavior |
| **App Store metadata** | Medium | Update privacy policy if cloud storage is described; enable Auth providers in Firebase Console |
| **Deploy Firestore rules** | High | `firebase deploy --only firestore:rules` before enabling sync |

### Firestore data model (cloud sync)

**User document:** `/users/{email}`

| Field | Type | When set |
|-------|------|----------|
| `username` | string | Account creation |
| `currentVersion` | string | Every login (`updateUser()`) |
| `lastLoggedIn` | timestamp | Every login |

**Puzzle subcollection:** `/users/{email}/puzzles/{puzzleId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | UUID string |
| `name` | string | |
| `pieces` | int or `"nil"` | |
| `rating` | double | |
| `difficulty` | string | |
| `estimatedTimeSpent` | string | e.g. `"2hr:30min"` |
| `completionDate` | timestamp | |
| `status` | string | `To-Do` or `Completed` |
| `imageData` | string | Base64 JPEG or `"nil"` |

### Known cloud sync limitations

| Limitation | Impact | Future mitigation |
|------------|--------|-------------------|
| Images as Base64 in Firestore docs | 1 MB document size limit; slow sync for large photos | Migrate to **Firebase Cloud Storage** with URL reference in puzzle doc |
| No offline conflict resolution | Last write wins | Consider Firestore offline persistence + merge strategy |
| Email as document ID | Email change breaks path | Consider UID-based paths with email as a field |
| No bidirectional merge on login | Local and cloud data may diverge | Implement migration + conflict UI |

### Testing login locally

```bash
# In Xcode: Edit Scheme → Run → Arguments → add -enable_login
# Or from CLI with xcodebuild, pass the launch argument to the simulator
```

Prerequisites:

1. Real `GoogleService-Info.plist` (not the example placeholder)
2. Email/Password and Apple providers enabled in Firebase Console
3. Firestore rules deployed

See [firebase-setup.md](firebase-setup.md).

---

## Puzzle model extensions

Commented fields in `PuzzleObject.swift` indicate planned metadata. None are implemented yet. Additional fields below come from [stats planning](#stats-and-collection-insights) and [competitive analysis](#competitive-positioning--puzzle-tracker).

### Existing planned fields (`PuzzleObject.swift`)

| Field | Description | Complexity |
|-------|-------------|------------|
| `category` | Puzzle type (landscape, mystery, etc.) | Low — new enum + picker |
| `barcode` | Scan UPC on puzzle box | Medium — VisionKit scanner | See [spec-barcode-scanner.md](spec-barcode-scanner.md); metadata strategy in [barcode-metadata-strategy.md](barcode-metadata-strategy.md) |
| `timer` | In-app puzzle timer | Medium — background timer, Live Activity |
| `price` | Purchase price tracking | Low — currency field |
| `notes` | Free-text notes | Low — text area |
| `urlLink` | Link to manufacturer or review | Low — URL field |
| Reverse image search | Auto-fill puzzle info from photo | High — ML or external API |

### Additional planned fields (product strategy)

| Field | Description | Complexity | Driver |
|-------|-------------|------------|--------|
| `tags` | User-defined labels (e.g. "winter", "Wysocki") | Medium — tag list + filter UI | Competitor; random-pick filters |
| `brand` / `manufacturer` | Puzzle brand or artist | Low | Duplicate check; favorites |
| `startDate` | When puzzling began | Low | Days-to-complete; progress tracking |
| `disposition` | Post-completion fate: Kept, Donated, Sold, Gifted, Trashed | Low | Competitor review requests |
| `hasMissingPieces` | Boolean flag | Low | Thrift-store finds; competitor filter |
| `material` | Cardboard, wood, etc. | Low | Competitor review requests |
| `purchaseLocation` | Where the puzzle was bought | Low | Competitor metadata |
| `progressPhotos` | Additional photos beyond cover image | Medium | Progress-over-days without full re-do model |

### Status enum extension

`In-Progress` status is shipped in `Puzzle.Status`:

```swift
case inProgress = "In-Progress"
```

**Target lifecycle** (aligned with competitor folders, simplified for Puzzle Buddy):

| Status | Meaning | Priority |
|--------|---------|----------|
| `Wishlist` | Want to buy / don't own yet | P2 — new enum case + migration |
| `To-Do` | Owned, not started | ✅ Shipped |
| `In-Progress` | On the table now | ✅ Shipped |
| `Completed` | Finished | ✅ Shipped |
| `Abandoned` | Will not finish | P2 — competitor has this |

Adding new statuses requires:

- Migration of existing `PuzzleRecord` rows (default unchanged)
- Updated pickers in form and detail
- Status tabs / filters on `PuzzleList`
- Analytics metadata already supports arbitrary `puzzle_status` strings

### UI improvements (near-term)

| Item | Location | Description |
|------|----------|-------------|
| Editable `RatingsView` on form | `PuzzleForm.swift` | ✅ Visual half-star control with tap + VoiceOver adjustable |
| Search / filter | `PuzzleList` | `searchText` state exists but is not wired to filtering yet |
| Profile tab or settings section | Navigation | Surface `ProfileView` for account management |

---

## Find & organize — user-driven product strategy

Product thinking for collectors with growing libraries (roughly 20–200 puzzles). The core problem today: the list is a single chronological log — fine for a dozen puzzles, frustrating at scale. Users need to answer *"Where is that winter cabin puzzle?"* and *"What should I work on next?"*

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
| **Tags** (multi, user-defined) | "How I think about my collection" | `cozy`, `Wysocki`, `2024` | P1 — with find & organize bundle |
| **Category** (single, preset enum) | "What kind of puzzle is this?" | Landscape, Mystery, Gradient | P2 — after tags prove useful |
| **Brand** (structured field) | "Who made it?" | Ravensburger, Galison | P2 — duplicate check, favorites, stats by brand |

### Recommended build order (find & organize)

Ship in this order so each layer makes the next feel valuable:

| Step | Features | Rationale |
|------|----------|-----------|
| 1 | **Search by name** + **status tabs** (All / To-Do / Completed) + **sort** (name, rating, pieces, date) | Table stakes; status is already stored but not used to segment the list |
| 2 | **Custom tags** — add/edit chips, filter by tag on list, tag counts in stats | Flexible organization; enables pick-next filters |
| 3 | **"Pick my next puzzle"** — random from backlog, optional tag and piece-count filters | Delight + practical; low cost once filters exist |

Backlog IDs: `list-search-sort`, `list-status-tabs`, `field-tags`, `pick-next` in [implementation-playbook.md](implementation-playbook.md).

### Feature tiers (user impact)

**High value — users would notice immediately**

| Feature | User need | Backlog ID / field |
|---------|-----------|-------------------|
| In Progress status | Puzzle on the table right now | `status-in-progress` |
| Notes | Missing pieces, lent to someone, thrift price | `field-notes` |
| Pick my next puzzle | Random from backlog, filtered | `pick-next` |
| Duplicate check | "Do I already own this?" while shopping | `list-search-sort`, `barcode-scan` |
| Wishlist | Want to buy, don't own yet | `status-wishlist-abandoned` |

**Medium value — deep collectors**

| Feature | User need | Backlog ID / field |
|---------|-----------|-------------------|
| Brand / manufacturer | Search, favorites, stats by brand | `field-brand` |
| Barcode scan | Fast add + duplicate prevention | `barcode-scan` |
| Missing pieces flag | Common for thrift finds; filterable | `field-missing-material` |
| Start date + timer | Actual time vs manual estimate | `field-start-date`, `timer` |
| Progress photos | WIP shots, not just finished box | `progress-photos` |

**Delight — retention, not core loop**

| Feature | User need | Backlog ID |
|---------|-----------|------------|
| Widgets | In-progress or random To-Do on home screen | `widget` |
| Milestones | "50th puzzle completed" | `milestones` |
| Share card | Finished puzzle image + stats for social | `year-in-review`, `share-collage` |

### What not to chase (yet)

- **Full Puzzle Tracker filter matrix** — brand + year + purchase location + exclude mode + every metadata dimension at once; overwhelming until base list UX is solid
- **Fixed tag taxonomy only** — prefer free-form tags; optional presets can supplement later
- **Custom fields / folders** — power-user complexity; defer unless users ask

### Smallest high-impact slice

If shipping one cohesive increment: **status tabs + search + sort + tags**. That is the point where the app feels like a collection tool rather than a chronological log.

---

## Stats and collection insights

Today the only derived stat on puzzle detail is **pieces per minute**, which is niche (speed puzzlers) and weak when time is a rough estimate. Collection-level stats do not exist yet. Planned work is phased by data-model cost.

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
| Photo gallery per puzzle | ✅ | ✅ Single photo | Multi-photo progress shots |
| Status folders | Wishlist, Waiting list, Completed, Abandoned, In progress | To-Do, Completed | Add In-Progress + Wishlist; consider Abandoned |
| Built-in timer (pause) | ✅ Core feature | ❌ Manual time only | High-value match; pairs with In-Progress |
| Progress by photos + days | ✅ | ❌ | Start date + optional progress photos |
| Filtering and sorting | ✅ Extensive (tags, brand, year, type, purchase location, missing pieces, exclude mode) | ❌ `searchText` unwired | Wire search; add filters incrementally |
| Barcode scan | ✅ Bulk + manual entry | ❌ Planned (`barcode` field) | Duplicate-check while shopping — top user request in reviews |
| Tags | ✅ (e.g. seasonal) | ❌ | Tags or categories for Wheel-style picks |
| Custom fields / folders | ✅ Premium | ❌ | Lower priority unless power users ask |
| Brand, artist, manufacturer | ✅ | ❌ | Brand field unlocks favorites + duplicate check |
| Purchase location / price | ✅ | `price` planned | Thrift-store hunters care about this |
| Disposition after complete | ✅ Kept, donated, sold, trashed | ❌ | Review-requested; distinct from status |
| Puzzle material (cardboard, wood) | ✅ Requested in reviews | ❌ | Nice-to-have metadata |
| Missing pieces flag | ✅ Filterable | ❌ | Practical for thrift finds |
| Wheel of Fortune (random pick) | ✅ Filterable by list/tags | ❌ | Fun differentiator; low build cost |
| Re-do / multiple attempts | ✅ Separate attempts with summary table | ❌ | Niche; defer unless speed puzzlers |
| Share results / collages | ✅ | ❌ | Year-in-review + share card |
| Friend sharing / social | ✅ v7.3+ | ❌ | Could differentiate via privacy-first local sync later |
| Statistics screen | ✅ Improved over time | ✅ Collection Stats tab | Milestones, year-in-review still planned |
| Favorites on metadata lists | ✅ Brands, tags, artists | ❌ | After brand/tags exist |
| Accessibility statement | Not indicated | ✅ WCAG work in progress | **Differentiator** — lean into a11y |
| Account required | Premium cloud features | ❌ Local-first, optional sync | **Differentiator** — no account for core use |
| Privacy / no tracking pitch | Collects linked data | Analytics allowlist only | **Differentiator** — document clearly |

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
| Local-first, no account | Core catalog works offline forever; cloud is opt-in |
| Accessibility | WCAG 2.1 AA target; VoiceOver, Dynamic Type, Reduce Motion — market this |
| Native SwiftUI polish | Fast, simple flows vs feature-bloated competitor |
| Privacy-safe analytics | Allowlisted events only; no PII — contrast in App Store copy |

**4. Suggested build order vs competitor gaps**

| Priority | Feature | Rationale |
|----------|---------|-----------|
| P0 | Collection stats screen | Quick win; competitor has this; we have the data |
| P0 | Status tabs + search | Table stakes for any catalog app |
| P1 | In-Progress + timer | Matches competitor core loop; unlocks real time stats |
| P1 | Barcode scan | Top review theme: duplicate prevention |
| P1 | Tags or categories | Enables seasonal stash + random pick filters |
| P2 | Wheel of Fortune | Delight feature; cheap once filters exist |
| P2 | Brand / manufacturer field | Search + favorites + duplicate check |
| P2 | Notes + disposition | Journaling and "what happened to this puzzle" |
| P3 | Multi-photo progress | Progress-over-days without full attempt model |
| P3 | Share collage / year in review | Premium-feeling polish |
| Defer | Friend sharing, custom fields, bulk AI scan, re-do attempts | High complexity; competitor's long tail |

**5. What not to chase (yet)**

- Feature parity with Puzzle Tracker's entire filter matrix — overwhelming for v1.x
- Premium tier / IAP until core loop beats free competitor on simplicity + a11y
- Social graph before local-to-cloud migration is solid

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
| Friend sharing (v7.3+) | Defer; differentiate with privacy-first optional cloud sync later |
| Custom fields / folders | Skip for v1.x — power-user complexity |
| Bulk AI barcode scan | Start with single scan + manual entry; bulk later |

### Product positioning summary

Puzzle Buddy competes on **simplicity, local-first trust, accessibility, and collection pride** — not feature parity with a mature freemium CRM-style tracker.

| Pillar | Message |
|--------|---------|
| Simplicity | Fewer taps to log a puzzle; no premium wall for core catalog |
| Local-first | Full catalog offline with no account; cloud sync opt-in when ready |
| Accessibility | WCAG 2.1 AA — market VoiceOver, Dynamic Type, Reduce Motion |
| Collection pride | Total puzzles, pieces, hours — not speed metrics |
| Privacy | Allowlisted analytics only; no PII in telemetry |

---

## Accessibility roadmap

Tracked in detail in [../accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) and [wcag.md](wcag.md). Summary by phase:

### Phase 1 — Done ✅

- VoiceOver labels on login and primary actions
- `A11yID` identifiers for UI tests
- Reduce Motion on brand gradient
- GitHub Pages accessibility statement
- `XCUIAccessibilityAudit` suite on key screens

### Phase 2 — Next

| Work item | WCAG criteria | Screens |
|-----------|---------------|---------|
| Puzzle form VoiceOver audit | 4.1.2 Name, Role, Value | Form — name, pieces, rating, difficulty, date, status, photo |
| Puzzle detail reading order | 1.3.2 Meaningful Sequence | Detail view |
| Rating/difficulty value announcements | 4.1.2 | `RatingsView`, `DifficultyView` |
| Delete confirmation labels | 4.1.2 | List swipe delete |
| Dynamic Type audit | 1.4.4 Resize Text | `PuzzleCell`, form, tab bar |
| Contrast verification | 1.4.3, 1.4.11 | Accent on card, star inactive states, placeholders |
| Sync status announcement | 4.1.3 Status Messages | When cloud sync ships |

### Phase 3 — Polish

| Work item | Description |
|-----------|-------------|
| Localization | `Localizable.strings` for all user-facing copy |
| Lottie Reduce Motion | Static frame or pause when Reduce Motion is on |
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
| Firebase Emulator integration tests | Planned | Isolated Firestore rules and sync testing |
| Snapshot tests | Optional | Visual regression for key screens |
| Landscape layout tests | ✅ Done | Login and puzzle list |
| Codemagic CI | Config present | Additional CI path via `codemagic.yaml` |

---

## Observability roadmap

| Item | Status | Notes |
|------|--------|-------|
| Remote Config for feature flags | Planned | Replace static `ProductService` flags |
| Screen-level UI analytics | Optional | `LogCategory.ui` exists; few events today |
| Push notification use cases | Exploratory | FCM wired but unused — could notify on shared puzzle lists in a social feature |
| `password_reset_sent` analytics | Implemented | Verify allowlist includes this event if funnels are needed |

---

## Infrastructure and platform

| Item | Notes |
|------|-------|
| **Cloud Storage for images** | Recommended before large photo libraries sync to Firestore |
| **iPad-optimized navigation** | Adaptive layouts exist; consider sidebar navigation on regular size class |
| **Widgets / Live Activities** | Puzzle timer or "puzzle in progress" widget |
| **Share extension** | Add puzzle from Safari or Photos share sheet |
| **macOS / visionOS** | Not planned; iOS 17+ iPhone and iPad only |
| **Android** | Out of scope; separate codebase if ever pursued |

---

## How to propose or track new work

1. **Accessibility** — update [accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) and the [conformance matrix](../accessibility/wcag-2.1-aa/conformance-matrix.md)
2. **Features** — add to this document under the appropriate release section
3. **Architecture changes** — update [architecture.md](architecture.md)
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
| [firebase-setup.md](firebase-setup.md) | Firebase project setup for login release |
| [testing.md](testing.md) | Test strategy and CI |
