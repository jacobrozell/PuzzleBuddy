# SwiftData schema & migrations

**Last updated:** 2026-10-28 · **Agent entry:** [AGENTS.md](../AGENTS.md)

Authoritative policy for on-device persistence versioning. Follow this **before** changing any `@Model` stored property.

---

## Current state (shipped 1.0.0 / branch 1.1.0+)

| Item | Value |
|------|--------|
| Live schema | `PuzzleSchemaV3` @ `Schema.Version(1, 2, 0)` (`release/1.1.0`) |
| Frozen | `PuzzleSchemaV1` @ `1.0.0` and `PuzzleSchemaV2` @ `1.1.0` — **nested** model copies (do not edit) |
| Migration plan | `PuzzleMigrationPlan` — lightweight V1→V2, lightweight V2→V3 |
| Container | `PuzzleModelContainer` (versioned + plan on disk; unversioned 1.0.0 stores are copied to the current schema; wipe is last resort) |
| Models (V3) | `FriendRecord`, `PuzzleRecord`, `PuzzlePhotoRecord`, `PuzzleCompletionRecord` |
| Git contract | Tag `1.0.0` freezes V1; 1.1.0 freezes V2 (On loan). The 1.1.0 stopwatch build ships V3. Do not edit V3 after that upload. Timer sessions are the next schema version — [1.2.0-timer-redesign.md](implementation/1.2.0-timer-redesign.md). |

**1.1.0 completion history** did not change stored properties. **On loan / Friends** is the first real store shape change (V2). **In-app timer** (1.2.0) adds `timerAccumulatedSeconds: Int = 0` and `timerRunningSince: Date?` on `PuzzleRecord` (V3).

`PuzzleMigrationPlanTests` pins the 1.1.0 entity version hashes for nested V2 and opens an on-disk V2 store as V3.

---

## Files

| Path | Role |
|------|------|
| [`App/Persistence/PuzzleSchemaV1.swift`](../App/Persistence/PuzzleSchemaV1.swift) | Nested frozen models for App Store 1.0.0 fingerprint |
| [`App/Persistence/PuzzleSchemaV2.swift`](../App/Persistence/PuzzleSchemaV2.swift) | Nested frozen models for the 1.1.0 fingerprint |
| [`App/Persistence/PuzzleSchemaV3.swift`](../App/Persistence/PuzzleSchemaV3.swift) | Live top-level `@Model` types (timer fields) |
| [`App/Persistence/PuzzleMigrationPlan.swift`](../App/Persistence/PuzzleMigrationPlan.swift) | `schemas` + lightweight V1→V2→V3 |
| [`App/Helpers/PuzzleModelContainer.swift`](../App/Helpers/PuzzleModelContainer.swift) | Opens store; wipe-on-unreadable is last resort |
| [`AppTests/PuzzleMigrationPlanTests.swift`](../AppTests/PuzzleMigrationPlanTests.swift) | Schema / plan lock tests |
| [`docs/implementation/on-loan-friends.md`](implementation/on-loan-friends.md) | On loan feature note |

Domain helpers (`PuzzleRecord.swift`, `FriendRecord.swift`, etc.) stay top-level for app code. **V1 and V2 must keep nested copies** so the 1.0.0 checksum stays stable (Dart Buddy pattern). Editing top-level `@Model` classes after freeze requires a **new** schema version — never mutate nested V1 types.

---

## Rules for agents

1. **Never edit nested models inside `PuzzleSchemaV1` or `PuzzleSchemaV2`** (causes `134504 unknown model version`).
2. Helpers without new keys are OK — e.g. `PuzzleCompletionRecord.apply(from:)` does not need a schema bump.
3. **New / removed / renamed stored properties → new schema version** before shipping.
4. **Do not add a schema version identical to the previous** — SwiftData rejects duplicate version checksums.
5. Keep wipe-on-open-failure in `PuzzleModelContainer` as **recovery only**; migrations exist so upgrades should not hit it for additive changes.
6. After adding files under `App/Persistence/`, run `xcodegen generate`.
7. Unit-test `ModelContainer` setups that construct schemas manually must include **`FriendRecord.self`**.

---

## How to add a schema version (post–V3)

1. Identify the change vs current latest schema.
2. Freeze the current live schema as nested copies (as V2 was for V3), then add `PuzzleSchemaV4` listing the live models.
3. Update `PuzzleMigrationPlan` with an adjacent lightweight/custom stage.
4. Update domain models + JSON export/import.
5. Extend `PuzzleMigrationPlanTests`; prefer a disk Vn→Vn+1 open test.
6. Update this file, AGENTS, architecture.

### Lightweight vs custom

| Change | Prefer |
|--------|--------|
| New optional property / new defaulted property | `.lightweight` |
| New entity type | `.lightweight` (often) |
| Rename, non-optional without default, data backfill | `.custom` |
| Delete property users still need | Avoid or custom export/transform |

---

## What does *not* need a schema bump

- Methods on `@Model` classes (`apply`, `toPuzzle`, …)
- `Puzzle` (domain) fields that are not persisted (e.g. `loanedToDisplayName`)
- Enum raw-value string expansions that still fit existing `String` columns
- UI-only / Settings / analytics changes
- In-memory test containers (prefer `PuzzleModelContainer.makeInMemory()`)

---

## Failure policy

If the store cannot open even with the migration plan:

1. Log `model_container_load_failed`
2. Attempt recreate empty store → `model_container_store_reset` (Crashlytics non-fatal **2006**) + user banner via `UserPreferences.markStoreWasReset()`
3. Else ephemeral in-memory → `model_container_ephemeral_fallback`

That path **deletes user data**. Migrations exist to keep upgrades off this path.

---

## Related

- [architecture.md](architecture.md) — persistence overview
- [implementation/on-loan-friends.md](implementation/on-loan-friends.md) — first V2 feature
- [implementation/1.1.0-completion-history.md](implementation/1.1.0-completion-history.md) — explicitly no schema change
- Dart Buddy reference: `DartBuddy/Persistence/` + `.cursor/rules/swiftdata-schema-releases.mdc`
