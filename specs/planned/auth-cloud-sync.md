# Auth + cloud sync (planned — not in app)

**Status:** Spec only · **Removed from codebase:** June 2026

Account sign-in and Firestore puzzle sync were implemented early in the project, then **removed** from the iOS app and Firebase Console. Puzzle Buddy 1.0 is **local-first only** (SwiftData).

This document captures intent for a possible future reimplementation. **Do not add Firebase Auth, Firestore, or FCM without an updated spec and explicit product approval.**

---

## Current product reality

| Topic | 1.0 behavior |
|-------|--------------|
| Persistence | SwiftData `PuzzleRecord` on device |
| Firebase | Analytics + Crashlytics only |
| Account | Not required |
| Multi-device sync | Not supported |

See [AGENTS.md](../../AGENTS.md) and [architecture.md](../../docs/architecture.md).

---

## If reimplementing (high-level requirements)

### Product

- Optional account — app must work fully offline without sign-in
- First sign-in: migrate local SwiftData puzzles to cloud (conflict UI TBD)
- Email/password + Sign in with Apple (prior art existed before removal)

### Firebase Console

- Re-enable Authentication providers
- Create Firestore database + security rules (email-scoped paths)
- Consider Cloud Storage for images (Firestore 1 MB doc limit)

### App architecture (sketch)

```
LoginView → PuzzleView(user:)
PuzzleStore dual-path: SwiftData + FirestorePuzzleRemoteStore
ProductService.isLoginEnabled (or Remote Config)
```

### Data model (historical)

```
users/{email}/
  username, currentVersion, lastLoggedIn
  puzzles/{puzzleUUID}/
    fields from Puzzle.getDataFields()
```

Rules pattern: `request.auth.token.email == userId`

### Telemetry

- Auth funnel events would need new Analytics allowlist entries
- No PII in Crashlytics (same rules as [telemetry.md](../../docs/telemetry.md))

### Testing

- Firebase Emulator for rules integration tests
- UI tests for login flow
- Local → cloud migration tests

---

## Related docs

- [roadmap.md](../../docs/roadmap.md) — release planning
- [FutureIdeas/backlog.md](../../FutureIdeas/backlog.md)
- Removed code is not in git history on `main` after June 2026 cleanup — recover from git history if needed for reference
