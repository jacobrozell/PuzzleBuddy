# Puzzle redo & completion history

**Status:** Planned · **Target:** 1.0.0  
**Sprint:** [1.0.0-expanded-feature-sprint.md](../../docs/implementation/1.0.0-expanded-feature-sprint.md)  
**Competitor reference:** Puzzle Tracker re-do / multiple attempts (lighter model)

## Problem

Collectors often finish the same puzzle multiple times. Puzzle Buddy only tracks a single completion cycle. Users need a completion count and history without a heavy “attempts table” UI.

## Scope

### Data model

`PuzzleCompletionRecord` (SwiftData `@Model`):

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Unique |
| `puzzleID` | UUID | Parent puzzle |
| `completionNumber` | Int | 1-based, sequential |
| `startedAt` | Date? | From puzzle `startDate` at completion time |
| `completedAt` | Date | Required |
| `timeSpentHours` | Int? | Snapshot from puzzle at completion |
| `timeSpentMinutes` | Int? | |
| `rating` | Double? | Optional snapshot |

`PuzzleRecord.timesCompleted: Int` — denormalized count for list/stats.

### Behavior

1. **Transition to Completed** (from any non-completed status): append completion record; set `timesCompleted = completions.count`.
2. **First completion:** completion #1.
3. **Puzzle again** (detail action, completed only):
   - Confirm dialog
   - Status → In-Progress, progress → 0%, new `startDate`
   - Do **not** delete prior completions
4. **Detail UI:** “Completed N times” when N > 1; list past dates (newest first).

### Out of scope (1.0)

- Per-attempt photo galleries
- In-app timer per attempt (manual time snapshot only)
- Separate ratings per attempt editing after the fact (read-only list)
- Stats leaderboard / speed comparison across attempts

## UX copy

- Action: **Puzzle again**
- Confirm: “Start this puzzle again? Your previous completions stay in your history.”
- Accessibility: “Completed 3 times. Completion 2, January 12, 2026.”

## Telemetry (allowlist before ship)

| Event | When |
|-------|------|
| `puzzle_redo_started` | User confirms redo |
| `puzzle_completion_recorded` | New completion appended (metadata: `completion_number` only) |

## Tests

- Complete → redo → complete → `timesCompleted == 2`, two records
- Complete once → `timesCompleted == 1`
- JSON export includes completions array
- Pick-next still excludes wishlist; includes in-progress redo
