# In-app puzzle timer

**Target:** ships in **1.1.0** as this stopwatch (`release/1.1.0`, schema V3).  
**Next:** session redesign — [1.2.0-timer-redesign.md](../../docs/implementation/1.2.0-timer-redesign.md). Do not change this 1.1 behavior while that plan is future work.  
**Competitor gap:** Puzzle Tracker core feature  
**Last updated:** 2026-10-28

## Behavior

The timer exists only while status is **In-Progress**. It is a stopwatch for the current attempt, not a replacement for the form's "How long did it take?" fields.

- **Start** sets `timerRunningSince` to now. **Pause** adds `now - timerRunningSince` into `timerAccumulatedSeconds` and clears the anchor. **Reset** (confirmation dialog) zeroes both and does not touch logged time.
- Elapsed = `accumulated + (now - runningSince)` when running, else `accumulated`. The UI ticks with a `TimelineView`; the store does not.
- Keeps running across background, lock, and quit. No pause on `scenePhase`.
- Clock moved backward (`now < timerRunningSince`): the open segment is dropped and the timer pauses (on next store load or command). Never negative.
- **One running timer.** Starting puzzle B pauses puzzle A; A keeps its accumulated seconds.
- Leaving In-Progress (To-Do, Wishlist, Abandoned, Completed) pauses first. Accumulated seconds stay on the record.
- **Redo** (`startRedo`) zeroes both timer fields.
- **Undo completion** only reverts status and progress. The paused timer and any prefilled logged time stay.

### Logged time vs timer

`estimatedTimeSpent` stays the value stats, pace, completion history, and collage read. On the save that first transitions to Completed, before the completion row is appended:

- Timer total > 0 **and** hours and minutes both empty → write the rounded timer time.
- User already entered hours or minutes → keep them.

Rounding (`PuzzleTimerSemantics.roundedMinutes`): nearest minute; any positive total under 30 seconds logs as 1 minute; zero stays empty.

The edit form shows "Timer recorded 2 hr 14 min" with a **Use timer time** button when the rounded timer total differs from the entered time.

## Persistence

`PuzzleRecord.timerAccumulatedSeconds: Int = 0` and `timerRunningSince: Date?` in `PuzzleSchemaV3` (lightweight V2→V3). Same fields on `Puzzle`, `copy()`, and the JSON backup (optional keys; missing → 0 / nil). See [swiftdata-migrations.md](../../docs/swiftdata-migrations.md).

## UI

- `PuzzleTimerCard` on In-Progress detail (not in edit mode), above the details group. Monospaced `H:MM:SS`, one Start/Pause button (44pt+, VoiceOver value = spoken duration + running/paused), secondary **Reset timer** with confirmation. No pulse animation.
- List row: "Timer running" label on the running puzzle only.
- Same card on iPhone, iPad, and Duo.

## Analytics

`puzzle_timer_started`, `puzzle_timer_paused` (`reason`: `pause`, `reset`, `other_started`, `status_left`; `duration_bucket`: `under_15m`, `15m_1h`, `1h_3h`, `over_3h`). No names, no raw seconds. See [telemetry.md](../../docs/telemetry.md).

## Non-goals (later)

Owned by [1.2.0-timer-redesign.md](../../docs/implementation/1.2.0-timer-redesign.md). Read the **Owner decisions** there before implementing.

- Sessions, Focus mode, forgot-to-pause, pace/ETA — next version, new schema after V3
- Live Activity / lock-screen timer, Shortcuts, and a tab-bar mini-bar — later than that
- Pausing when the app backgrounds
- Changing how collection stats sum `estimatedTimeSpent`
