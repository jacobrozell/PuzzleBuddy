# iPhone Duo readiness (1.1.0)

**Goal:** Ship 1.1.0 Duo-ready: size-class layout, full-display chrome, Connect Duo screenshots (product-page Duo badge).  
**Branch:** `release/1.1.0`  
**Build:** Xcode **27.1** / iOS **27.1 SDK** (deployment target stays **iOS 18**).

**Last updated:** 2026-10-27

**Automated verification (2026-10-27):** `AdaptiveLayoutTests` 8/8 · `testPuzzleDetailEditSurvivesRotation` + `testAddPuzzleFormLandscapeLayout` on iPhone 17 · **Debug build + launch on iPhone Duo simulator** (Xcode 27.1). Closed pose (0°): outer list, status filter, FAB, tab bar (`snapshot_ui` on Duo UDID).

**Fold presentation (2026-10-27):** One `NavigationSplitView` for every width, inside a `.sidebarAdaptable` tab. Selection, the edit draft, and long-form sheets live on `PuzzleBrowseState` above that tab, so a size-class rebuild keeps the open puzzle. Device Hub Open → Edit or Add → Closed is still a manual check.

---

## Layout decisions

| Signal | Behavior |
|--------|----------|
| Regular width **and** regular height | Sidebar tabs and list + detail split (iPad, iPhone Duo inner display, a tall resizable window). |
| Regular width **and** compact height | Phone stack. iPhone Pro Max landscape stays on the tab bar and pushes detail. |
| `verticalSizeClass == .compact` | Short-height chrome: compact filter header, landscape-style scroll insets |
| Removed | `userInterfaceIdiom`, `interfaceOrientation` / `isLandscapeInterface` for chrome |

**Code:** [`App/Util/AdaptiveLayout.swift`](../App/Util/AdaptiveLayout.swift) · **Tests:** [`AppTests/AdaptiveLayoutTests.swift`](../AppTests/AdaptiveLayoutTests.swift)

**Top-edge fill (2026-10-27):** Duo puts the status bar on the trailing edge, so a default white window/nav strip showed above the title. Brand chrome now ignores the **top** safe area, `UIWindow` matches `Brand.background`, and iOS 26+ skips opaque `.toolbarBackground` (Liquid Glass). [`App/Util/SystemNavigationPolicy.swift`](../App/Util/SystemNavigationPolicy.swift)

**Connect screenshots (2026-10-27):** Outer **1398×2034** + inner **2007×2853** via [`../Scripts/capture-duo-marketing-screenshots.sh`](../Scripts/capture-duo-marketing-screenshots.sh) → [`../marketing-screenshots/iphone-duo/`](../marketing-screenshots/iphone-duo/). Paste-ready listing copy: [`../docs/release/1.1.0-connect-paste.md`](../docs/release/1.1.0-connect-paste.md).

**Out of scope:** ReservedRegion / pose APIs, cover-only UI, multi-scene, landscape Duo slots (optional).

---

## Smoke checklist (iPhone Duo simulator)

Status legend: `[ ]` todo · `[x]` done

### Outer display (folded)

- [x] Collection list loads; status filter + search usable *(2026-10-27 — closed pose, seeded launch, Duo `snapshot_ui`)*
- [ ] FAB add puzzle; add/edit sheet dismisses cleanly
- [ ] Push to puzzle detail; back navigation
- [ ] Stats tab grid readable

### Inner display (open)

- [x] App launches; collection chrome renders (Duo sim smoke)
- [ ] Regular-width chrome when inner reports regular horizontal **and** regular vertical *(manual — confirm toolbar vs FAB)*
- [ ] List → detail; completion history section
- [ ] Long-form add puzzle uses page-sized sheet
- [ ] Stats adaptive grid uses regular-width columns

### Fold / unfold mid-session

- [ ] From list, fold/unfold — no clipped primary controls *(manual — Device Hub Closed ↔ Open)*
- [ ] From pushed detail or inline **Edit**, fold/unfold — **same screen stays up** with unsaved text *(manual — was dismissing before nav-stack fix; verify Open → Edit → Closed)*
- [ ] From Add Puzzle (or other long-form sheet), fold/unfold — **sheet stays up** with draft *(manual — Open → Add Puzzle → Closed)*

### Compact-height poses

- [x] Compact filter header path (`Search and filters` button + status segments at 874×402)
- [ ] Last list row clears FAB/tab bar with seeded data
- [ ] Onboarding scroll at compact height (if easy to reach)

### Optional

- [ ] Barcode scanner once per display (camera permission)

---

## References

- [Prepare your app for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [Three steps to make your app shine on iPhone Duo](https://developer.apple.com/news/?id=kkphp5qo) — iOS 27.1 SDK for full-display + vertical bars
