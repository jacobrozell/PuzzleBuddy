# Agent Build Checklist — Puzzle Buddy (0 → Ship)

Ordered checklist for building Puzzle Buddy from brainstorm to App Store. Focuses on engineering concepts, release discipline, and agent tooling.

**Status:** Living document — check boxes, add dates and commit hashes as phases complete.

**Reference implementation:** [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy) — copy the *structure*, not the domain.

**Product register:** [feature-inventory.md](feature-inventory.md)  
**Behavior specs:** [features.md](features.md), [architecture.md](architecture.md), [roadmap.md](roadmap.md)

---

## Agent query template (paste to start a new session)

```text
You are building Puzzle Buddy. Read AGENTS.md first, then docs/agent-build-checklist.md.

Rules:
1. Local-first — SwiftData only; no Auth/Firestore unless auth-cloud-sync spec is approved
2. Telemetry — AppLog allowlists in AppLogging.swift; document in docs/telemetry.md
3. Test-first for domain logic
4. XcodeGen — regenerate project; do not commit .xcodeproj
5. Accessibility is a release gate (WCAG 2.1 AA)
6. Update feature-inventory.md and telemetry.md when shipping behavior changes

App: Puzzle Buddy / com.jacobrozell.Puzzle-Buddy · iOS 18+ · Firebase Analytics+Crashlytics only
```

---

## Living document rules

| When | Update |
|------|--------|
| Phase completes | Check box + date + commit in **Progress log** |
| New screen ships | [features.md](features.md) + [feature-inventory.md](feature-inventory.md) + accessibility tracker |
| Release scope changes | `ProductService` flags + this checklist + roadmap 1.0 cut table |
| New user-visible string | All bundled locale files + parity test (when i18n ships) |
| New analytics event | [analytics.md](analytics.md) allowlist + mapping tests |
| Pre-spec idea | [roadmap.md](roadmap.md) backlog — promote to features.md when rules lock |

**Source-of-truth hierarchy:** this checklist → system docs (`architecture.md`, `wcag.md`) → [features.md](features.md) → [feature-inventory.md](feature-inventory.md) → [roadmap.md](roadmap.md) (future / non-authoritative for shipped behavior)

### Progress log

| Phase | Completed | Commit | Notes |
|-------|-----------|--------|-------|
| 0 | 2026-06-16 | `ff261ee` | XcodeGen, CI, SwiftLint, hooks, CONTRIBUTING |
| 1 | — | — | Informal docs; no `specs/` folder yet |
| 2 | partial | WIP | Design tokens + a11y Phase 1 |
| 3 | partial | WIP | `CollectionStats`, `PuzzleListFilter`, `PuzzleDetailMetrics` + tests |
| 4 | partial | 2026-06-29 | SwiftData only; Auth/Firestore removed from app |
| 5 | partial | WIP | Tabs, onboarding, `ProductService`; no deep links |
| 6 | 2026-06-16 | WIP | Core catalog journey + stats/filter polish uncommitted |
| 7 | partial | WIP | `AdaptiveLayout`; app shell refresh uncommitted |
| 8 | partial | `ff261ee` | Settings + legal; no `AppLinks` enum |
| 9 | partial | WIP | List/detail/stats; tags/pick-next planned |
| 10 | — | — | English only |
| 11 | partial | — | Phase 1 a11y done; Phase 2 open |
| 12 | partial | `ff261ee` | Single CI scheme; no split UI targets |
| 13 | N/A | 2026-06-29 | Login removed — future: specs/planned/auth-cloud-sync.md |
| 14 | partial | 2026-06-29 | AppLog + Crashlytics; docs/telemetry.md |
| 15 | partial | — | GitHub Pages HTML; TestFlight informal |
| 16 | — | — | Pre-ship; large WIP on disk |
| 17+ | — | — | Roadmap only |

---

## Phase 0 — Repo & agent infrastructure

