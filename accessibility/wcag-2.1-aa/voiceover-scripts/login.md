# VoiceOver script — Login screen

Expected reading order when swiping right through `LoginView`.

## Preconditions

- VoiceOver enabled
- User on login screen (not signed in)
- Reduce Motion optional (background may be gradient or static)

## Reading order

| # | Element | Expected announcement | Identifier |
|---|---------|----------------------|------------|
| 1 | Email field | "Email, text field" or "Email address, text field" | `login_email_field` |
| 2 | Password field | "Password, secure text field" | `login_password_field` |
| 3 | Forgot password | "Forgot password, button" | `forgot_password_button` |
| 4 | Log in | "Log in, button" | `login_submit_button` |
| 5 | Sign in with Apple | System: "Sign in with Apple, button" | — |
| 6 | Create account link | Visible link text | — |

Order may vary if decorative header content is inserted above the form — decorative elements should be skipped or marked as such.

## Rotor checks

| Rotor | Expected |
|-------|----------|
| Headings | App title or section heading if present |
| Form controls | Email, Password |
| Links | Forgot password, create account |

## Pass criteria

- All interactive elements reachable without unexplained dead zones
- No control announced only as "button" without purpose
- Double-tap activates control

## Known issues

- Document gaps here as found during audit
