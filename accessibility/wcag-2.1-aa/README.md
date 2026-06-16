# WCAG 2.1 AA evidence folder

Stores conformance artifacts for Puzzle Buddy accessibility audits.

## Contents

| Path | Purpose |
|------|---------|
| [conformance-matrix.md](conformance-matrix.md) | Per-criterion Supports / Partial / Planned status |
| [voiceover-scripts/](voiceover-scripts/) | Expected VoiceOver reading order per screen |
| `screenshots/` | Dynamic Type, contrast, and layout captures (add during audits) |

## How to use

1. Run manual audit per [docs/wcag.md](../../docs/wcag.md)
2. Update `conformance-matrix.md` status columns
3. Add screenshots to `screenshots/` named `{screen}-{setting}.png` (e.g. `login-voiceover.png`, `list-ax5-text.png`)
4. Log audit date in the matrix **Verification log** table

## Related

- [accessibility_todo.md](../accessibility_todo.md) — engineering phases
- [docs/wcag.md](../../docs/wcag.md) — full WCAG guide
- [docs/accessibility.html](../../docs/accessibility.html) — public statement
