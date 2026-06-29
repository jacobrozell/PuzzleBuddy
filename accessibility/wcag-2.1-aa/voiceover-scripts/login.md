# Login screen — archived

**Status:** Removed from app (June 2026). Login UI and Firebase Auth are not in Puzzle Buddy 1.0.

This script is kept for historical WCAG evidence only. Active audit targets: puzzle list, puzzle form, settings, stats — see [puzzle-list.md](puzzle-list.md) and [wcag.md](../../docs/wcag.md).

If auth returns per [specs/planned/auth-cloud-sync.md](../../../specs/planned/auth-cloud-sync.md), recreate login VoiceOver scripts and UI tests.

---

## Original script (archived)

Expected reading order when swiping right through `LoginView` (removed).

| Step | Element | Expected VoiceOver | Identifier (removed) |
|------|---------|-------------------|----------------------|
| 1 | Email field | "Email, text field" | `login_email_field` |
| 2 | Password field | "Password, secure text field" | `login_password_field` |
| 4 | Log in | "Log in, button" | `login_submit_button` |
