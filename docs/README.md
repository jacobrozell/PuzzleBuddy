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

These Markdown files are for developers and agents (linked from [README.md](../README.md)):

| Document | Description |
|----------|-------------|
| [../AGENTS.md](../AGENTS.md) | **Agent onboarding** — product snapshot, read order, anti-patterns |
| [agent-build-checklist.md](agent-build-checklist.md) | Phased 0→Ship status, progress log, agent query template |
| [feature-inventory.md](feature-inventory.md) | What ships today — shipped / gated / planned |
| [telemetry.md](telemetry.md) | **Logging, Analytics, Crashlytics** — full allowlists and bootstrap |
| [features.md](features.md) | Core features — user flows, fields, persistence |
| [roadmap.md](roadmap.md) | Future releases and backlog |
| [implementation-playbook.md](implementation-playbook.md) | Build-all-then-cut workflow, agent queries |
| [architecture.md](architecture.md) | App structure, data model, navigation |
| [development.md](development.md) | Local setup, XcodeGen, debugging |
| [firebase-setup.md](firebase-setup.md) | Firebase Console — Analytics + Crashlytics only |
| [analytics.md](analytics.md) | AppLog quick reference (see telemetry.md for full spec) |
| [testing.md](testing.md) | Unit tests, UI tests, CI |
| [wcag.md](wcag.md) | WCAG 2.1 AA conformance guide |

## Contributing to docs

- Keep the root README as the entry point with links into `docs/`
- Update technical docs when changing architecture, telemetry allowlists, CI, or feature flags
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
