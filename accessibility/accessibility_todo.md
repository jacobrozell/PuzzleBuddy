# Accessibility — Puzzle Buddy

Phased plan toward **WCAG 2.1 Level AA** on iOS, aligned with [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy) practices.

**Documentation**

| Document | Purpose |
|----------|---------|
| [docs/wcag.md](../docs/wcag.md) | Full WCAG 2.1 AA conformance guide |
| [wcag-2.1-aa/conformance-matrix.md](wcag-2.1-aa/conformance-matrix.md) | Per-criterion status table |
| [wcag-2.1-aa/voiceover-scripts/](wcag-2.1-aa/voiceover-scripts/) | VoiceOver audit scripts |
| [docs/accessibility.html](../docs/accessibility.html) | Public statement (GitHub Pages) |

## Standards reference

| Guideline | iOS implementation |
|-----------|-------------------|
| Perceivable | VoiceOver labels, sufficient contrast, Dynamic Type |
| Operable | Touch targets, Reduce Motion, keyboard (where applicable) |
| Understandable | Clear labels, error messages via `ErrorHandling` |
| Robust | `accessibilityIdentifier` for UI tests, semantic controls |

Apple HIG: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

## Current implementation

### VoiceOver

- Puzzle list, add puzzle, settings, and tab bar use labels and system semantics
- Onboarding screens use standard SwiftUI control semantics

### Identifiers (`A11yID`)

Centralized in `DesignTokens.swift`:

| Constant | Element |
|----------|---------|
| `puzzleList` | Main puzzle list |
| `addPuzzleButton` | Add puzzle FAB/button |
| `puzzlesTab` | Puzzles tab |
| `settingsTab` | Settings tab |

Apply via `.optionalAccessibilityIdentifier(A11yID.*)` or `.accessibilityIdentifier`.

### Reduce Motion

- `BrandBackground` shows a flat `Brand.background` when `@Environment(\.accessibilityReduceMotion)` is true instead of the animated gradient

### Contrast

- `Brand.accent` is documented as WCAG AA on white text at 4.5:1+ in `DesignTokens.swift`
- Secondary text uses `Brand.textSecondary` with reduced opacity in dark mode

## Phase 1 — Done

- [x] VoiceOver labels on puzzle list, settings, and primary actions
- [x] Accessibility identifiers for UI tests (`A11yID`)
- [x] Reduce Motion support for brand gradient background
- [x] GitHub Pages accessibility statement

## Phase 2 — Next

### VoiceOver audit

- [ ] Puzzle form: name, pieces, rating, difficulty, date, status, photo picker
- [ ] Puzzle detail: read all fields in logical order
- [ ] Ratings and difficulty controls: announce current value on change
- [ ] Delete confirmation: accessible action names

### Dynamic Type

- [ ] Audit `PuzzleCell` at largest accessibility sizes — no clipping
- [ ] Form fields and buttons scale with `.dynamicTypeSize` limits where needed
- [ ] Tab bar and navigation titles remain readable

### Contrast verification

- [ ] Verify `Brand.accent` on `Brand.card` (not only on white text)
- [ ] Star rating inactive states vs background
- [ ] Placeholder and secondary label contrast

### Automated audits

- [x] Add `XCUIAccessibilityAudit` UI test suite in `Puzzle BuddyUITests`
- [x] Run audit on onboarding and puzzle list (seeded fixtures)
- [x] Run audit on settings and add-puzzle form
- [x] Landscape layout checks for puzzle list and detail

## Phase 3 — Polish

- [ ] Localization (`Localizable.strings`) — all user-facing strings
- [ ] Manual evidence folder under `accessibility/wcag-2.1-aa/` (screenshots, VoiceOver recordings)
- [ ] Voice Control label audit
- [ ] Bold Text and Increase Contrast system setting checks

## Developer checklist (new UI)

When adding or changing a screen:

1. Every interactive control has an `accessibilityLabel` (or visible text that VoiceOver reads)
2. Custom controls expose value/hint where the default is unclear
3. Add `A11yID` for elements UI tests need to tap
4. Test with VoiceOver on device or Simulator (Settings → Accessibility → VoiceOver)
5. Test with **Largest** Dynamic Type (Settings → Accessibility → Display & Text Size)
6. Respect Reduce Motion for non-essential animation
7. Update this file if completing a phase item

## Testing accessibility

```bash
# Run label unit tests
xcodebuild test-without-building \
  -only-testing:Puzzle_BuddyTests/AccessibilityLabelTests \
  ...
```

Manual VoiceOver rotors to verify:

- **Headings** — navigation title hierarchy
- **Links** — forgot password, external links in settings
- **Form controls** — text fields and pickers in puzzle form

## Reporting issues

Users can reach support via [support.html](../docs/support.html). Include:

- iOS version
- Whether VoiceOver, Dynamic Type, or Reduce Motion is enabled
- Steps to reproduce
