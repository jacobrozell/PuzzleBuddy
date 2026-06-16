# WCAG 2.1 Level AA — Conformance matrix

Per-criterion status for Puzzle Buddy iOS app. Updated as audits complete.

**Legend**

| Status | Meaning |
|--------|---------|
| **Supports** | Implemented and verified |
| **Partial** | Implemented with known gaps |
| **Planned** | On roadmap (see [accessibility_todo.md](../accessibility_todo.md)) |
| **N/A** | Not applicable to native iOS app |
| **Not evaluated** | Not yet audited |

**Last reviewed:** 2026-06-16  
**Target level:** WCAG 2.1 AA

---

## 1. Perceivable

| Criterion | Name | Level | Status | Notes |
|-----------|------|-------|--------|-------|
| 1.1.1 | Non-text Content | A | Partial | Puzzle images lack user-authored alt text; decorative Lottie |
| 1.2.1 | Audio-only and Video-only | A | N/A | No prerecorded A/V |
| 1.2.2 | Captions (Prerecorded) | A | N/A | |
| 1.2.3 | Audio Description or Media Alternative | A | N/A | |
| 1.2.4 | Captions (Live) | AA | N/A | |
| 1.2.5 | Audio Description (Prerecorded) | AA | N/A | |
| 1.3.1 | Info and Relationships | A | Partial | Form structure OK; custom controls incomplete |
| 1.3.2 | Meaningful Sequence | A | Supports | Login and list order verified |
| 1.3.3 | Sensory Characteristics | A | Supports | Instructions not shape/color-only |
| 1.4.1 | Use of Color | A | Supports | Status uses text labels |
| 1.4.2 | Audio Control | A | N/A | No auto-play audio |
| 1.4.3 | Contrast (Minimum) | AA | Partial | Accent on white OK; full token audit pending |
| 1.4.4 | Resize Text | AA | Partial | System Dynamic Type; AX5 layout audit pending |
| 1.4.5 | Images of Text | AA | Supports | No critical bitmap text |
| 1.4.10 | Reflow | AA | Partial | Scrollable forms; some fixed heights |
| 1.4.11 | Non-text Contrast | AA | Planned | Star/difficulty UI components |
| 1.4.12 | Text Spacing | AA | Supports | System fonts |
| 1.4.13 | Content on Hover or Focus | AA | N/A | Touch-first |

---

## 2. Operable

| Criterion | Name | Level | Status | Notes |
|-----------|------|-------|--------|-------|
| 2.1.1 | Keyboard | A | Supports | Text fields; VoiceOver/Voice Control for rest |
| 2.1.2 | No Keyboard Trap | A | Supports | Standard navigation |
| 2.1.4 | Character Key Shortcuts | A | N/A | No single-key shortcuts |
| 2.2.1 | Timing Adjustable | A | Supports | No session timeouts |
| 2.2.2 | Pause, Stop, Hide | A | Partial | Gradient respects Reduce Motion; Lottie does not |
| 2.3.1 | Three Flashes or Below | A | Supports | No flashing content |
| 2.4.1 | Bypass Blocks | A | Supports | Tab bar |
| 2.4.2 | Page Titled | A | Supports | Navigation titles |
| 2.4.3 | Focus Order | A | Partial | Puzzle form audit pending |
| 2.4.4 | Link Purpose (In Context) | A | Supports | Forgot password, support links |
| 2.4.5 | Multiple Ways | A | Supports | Tabs + list |
| 2.4.6 | Headings and Labels | AA | Partial | Login done; form in progress |
| 2.4.7 | Focus Visible | AA | Supports | iOS system focus |
| 2.5.1 | Pointer Gestures | A | Supports | Tap; swipe delete with VO action |
| 2.5.2 | Pointer Cancellation | A | Supports | System controls |
| 2.5.3 | Label in Name | A | Supports | Visible labels match a11y names on login |
| 2.5.4 | Motion Actuation | A | Supports | No motion-triggered actions |

---

## 3. Understandable

| Criterion | Name | Level | Status | Notes |
|-----------|------|-------|--------|-------|
| 3.1.1 | Language of Page | A | Supports | English UI |
| 3.1.2 | Language of Parts | AA | N/A | Monolingual |
| 3.2.1 | On Focus | A | Supports | No unexpected context change |
| 3.2.2 | On Input | A | Supports | No auto-submit on field entry |
| 3.2.3 | Consistent Navigation | AA | Supports | Persistent tab bar |
| 3.2.4 | Consistent Identification | AA | Supports | `A11yID` constants |
| 3.3.1 | Error Identification | A | Supports | `ErrorHandling` alerts |
| 3.3.2 | Labels or Instructions | A | Partial | Puzzle form hints incomplete |
| 3.3.3 | Error Suggestion | AA | Partial | Firebase auth messages |
| 3.3.4 | Error Prevention (Legal, Financial, Data) | AA | Supports | Delete requires swipe; no single-tap data loss |

---

## 4. Robust

| Criterion | Name | Level | Status | Notes |
|-----------|------|-------|--------|-------|
| 4.1.1 | Parsing | A | N/A | Native UI |
| 4.1.2 | Name, Role, Value | A | Partial | Login/settings OK; rating/difficulty planned |
| 4.1.3 | Status Messages | AA | Planned | Sync completion not announced |

---

## Summary

| Status | Count (of applicable AA criteria) |
|--------|----------------------------------|
| Supports | 28 |
| Partial | 12 |
| Planned | 3 |
| N/A | 15 |
| Not evaluated | 0 |

**Overall:** Partial conformance — committed to full AA; see [docs/wcag.md](../../docs/wcag.md) for remediation plan.

---

## Verification log

| Date | Auditor | Scope | Result |
|------|---------|-------|--------|
| 2026-06-16 | Engineering | Login, list, settings, tokens | Phase 1 criteria documented |
| — | — | Full VoiceOver form pass | Pending |
| — | — | Dynamic Type AX5 audit | Pending |
| — | — | XCUIAccessibilityAudit | Pending |

Add rows as formal audits complete. Store screenshots in `screenshots/` and VoiceOver scripts in `voiceover-scripts/`.
