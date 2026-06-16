# Documentation & GitHub Pages

This folder serves two purposes:

1. **GitHub Pages** — public legal and support pages for the App Store
2. **Technical documentation** — architecture, development, Firebase, analytics, and testing guides

## GitHub Pages setup

Static HTML for App Store-required URLs.

### Enable Pages

1. Repository **Settings → Pages**
2. **Source:** Deploy from a branch
3. **Branch:** `main` or `master`
4. **Folder:** `/docs`

GitHub publishes the site within a few minutes of pushing to the selected branch.

### Public URLs

Assuming repo name `PuzzleBuddy` and user `jacobrozell`:

| Page | URL |
|------|-----|
| Home | https://jacobrozell.github.io/PuzzleBuddy/ |
| Privacy policy | https://jacobrozell.github.io/PuzzleBuddy/privacy.html |
| Support | https://jacobrozell.github.io/PuzzleBuddy/support.html |
| Accessibility | https://jacobrozell.github.io/PuzzleBuddy/accessibility.html |

### Site files

```
docs/
├── index.html           # Landing / redirect
├── privacy.html         # Privacy policy
├── support.html         # Support contact and FAQ
├── accessibility.html   # Accessibility statement
├── assets/
│   └── style.css        # Shared styles
└── *.md                 # Technical docs (not served as HTML by default)
```

To update legal copy, edit the HTML files directly. Shared styling lives in `assets/style.css`.

### App Store Connect

Point Privacy Policy URL, Support URL, and Marketing URL fields to the Pages URLs above.

## Technical documentation index

These Markdown files are for developers (linked from the root [README.md](../README.md)):

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | App structure, data model, navigation, dependencies |
| [development.md](development.md) | Local setup, XcodeGen, debugging, troubleshooting |
| [firebase-setup.md](firebase-setup.md) | Firebase Console, Analytics, Crashlytics; Auth/Firestore for login release |
| [analytics.md](analytics.md) | AppLog, Analytics allowlist, privacy rules |
| [testing.md](testing.md) | Unit tests, UI tests, CI test runner |
| [wcag.md](wcag.md) | WCAG 2.1 AA conformance guide |

## Contributing to docs

- Keep the root README as the entry point with links into `docs/`
- Update technical docs when changing architecture, Firebase schema, CI, or analytics allowlist
- Update HTML legal pages when privacy practices or support contact changes
- Follow the same PR process as code — see [CONTRIBUTING.md](../CONTRIBUTING.md)

## Accessibility & WCAG documentation

| Document | Audience |
|----------|----------|
| [accessibility.html](accessibility.html) | Public accessibility statement (GitHub Pages) |
| [wcag.md](wcag.md) | WCAG 2.1 AA guide — criteria mapping, screens, iOS AT testing |
| [../accessibility/accessibility_todo.md](../accessibility/accessibility_todo.md) | Engineering roadmap and phases |
| [../accessibility/wcag-2.1-aa/conformance-matrix.md](../accessibility/wcag-2.1-aa/conformance-matrix.md) | Per-criterion Supports / Partial / Planned status |
| [../accessibility/wcag-2.1-aa/voiceover-scripts/](../accessibility/wcag-2.1-aa/voiceover-scripts/) | Expected VoiceOver reading order per screen |
