# On loan + local Friends foundation

**Status:** Implemented on `release/1.1.0` · **Last updated:** 2026-09-21

## What shipped

- Temporary **On loan** tracking on puzzles (orthogonal to status and disposition)
- Local **`Friend` / `FriendRecord`** with silent find-or-create from the loan name field
- SwiftData **`PuzzleSchemaV2`** + lightweight V1→V2 migration
- List filter, cell badge, stats card, Mark returned
- JSON backup `friends[]` + loan fields
- **`FriendsListView`** exists but is **hidden** (`ProductService.isFriendsListEnabled = false`)

## Model

| Field | Layer | Notes |
|-------|--------|-------|
| `isOnLoan` | Puzzle / PuzzleRecord | Filter + badge |
| `loanedToFriendID` | Puzzle / PuzzleRecord | UUID FK (no `@Relationship`) |
| `loanedToDisplayName` | Puzzle only | Draft / resolved name |
| `loanedAt` | both | Set when turning on |
| `dueBackDate` | both | Optional |
| `lastLoanNudgeAt` | both | Reserved for future poke |
| Friend `remoteId` | FriendRecord | Reserved for Firestore |

## Rules

- Gifted / Sold / Donated / Trashed clears loan
- Mark returned clears loan fields; Friend row kept
- Delete All Data removes puzzles **and** friends (`FriendRecord`)
- Demo friends use `isDemo`; removed with demo puzzles
- Never put borrower names in Analytics

## Schema

- `PuzzleSchemaV1` — nested frozen models (pre–On-loan fingerprint)
- `PuzzleSchemaV2` — live top-level models + `FriendRecord`
- In-memory tests use non-versioned `Schema([...])`; disk opens use versioned schema + migration plan

## Future

- Enable Friends / People list UI (`isFriendsListEnabled`)
- Auth / Firestore sync of friends
- Push + loan poke ([FutureIdeas/backlog.md](../../FutureIdeas/backlog.md))