- [x] **0.1** Create repo; `README.md` = build/run entry (links to specs)
- [x] **0.2** **Project codegen:** XcodeGen `project.yml` — single source for targets, schemes, build phases
- [ ] **0.3** **Layered folders** (checklist layout):
  - [ ] `App/` — entry, DI bootstrap, root navigation
  - [ ] `Features/` — SwiftUI + MVVM per flow
  - [ ] `Domain/` — pure business logic (no SwiftUI)
  - [ ] `Data/` — repository protocols + implementations
  - [x] `Persistence/` — `PuzzleSchemaV1`, `PuzzleMigrationPlan`, `PuzzleModelContainer`
  - [x] `DesignSystem/` — *de facto* `Util/DesignTokens.swift`
  - [x] `Support/` — *de facto* `Util/` (logging, flags, layout)
  - [x] `Resources/` — assets, launch storyboard, plist templates
  - [x] `Tests/` — `AppTests/`, `AppUITests/`
  - *Current:* flat `Login/`, `Views/`, `Helpers/`, `Util/` — functional, not checklist layout
- [x] **0.4** Pin deployment target (iOS 18), bundle ID, team ID, Swift version in `project.yml`
- [x] **0.5** `.gitignore`: generated `.xcodeproj`, `GoogleService-Info.plist`, DerivedData
- [x] **0.6** **Git hooks** — `.githooks/pre-commit` blocks Firebase plist (`Scripts/install-git-hooks.sh`)
- [ ] **0.7** **`.cursor/mcp.json`** — XcodeBuildMCP documented in repo (`.cursor/` gitignored locally)
- [ ] **0.8** **Cursor rules** (`.cursor/rules/`) — accessibility, layout, migration policy
- [x] **0.9** **SwiftLint** + CI lint job (`.github/workflows/ci.yml`)
- [x] **0.10** **CONTRIBUTING.md** — architecture, style, test expectations
- [x] **0.11** Verify: `xcodegen generate && Scripts/ci/run-tests.sh` (CI on push/PR)

---

## Phase 1 — Spec system from brainstorm

- [x] **1.1** Brainstorm lives in non-authoritative docs — [roadmap.md](roadmap.md), user research in `docs/spec-garage-collector.md`
- [ ] **1.2** **System specs** in dedicated `specs/` folder:
  - [x] Architecture — [architecture.md](architecture.md)
  - [x] Tech stack — README + architecture
  - [x] Design system — `DesignTokens.swift` + architecture
  - [x] Data schema + migration policy — [swiftdata-migrations.md](swiftdata-migrations.md)
  - [x] Accessibility — [wcag.md](wcag.md), `accessibility/`
  - [ ] Localization policy — not written
  - [x] Test plan + CI — [testing.md](testing.md)
  - [x] Feature flags — `ProductService` in architecture
  - [ ] Spec governance doc — informal via CONTRIBUTING
- [x] **1.3** **Promotion pipeline** — [implementation-playbook.md](implementation-playbook.md) backlog IDs
- [ ] **1.4** Every feature spec ends with a **Verification** block — only in [feature-inventory.md](feature-inventory.md) today
- [x] **1.5** Index + inventory — this file + [feature-inventory.md](feature-inventory.md) (replaces `specs/README.md`)
- [ ] **1.6** Multi-variant catalog registry — N/A for v1

---

## Phase 2 — Design system & accessibility foundations

- [x] **2.1** **Token layers** — `Brand`, `DS` in `DesignTokens.swift`
- [x] **2.2** Semantic colors light + dark; contrast tracked in `accessibility/`
- [x] **2.3** **Dynamic Type** — semantic styles; `AdaptiveLayout` for stacked rows
- [ ] **2.4** **Touch targets** — 44×44 pt audit not complete
- [x] **2.5** Reusable components ship with `accessibilityLabel` / `A11yID` on key controls
- [x] **2.6** **WCAG tracker** — `accessibility/wcag-2.1-aa/conformance-matrix.md`
- [x] **2.7** Automated label contracts — `AccessibilityLabelTests`, `PuzzleAccessibilityUITests`
- [x] **2.8** Supported orientations documented — portrait + landscape phone/iPad in `project.yml`

