# Puzzle Buddy — release todo

Status legend: `[ ]` todo · `[x]` done

Strategy: [`../roadmap.md`](../roadmap.md) · Shipped scope: [`../features.md`](../features.md)

## 1.0.0 App Store

- [x] **`isLoginEnabled = false`** — verified in Release (no login surfaces)
- [x] **GitHub Pages** — privacy + support URLs live (support/index copy aligned with 1.0 local-first)
- [ ] **Marketing screenshots** — local-first catalog, no account pitch
- [ ] **Device smoke** — add puzzle → collection → detail → export CSV
- [ ] **WCAG core journey** — VoiceOver manual audit ([`../accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md))
- [ ] **App Store Connect** — see [`app-store-connect.md`](app-store-connect.md) (age rating, export compliance, privacy labels)

## Pre-submit

- [ ] **IPDb import smoke** — large CSV on device
- [x] **UPC lookup** — network failure graceful (user-facing notices + unit tests)
- [ ] **Landscape + iPad** — Phase 2 layout plan sign-off (UI landscape tests in suite)
- [x] **Onboarding / permissions** — no push on 1.0 launch; photo library usage string; branding aligned
- [x] **Simulator smoke** — app builds and launches on iPhone 17 sim (XcodeBuildMCP)
