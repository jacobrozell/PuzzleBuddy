# Reviewer-Readiness Handoff — Puzzle Buddy

Handoff for continuing **App Store reviewer-readiness** through first submit. Pairs with [`docs/release/todo.md`](../docs/release/todo.md) and [`docs/release/app-store-connect.md`](../docs/release/app-store-connect.md).

> Last updated: 2026-06-22 · Stage: Pre-ship polish (1.0.0 build 1)

---

## Completed (2026-06-22)

- **Branding** — Onboarding uses `AppInfo.displayName` (Puzzle Buddy); removed stale `Config.appName` (Puzzle Pal).
- **Photo library permission** — `NSPhotoLibraryUsageDescription` in `project.yml` (required for Choose photo).
- **Push gating** — No notification prompt on 1.0 launch; push registration only when `isLoginEnabled`.
- **GitHub Pages copy** — `docs/index.html` and `docs/support.html` describe local-first 1.0 (no false sign-in/sync claims).
- **Onboarding flash fix** — `RootView` skips onboarding immediately when already complete (fixes UI test flake + returning-user flash).
- **App Store Connect doc** — [`docs/release/app-store-connect.md`](../docs/release/app-store-connect.md) (privacy label table, review notes).
- **Unit tests** — 158 tests passing.

---

## Remaining (human / Connect-side)

1. **Commit + push** review fixes on `main` (uncommitted as of handoff).
2. **Publish GitHub Pages** — push `docs/` so live support/index match repo.
3. **App Store Connect** — create app, privacy label, age rating, export compliance per connect doc.
4. **Marketing screenshots** — iPhone + iPad, local-first pitch.
5. **Device smoke** — add puzzle → detail → export CSV on physical device.
6. **VoiceOver manual pass** — form + detail ([`accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md) Phase 2).
7. **IPDb large CSV** — import smoke on device.
8. **First TestFlight / App Review upload** — archive from Xcode, team `7JT2JB89AV`.

---

## Environment setup

```bash
cd ~/Desktop/personal/Puzzle-Buddy
xcodegen generate
open "Puzzle Buddy.xcodeproj"
```

XcodeBuildMCP defaults:

- projectPath: `Puzzle-Buddy/Puzzle Buddy.xcodeproj`
- scheme: `Puzzle Buddy`
- bundleId: `com.jacobrozell.Puzzle-Buddy`
- simulator: iPhone 17 (UDID `22114A58-1110-4FC7-8431-F7B84B6C7465`)

```bash
xcodebuild test -project "Puzzle Buddy.xcodeproj" -scheme "Puzzle Buddy" \
  -destination 'platform=iOS Simulator,id=22114A58-1110-4FC7-8431-F7B84B6C7465' \
  -only-testing:"Puzzle BuddyUITests/PuzzleAccessibilityUITests"
```

Fresh-install UI test: uninstall `com.jacobrozell.Puzzle-Buddy` on sim before audit runs.

---

## Acceptance criteria

- Fresh install: onboarding once, then main tabs; **no push prompt**; no login surfaces.
- Core loop: add puzzle (photo + manual), list filters, detail, stats, export JSON/CSV.
- In-app privacy claims match hosted policy + Connect nutrition label.
- Support, Privacy, Accessibility URLs return HTTP 200.
- Unit + UI accessibility tests green on iPhone 17 sim.

## Key references

- [`docs/release/todo.md`](../docs/release/todo.md)
- [`docs/release/app-store-connect.md`](../docs/release/app-store-connect.md)
- [`docs/roadmap.md`](../docs/roadmap.md)
- [`docs/features.md`](../docs/features.md)