---

## Phase 3 — Domain layer (test-first)

- [x] **3.1** Domain types — `CollectionStats`, `PuzzleListFilter`, `PuzzleDetailMetrics`, `PuzzleDateSemantics`
- [ ] **3.2** **Typed errors** at domain boundary — `ErrorHandling` at UI layer only
- [x] **3.3** **State machines** — `PuzzleStore` idle/fetching/done
- [x] **3.4** Deterministic services — stats, filter, metrics, serialization tests
- [x] **3.5** Unit tests per branch — `AppTests/` (13 files)
- [ ] **3.6** Property-style simulation — not implemented
- [ ] **3.7** **Command pattern** — not implemented
- *Gap:* `Puzzle` is `ObservableObject` in `Helpers/` — not strict Domain layer

---

## Phase 4 — Persistence & repositories

- [x] **4.1** Versioned schema — `PuzzleSchemaV1` + `PuzzleMigrationPlan` ([swiftdata-migrations.md](swiftdata-migrations.md)); add V2 when stored properties change
- [x] **4.2** **Repository** — `PuzzleStore` is concrete SwiftData store (no remote layer)
- [x] **4.3** **Dependency bootstrap** — `ModelContainer` + `@EnvironmentObject` at app root
- [x] **4.4** Migration plan baseline tests — `PuzzleMigrationPlanTests` (add Vn→V{n+1} disk test when introducing a stage)
- [x] **4.5** Bootstrap failure policy — Firebase skipped when plist placeholder; SwiftData always runs (wipe-on-unreadable last resort)
- [ ] **4.6** Features depend on `any FooRepository` — direct `PuzzleStore` usage

---

## Phase 5 — App shell & navigation

- [x] **5.1** `@main` app struct + dependency bootstrap (`PuzzleBuddyApp`)
- [x] **5.2** Root navigation — tabs: Puzzles, Stats, Settings (`PuzzleTabbar`)
- [ ] **5.3** **Router** for deep links — not implemented (no push)
- [x] **5.4** First-run **onboarding** (`OnboardingView`, UserDefaults flag)
- [x] **5.5** Central **feature flags** — `ProductService` (import/export, barcode, pick-next)
- [x] **5.6** **Release surface** — `ProductService` gates import/export; no login surface

---

## Phase 6 — First vertical slice (MVP core journey)

**Puzzle Buddy journey:** onboarding → add puzzle → list → detail → edit → persist → relaunch

- [x] **6.1** Entry screen + store (`PuzzleList`, `PuzzleStore`)
- [x] **6.2** Configuration step with validation (`PuzzleForm` — name required)
- [x] **6.3** Primary interaction UI — accessibility labels on key controls
- [x] **6.4** Domain wired through store (stats/filter in helpers, not in `View.body`)
- [x] **6.5** Completion / detail screen; SwiftData write
- [x] **6.6** Integration test — persistence tests + UI smoke
- [x] **6.7** UI test identifiers on critical controls (`A11yID`)

---

## Phase 7 — Shared chrome & adaptive layout

- [x] **7.1** Shared headers, error alerts (`ErrorHandling`), brand chrome
- [ ] **7.2** **Non-color state indicators** — partial (status pills WIP)
- [x] **7.3** Loading, disabled, destructive patterns — store fetching state, swipe delete
- [x] **7.4** **Orientation support** — `AdaptiveLayout`, compact vertical size class
- [ ] **7.5** iPad side-by-side predicates — layout exists; not unit-tested per checklist
- [x] **7.6** Secondary feature — Collection Stats tab proves architecture

---

## Phase 8 — Entity management & settings

