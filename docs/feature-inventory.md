# Feature inventory — Puzzle Buddy

**What exists in the build today** (reality register). For behavior detail see [features.md](features.md). For future work see [roadmap.md](roadmap.md). For ship gates see [agent-build-checklist.md](agent-build-checklist.md).

**Last updated:** 2026-06-16  
**Target v1.0 scope:** Local-first catalog — no account required. Login/cloud sync built but gated off.

---

## Shipped (reachable in default 1.0 build)

| Area | Feature | Code paths | Notes |
|------|---------|------------|-------|
| Launch | Splash → onboarding or main | `SplashView`, `RootView`, `OnboardingView` | Onboarding skipped in UI tests |
| Catalog | Add / edit / delete puzzle | `PuzzleForm`, `PuzzleStore`, `PuzzleRecord` | SwiftData persistence |
| Catalog | List + detail + photo | `PuzzleList`, `PuzzleDetail`, `PuzzleCell` | |
| Catalog | Status filter, search, sort | `PuzzleList`, `PuzzleListFilter` | WIP on disk — not in `ff261ee` |
| Catalog | In-Progress status | `Puzzle.Status`, form/detail/list | WIP on disk |
| Catalog | Half-star ratings on form + list | `RatingsView`, `PuzzleForm`, `PuzzleCell` | WIP on disk |
| Stats | Collection stats tab | `CollectionStatsView`, `CollectionStats` | WIP on disk |
| Stats | Per-puzzle pace metrics on detail | `PuzzleDetailMetrics`, `PuzzleDetail` | WIP on disk |
| Settings | Legal links (privacy, support, a11y) | `SettingsView` | GitHub Pages URLs |
| Settings | App version | `SettingsView`, `Puzzle_BuddyApp.version` | |
| Observability | Allowlisted Analytics + Crashlytics | `AppLog`, `AppDelegate` | No PII |
| Observability | Firebase bootstrap guard | `FirebaseBootstrap` | CI uses example plist |
| Design | Brand tokens, adaptive layout | `DesignTokens`, `AdaptiveLayout` | |
| A11y | Phase 1 — labels, IDs, Reduce Motion | `A11yID`, `PuzzleAccessibilityUITests` | Phase 2 open |

---

## Partial (implemented, gated or incomplete)

| Area | Feature | Gate / gap | Code paths |
|------|---------|------------|------------|
| Auth | Email/password, Apple, forgot password | `ProductService.isLoginEnabled` = `false`; `-enable_login` for dogfood | `Login/`, `FirebaseAuthProvider` |
| Sync | Firestore puzzle CRUD | `ProductService.isCloudSyncEnabled` | `PuzzleStore`, `PuzzleRemoteStore` |
| Auth | Profile / change username | Not in main tab IA | `ProfileView`, `ChangeUsernameView` |
| Auth | Local → cloud migration on first sign-in | Not implemented | — |
| Settings | Sign out | Only when login enabled | `SettingsView` |
| A11y | Form rating/difficulty VO, contrast evidence | Phase 2 roadmap | `RatingsView`, `DifficultyView` |
| Release | Lean surface gate | Login only; no `ReleaseSurface` module | `ProductService` |
| Legal | Centralized `AppLinks` | URLs inline in `SettingsView` | — |

---

## Planned (spec'd, not built)

| Area | Feature | Spec |
|------|---------|------|
| Organize | Custom tags + filter chips | [roadmap.md — find & organize](roadmap.md#find--organize--user-driven-product-strategy) |
| Organize | Pick my next puzzle | [implementation-playbook.md](implementation-playbook.md) `pick-next` |
| Tracking | Notes, brand, start date, timer | [roadmap.md — model extensions](roadmap.md#puzzle-model-extensions) |
| Tracking | Barcode scan | `barcode` field (commented) |
| Status | Wishlist, Abandoned | [roadmap.md — status extension](roadmap.md#status-enum-extension) |
| Delight | Widget, milestones, year-in-review | [roadmap.md — Phase D](roadmap.md#phase-d--delight-optional-higher-effort) |
| Platform | Deep links, App Intents | [agent-build-checklist.md](agent-build-checklist.md) Phase 14 |
| i18n | Localization | [roadmap.md — accessibility Phase 3](roadmap.md#phase-3--polish) |

---

## Stub (code present, not product-ready)

| Item | Location | Notes |
|------|----------|-------|
| `createAccountWithApple` | `FirebaseAuthProvider` | Commented / stubbed |
| Push notification use cases | `AppDelegate` | FCM wired, unused |
| Remote Config flags | — | Static `ProductService` today |
| Delete all local data | — | Not spec'd |

---

## v1.0 release surface (owner decisions)

| Decision | v1.0 choice |
|----------|-------------|
| Account required | **No** — local SwiftData only |
| Login / cloud sync | **Off** (`isLoginEnabled = false`) |
| Telemetry | Analytics + Crashlytics when Firebase configured |
| Locales | English only |
| Tip / donate link | None (`AppLinks.tipJar` not implemented) |
| Min iOS | 17.0 |
| Bundle ID | `com.jacobrozell.Puzzle-Buddy` |

---

## Verification

| Release | Last verified | Commit | Primary paths |
|---------|---------------|--------|---------------|
| 1.0 (local catalog) | 2026-06-16 | `ff261ee` (+ WIP) | `PuzzleStore`, `PuzzleList`, `PuzzleForm`, `PuzzleDetail` |
| 1.x (login + sync) | — | — | `Login/`, `PuzzleStore` cloud path |

Update this table when a release slice is device-verified and tagged.
