# WCAG 2.1 Level AA — Puzzle Buddy

This document is the developer-facing WCAG conformance guide for the Puzzle Buddy iOS app. It maps [WCAG 2.1](https://www.w3.org/TR/WCAG21/) Level AA success criteria to iOS implementation, current status, and verification steps.

**Related documents**

| Document | Audience |
|----------|----------|
| [accessibility.html](accessibility.html) | End users (GitHub Pages) |
| [../accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) | Engineering roadmap |
| [../accessibility/wcag-2.1-aa/conformance-matrix.md](../accessibility/wcag-2.1-aa/conformance-matrix.md) | Per-criterion status table |
| [testing.md](testing.md) | Automated and manual test procedures |

## Scope

| In scope | Out of scope |
|----------|--------------|
| Puzzle Buddy iOS app (SwiftUI) | Third-party Firebase Console |
| GitHub Pages legal/support HTML | App Store listing screenshots |
| iOS 17.0+ on iPhone and iPad | watchOS, macOS, web |

**Note:** Version 1.0 launches directly into the puzzle list (no sign-in). Login-screen WCAG coverage applies when `ProductService.isLoginEnabled` is true or when testing with `-enable_login`.

**Target conformance level:** WCAG 2.1 Level AA  
**Conformance status:** Partial — Phase 1 complete; Phase 2–3 in progress (see roadmap)

Apple's [Accessibility Programming Guide](https://developer.apple.com/documentation/accessibility) and Human Interface Guidelines complement WCAG for native apps. Where iOS provides platform-level support (Dynamic Type, VoiceOver, system contrast), this document notes how Puzzle Buddy relies on or extends that behavior.

---

## Principles overview

### 1. Perceivable

Information and UI components must be presentable to users in ways they can perceive.

#### 1.1 Text alternatives (1.1.1 Non-text Content)

**Requirement:** All non-text content has a text alternative that serves an equivalent purpose.

| Content | Implementation | Status |
|---------|----------------|--------|
| Puzzle photos | Decorative when supplementary; puzzle `name` is primary identifier in list/detail | Partial — image picker lacks explicit alt text field |
| Star rating icons | `Puzzle.Rating.accessibilityDescription` on list rows and `RatingsView` | Supports |
| Brand gradient background | Static when Reduce Motion is on (`BrandBackground`) | Supports |
| Tab bar icons | System tab items include text labels ("Puzzles", "Settings") | Supports |
| App icon | Platform-managed | Supports |

**Verification:** Enable VoiceOver → navigate puzzle list and form → confirm images do not block understanding of puzzle identity.

#### 1.2 Time-based media (1.2.x)

**Requirement:** Alternatives for audio/video; captions where applicable.

| Content | Status |
|---------|--------|
| Video/audio | Not used |

#### 1.3 Adaptable (1.3.1, 1.3.2, 1.3.3)

**Requirement:** Structure and relationships programmatically determinable; meaningful reading order; instructions not reliant on a single sense.

| Area | Implementation | Status |
|------|----------------|--------|
| Forms | SwiftUI `Form` + `Section` group related fields | Supports |
| Lists | `List` with identifiable rows | Supports |
| Headings | Navigation titles on each screen | Supports |
| Login flow | Top-to-bottom: email → password → actions | Supports |
| Color-only state | Status uses text labels ("To-Do", "Completed"), not color alone | Supports |

**Verification:** VoiceOver rotor → Headings; swipe through puzzle form in logical order.

#### 1.4 Distinguishable (1.4.1–1.4.13)

**Requirement:** Sufficient contrast, text resizing, reflow, and non-text contrast.

| Criterion | Puzzle Buddy approach | Status |
|-----------|----------------------|--------|
| **1.4.1 Use of Color** | Difficulty and rating supplemented by position/count; status is text | Supports |
| **1.4.3 Contrast (Minimum)** | `Brand` tokens designed for AA; accent `#C15C38` on white text | Partial — full audit pending |
| **1.4.4 Resize Text** | System Dynamic Type via SwiftUI text styles | Partial — layout audit at AX5 pending |
| **1.4.5 Images of Text** | No critical information in bitmap text | Supports |
| **1.4.10 Reflow** | Scroll views and `Form` for overflow | Partial |
| **1.4.11 Non-text Contrast** | Buttons, stars, difficulty chips vs background | Planned — Phase 2 |
| **1.4.12 Text Spacing** | System font spacing | Supports (platform) |
| **1.4.13 Content on Hover/Focus** | N/A (touch-first) | N/A |

**Design token reference** (`DesignTokens.swift`):

| Token | Light | Dark | Notes |
|-------|-------|------|-------|
| `Brand.accent` | Teal `rgb(13, 140, 158)` | Same | Primary actions; white label text |
| `Brand.textPrimary` | Near-black | White | Body and titles |
| `Brand.textSecondary` | Gray ~4.5:1 target on card | 62% white on dark card | Subtitles |
| `Brand.background` | Off-white | Near-black | Screen background |
| `Brand.card` | White | Dark gray | Elevated surfaces |

**Verification:** Settings → Accessibility → Display & Text Size → Largest; Xcode Accessibility Inspector contrast check on login and list screens.

---

### 2. Operable

UI components and navigation must be operable.

#### 2.1 Keyboard accessible (2.1.1, 2.1.2)

**Requirement:** All functionality available from a keyboard; no keyboard trap.

On iOS, **VoiceOver** and **Voice Control** are the primary alternatives to touch. External keyboards should focus standard `TextField` controls.

| Area | Status |
|------|--------|
| Text fields (login, puzzle name, pieces) | Supports — system keyboard |
| Custom star/difficulty pickers | Partial — may need accessibility actions |
| Tab navigation | Supports — tab bar |

**Verification:** Connect hardware keyboard; Tab through login fields. Voice Control: "Show names" and speak button labels.

#### 2.2 Enough time (2.2.1, 2.2.2)

**Requirement:** Users can extend or disable time limits; moving/blinking content can be paused.

| Feature | Status |
|---------|--------|
| Session timeout | None enforced in-app |
| Brand gradient / splash pulse | Supports — static or reduced when Reduce Motion enabled |

#### 2.3 Seizures (2.3.1)

**Requirement:** No content flashes more than three times per second.

Brand gradient and splash animations are low-frequency. No strobe content.

**Status:** Supports

#### 2.4 Navigable (2.4.1–2.4.7)

| Criterion | Implementation | Status |
|-----------|----------------|--------|
| **2.4.1 Bypass Blocks** | Tab bar provides direct section access | Supports |
| **2.4.2 Page Titled** | `.navigationTitle` on major screens | Supports |
| **2.4.3 Focus Order** | Matches visual order in forms and lists | Partial — audit puzzle form |
| **2.4.4 Link Purpose** | "Forgot password", Settings links have clear labels | Supports |
| **2.4.5 Multiple Ways** | Tab bar + list navigation to puzzles | Supports |
| **2.4.6 Headings and Labels** | Field labels + `accessibilityLabel` on login/settings | Partial |
| **2.4.7 Focus Visible** | iOS focus ring for external keyboard / Switch Control | Supports (platform) |

#### 2.5 Input modalities (2.5.1–2.5.4)

| Criterion | Status | Notes |
|-----------|--------|-------|
| **2.5.1 Pointer Gestures** | Supports | Tap-based; swipe-to-delete is standard list pattern with VoiceOver delete action |
| **2.5.2 Pointer Cancellation** | Supports | System button behavior |
| **2.5.3 Label in Name** | Supports | Visible "Log in" matches `accessibilityLabel` |
| **2.5.4 Motion Actuation** | Supports | No shake-to-activate features |

---

### 3. Understandable

Information and operation must be understandable.

#### 3.1 Readable (3.1.1, 3.1.2)

| Criterion | Status | Notes |
|-----------|--------|-------|
| **3.1.1 Language of Page** | Supports | `en` development language; `Puzzle-Buddy-Info.plist` / bundle English |
| **3.1.2 Language of Parts** | N/A | Single language UI |

Localization is planned (Phase 3).

#### 3.2 Predictable (3.2.1–3.2.4)

| Criterion | Implementation | Status |
|-----------|----------------|--------|
| **3.2.1 On Focus** | No context change on focus alone | Supports |
| **3.2.2 On Input** | Form fields do not auto-submit or navigate | Supports |
| **3.2.3 Consistent Navigation** | Tab bar persistent on main shell | Supports |
| **3.2.4 Consistent Identification** | `A11yID` constants reused across builds | Supports |

#### 3.3 Input assistance (3.3.1–3.3.4)

| Criterion | Implementation | Status |
|-----------|----------------|--------|
| **3.3.1 Error Identification** | `ErrorHandling` alerts with title + message | Supports |
| **3.3.2 Labels or Instructions** | Field labels in forms; login placeholders | Partial — puzzle form hints |
| **3.3.3 Error Suggestion** | Auth errors show localized Firebase messages | Partial |
| **3.3.4 Error Prevention** | Delete via swipe; no destructive one-tap on critical data | Supports |

**Verification:** Submit login with empty fields; confirm alert describes the problem.

---

### 4. Robust

Content must be robust enough for assistive technologies.

#### 4.1 Compatible (4.1.2, 4.1.3)

| Criterion | Implementation | Status |
|-----------|----------------|--------|
| **4.1.1 Parsing** | N/A (native UI, not HTML) | N/A |
| **4.1.2 Name, Role, Value** | `accessibilityLabel`, `accessibilityIdentifier`, system controls | Partial — custom rating/difficulty |
| **4.1.3 Status Messages** | Alerts for errors; list refresh not announced | Partial |

**`A11yID` contract** — see `DesignTokens.swift`. UI tests assert identifiers exist (`AccessibilityLabelTests`).

---

## Screen-by-screen conformance

### Login (`LoginView`)

| Control | Label | Identifier | Status |
|---------|-------|------------|--------|
| Email field | "Email" | `login_email_field` | Done |
| Password field | "Password" | `login_password_field` | Done |
| Log in button | "Log in" | `login_submit_button` | Done |
| Forgot password | "Forgot password" | `forgot_password_button` | Done |
| Sign in with Apple | System button | — | Platform |
| Brand background | Decorative | — | Reduce Motion OK |

### Puzzle list (`PuzzleList`)

| Control | Label | Identifier | Status |
|---------|-------|------------|--------|
| List | "Puzzle collection" | `puzzle_list` | Done |
| Add button | "Add puzzle" | `add_puzzle_button` | Done |
| Row cells | Name visible | — | Partial — row VO order |
| Swipe delete | System action | — | Platform |

### Puzzle form (`PuzzleForm`)

| Control | Label | Identifier | Status |
|---------|-------|------------|--------|
| Name, pieces, date, status | Visible text labels | — | Partial |
| Rating (`RatingsView`) | Star glyphs only | — | Planned |
| Difficulty (`DifficultyView`) | Visual chips | — | Planned |
| Image picker | Camera/photo | — | Planned |
| Submit | Visible button text | — | Partial |

### Settings (`SettingsView`)

| Control | Label | Identifier | Status |
|---------|-------|------------|--------|
| Sign out | "Sign out" | `settings_sign_out_button` | Done |
| Accessibility link | Link text | — | Done |

### Tab bar (`PuzzleTabbar`)

| Tab | Identifier | Status |
|-----|------------|--------|
| Puzzles | `puzzles_tab` | Done |
| Settings | `settings_tab` | Done |

---

## iOS assistive technology support

Puzzle Buddy is tested with these system features:

| Technology | Settings path | Priority |
|------------|---------------|----------|
| **VoiceOver** | Accessibility → VoiceOver | P0 |
| **Dynamic Type** | Display & Text Size → Larger Text | P0 |
| **Reduce Motion** | Accessibility → Motion → Reduce Motion | P0 |
| **Bold Text** | Display & Text Size → Bold Text | P1 |
| **Increase Contrast** | Accessibility → Display & Text Size | P1 |
| **Voice Control** | Accessibility → Voice Control | P1 |
| **Switch Control** | Accessibility → Switch Control | P2 |

### VoiceOver testing procedure

1. Enable VoiceOver (triple-click side button if configured, or Settings)
2. Login screen: verify all fields and buttons are reachable in logical order
3. Sign in → Puzzles tab: hear list label and add button
4. Open puzzle form: verify each field is announced
5. Settings → Sign out: confirm button label

### Dynamic Type testing procedure

1. Settings → Accessibility → Display & Text Size → Larger Text → enable **Larger Accessibility Sizes**
2. Drag slider to maximum
3. Open Puzzle Buddy → verify no clipped text on login, list rows, and form
4. Document issues in GitHub with screenshots

### Reduce Motion testing procedure

1. Enable Reduce Motion
2. Launch app → brand background and splash pulse should respect Reduce Motion

---

## Automated testing

### Unit tests

`AccessibilityLabelTests` validates `A11yID` contract constants.

### UI tests

`Puzzle_BuddyUITests` queries elements by `A11yID` on login screen.

### Planned: XCUIAccessibilityAudit

```swift
// Future — Puzzle BuddyUITests
func testLoginAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()
    try app.performAccessibilityAudit(for: .all) { issue in
        // Filter known false positives if needed
        return false
    }
}
```

Run audit targets: login, puzzle list, puzzle form, settings. See [testing.md](testing.md).

---

## GitHub Pages (supporting documentation)

Static pages under `/docs` support WCAG for web content:

| Page | Relevant criteria |
|------|-------------------|
| `index.html`, `privacy.html`, `support.html`, `accessibility.html` | 1.4.3 contrast, 1.4.4 resize, 2.4.2 titles, 3.1.1 language |
| `assets/style.css` | `prefers-color-scheme: dark`, system font stack, semantic HTML |

Web pages use semantic HTML, viewport meta, and CSS variables for light/dark. They are not yet formally audited to AA.

---

## Known gaps and remediation

| Gap | WCAG impact | Phase | Remediation |
|-----|-------------|-------|-------------|
| Puzzle form fields missing explicit VO labels | 1.3.1, 4.1.2 | 2 | Add `accessibilityLabel` / `accessibilityValue` |
| Star rating not announced as value | 4.1.2 | 2 | Done — `accessibilityDescription` on ratings |
| No localization | 3.1.1 (future locales) | 3 | `Localizable.strings` |
| Dynamic Type clipping on cells | 1.4.4 | 2 | Layout audit at AX5 |
| Full contrast audit incomplete | 1.4.3, 1.4.11 | 2 | Accessibility Inspector measurements |
| Status messages (sync complete) not announced | 4.1.3 | 2 | `AccessibilityNotification` on fetch |

Track progress in [accessibility_todo.md](../accessibility/accessibility_todo.md).

---

## Implementing accessibility in code

### Labels and identifiers

```swift
TextField("Email", text: $email)
    .accessibilityLabel("Email address")
    .optionalAccessibilityIdentifier(A11yID.loginEmailField)
```

### Custom control value

```swift
RatingsView(rating: $puzzle.rating)
    .accessibilityLabel("Rating")
    .accessibilityValue("\(puzzle.rating.rawValue) out of 5 stars")
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

if reduceMotion {
    Image("staticIllustration")
} else {
    AnimatedBrandBackground()
}
```

### Dynamic Type limits (when layout breaks)

```swift
.dynamicTypeSize(...DynamicTypeSize.accessibility3)  // only if AX5 breaks layout
```

Use sparingly — prefer fixing layout over capping type size.

---

## Evidence and audits

Manual conformance evidence will be stored in:

```
accessibility/wcag-2.1-aa/
├── conformance-matrix.md   # Criterion status
├── screenshots/            # Dynamic Type, contrast captures
└── voiceover-scripts/      # Expected VO reading order per screen
```

---

## Reporting and feedback

- **Users:** [Support page](https://jacobrozell.github.io/PuzzleBuddy/support.html)
- **Contributors:** Open a GitHub issue with `accessibility` label; reference WCAG criterion number (e.g. 1.4.3)

Include iOS version, assistive technology enabled, and steps to reproduce.

---

## References

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/?versions=2.1&levels=aa)
- [Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [UIView accessibility APIs](https://developer.apple.com/documentation/uikit/uiaccessibility)
- [SwiftUI accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Perform accessibility audits in XCUI tests](https://developer.apple.com/documentation/xctest/performing-accessibility-audits-in-your-tests)