- [x] **8.1** CRUD for puzzles — add, edit, delete with swipe
- [ ] **8.2** Identity presentation — N/A (no avatars)
- [x] **8.3** **Settings screen** — legal links, version, demo data, appearance
- [x] **8.4** Settings / store tests — persistence tests exist
- [ ] **8.5** **AppLinks** registry — URLs hardcoded in `SettingsView`
- [ ] **8.6** Tip/donate row — not applicable (nil = hidden pattern not wired)
- [ ] **8.7** **Delete all local data** — `Delete All Puzzles` in Settings (verify ship checklist)

---

## Phase 9 — Lists, history & derived views

- [x] **9.1** List + detail for persisted records
- [x] **9.2** Filters and search — status segments, name search, sort menu (WIP on disk)
- [x] **9.3** Aggregations — `CollectionStatsView` (WIP on disk)
- [ ] **9.4** Batch fetching — N/A at current scale
- [x] **9.5** Stats tab — keeps main tab count lean (3 tabs)

---

## Phase 10 — Localization & text coverage

- [ ] **10.1** String catalog wrapper (`L10n` or `String(localized:)`)
- [ ] **10.2** `en.lproj` source of truth
- [ ] **10.3** PR rule — all locales simultaneously
- [ ] **10.4** Parity test across `.lproj` files
- [ ] **10.5** Locale smoke UI tests
- [x] **10.6** **Lean ship** — English only for v1.0 (documented in inventory)
- [ ] **10.7** Translation sync scripts

---

## Phase 11 — Accessibility hardening (release gate)

- [x] **11.1** Automated audits — `PuzzleAccessibilityUITests` (`XCUIAccessibilityAudit`)
- [ ] **11.2** Manual **VoiceOver** pass on core journeys — scripts exist; dated audit incomplete
- [ ] **11.3** **Large text (AXXXL+)** — gaps logged in roadmap Phase 2
- [ ] **11.4** **Contrast evidence** — matrix Partial; evidence folder sparse
- [ ] **11.5** **Orientation matrix** — landscape tests exist; not full matrix doc
- [x] **11.6** **Reduce Motion** — brand background, splash
- [ ] **11.7** Hide decorative elements from VoiceOver — partial
- [x] **11.8** Accessibility statement link in Settings
- [ ] **11.9** Rollup doc — **no launch with open critical failures** — not signed off

---

## Phase 12 — Test matrix & CI

- [x] **12.1** PR CI — unit + UI tests on `Puzzle Buddy` scheme
- [ ] **12.2** **Split UI tests** into parallel targets by concern
- [ ] **12.3** Nightly full UI matrix
- [x] **12.4** **Launch arguments** — `UITestSupport`, `-ui_testing_bypass_onboarding`, seed puzzles
- [x] **12.5** Shared **test doubles** — preview fixtures, demo data seeding
- [ ] **12.6** Spec/code drift script in CI
- [x] **12.7** Block tracked secrets in CI — plist guard in workflow + pre-commit

---

## Phase 13 — Release surface & lean ship strategy

- [x] **13.1** Feature gate — `ProductService` (no auth/cloud flags)
- [ ] **13.2** One place controls tabs, deep links, locales, experimental features
- [x] **13.3** Dogfood launch args — `-enable_collection_import_export` only (not in App Store builds)
- [x] **13.4** Written **lean v1 plan** — README, roadmap, [feature-inventory.md](feature-inventory.md)
- [ ] **13.5** **Test-confidence matrix** — device QA evidence not documented
- [ ] **13.6** Branch model `dev` vs `release/*` — single-branch flow today
- [ ] **13.7** Per-feature release tags in specs — backlog IDs in playbook only

---

## Phase 14 — Telemetry, deep links & platform extensions

- [x] **14.1** Secrets template — `GoogleService-Info.plist.example`; real plist gitignored
- [x] **14.2** **Allowlisted analytics** — [analytics.md](analytics.md) + `AppLoggingTests`
- [x] **14.3** Crash reporting + dSYM upload — Crashlytics run script in `project.yml`
- [x] **14.4** Structured logging facade — `AppLog` → os.log + Firebase + Crashlytics
- [ ] **14.5** **Deep links** — parser, router, gated fallback
- [ ] **14.6** App Intents / Shortcuts
- [ ] **14.7** Widgets, Live Activities — roadmap only

---

## Phase 15 — Legal pages, GitHub Pages & store URLs

- [x] **15.1** Static HTML — `docs/privacy.html`, `support.html`, `accessibility.html`, `index.html`
- [x] **15.2** **GitHub Pages** from `/docs` — [docs/README.md](README.md)
- [ ] **15.3** Wire canonical URLs in `AppLinks` — inline in `SettingsView` today
- [ ] **15.4** App Store Connect URLs — owner action at submit
- [x] **15.5** "Last updated" on legal pages
- [ ] **15.6** App Store metadata spec — honest copy vs [feature-inventory.md](feature-inventory.md)
- [ ] **15.7** Marketing screenshots automation
- [x] **15.8** Launch screen — `LaunchScreen.storyboard` + asset catalog (WIP on disk)
- [ ] **15.9** CI/CD for TestFlight — Codemagic config present; not formalized

---

## Phase 16 — Release QA & ship

- [ ] **16.1** Device matrix scoped to v1.0 surface
- [ ] **16.2** RC sign-off doc with Go/No-Go
- [ ] **16.3** Owner decisions closed — see [feature-inventory.md](feature-inventory.md) v1.0 table
- [ ] **16.4** Lean-surface UI smoke green
- [ ] **16.5** Persistence recovery smoke on physical device
- [ ] **16.6** Pre-tag gate checklist (~10 min)
- [ ] **16.7** Post-submit monitoring plan

---

## Phase 17 — Expand surface (post-v1)

See [roadmap.md](roadmap.md) and [implementation-playbook.md](implementation-playbook.md) backlog. Next slices after 1.0:

1. Collection import/export (1.1)
2. Timer + richer metadata
3. Widget / year-in-review
4. Auth + cloud sync — future spec only ([auth-cloud-sync.md](../specs/planned/auth-cloud-sync.md))

---

## Phase 18 — Documentation hygiene (ongoing)

- [x] **18.1** Behavior docs — [features.md](features.md) maintained
- [x] **18.2** Feature inventory — [feature-inventory.md](feature-inventory.md)
- [ ] **18.3** Spec/code drift report in CI
- [ ] **18.4** Engineering audit after large refactors
- [ ] **18.5** Document extractions before splitting god types
- [ ] **18.6** Release automation runbooks

---

## Quick reference for agents

| Question | Where to look |
|----------|----------------|
| What should the product do? | [features.md](features.md), [roadmap.md](roadmap.md) |
| What exists in the build today? | [feature-inventory.md](feature-inventory.md) |
| How is code organized? | [architecture.md](architecture.md), [CONTRIBUTING.md](../CONTRIBUTING.md) |
| How do I build and test? | [README.md](../README.md), [development.md](development.md) |
| What ships this sprint? | [implementation-playbook.md](implementation-playbook.md) |
| Accessibility requirements? | [wcag.md](wcag.md), `accessibility/` |
| Lean vs full UI? | `ProductService` feature flags |
| Legal / support URLs? | `docs/*.html` → wire via `AppLinks` (TODO) |
| Ideas not yet spec'd? | [roadmap.md](roadmap.md) backlog |
| This checklist | `docs/agent-build-checklist.md` |

---

## Next actions (as of 2026-06-16)

1. **Commit WIP** — stats, filters, app shell, tests (see git status)
2. **Close a11y Phase 2** — form VO, contrast evidence (Phase 11 blocker)
3. **Add `AppLinks`** — centralize Settings URLs
4. **Device QA matrix** — document evidence for Phase 16
5. **TestFlight** — first RC after WIP lands
