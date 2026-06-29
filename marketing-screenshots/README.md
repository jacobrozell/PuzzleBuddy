# Marketing Screenshots

Professional App Store and marketing assets for **Puzzle Buddy**.

## Folder layout

Screenshots are sorted by **device → appearance → orientation**:

```
marketing-screenshots/
  iphone/
    dark/
      portrait/          ← App Store iPhone upload
      landscape/
    light/
      portrait/
      landscape/
  ipad/
    dark/
      portrait/          ← App Store iPad upload
      landscape/
    light/
      portrait/
      landscape/
  framed/
    iphone/
      dark/portrait/     ← bezels for web/social only
      light/portrait/
```

Legacy flat folders (`raw/`, `ipad/raw/`) are migrated with:

```bash
./Scripts/sort-marketing-screenshots.sh
```

## Quick start

```bash
# iPhone only (dark, portrait + landscape)
./Scripts/capture-marketing-screenshots.sh

# iPad only
./Scripts/capture-ipad-marketing-screenshots.sh

# Full matrix: iphone + ipad × dark + light × portrait + landscape
./Scripts/capture-all-marketing-screenshots.sh

# Optional bezels (portrait iPhone only)
brew install imagemagick   # once
./Scripts/frame-marketing-screenshots.sh
```

## App Store Connect dimensions

Upload from **`iphone/`** and **`ipad/`** subfolders only — no device frames.

| Slot | Portrait | Landscape |
|------|----------|-----------|
| iPhone 6.5" | 1284 × 2778 | 2778 × 1284 |
| iPad 13" | 2064 × 2752 | 2752 × 2064 |

Fix existing PNGs without re-capturing:

```bash
./Scripts/app-store-screenshot-size.sh resize marketing-screenshots/iphone/dark/portrait/*.png
```

## Screens captured

1. **Puzzle list** — demo collection
2. **Duplicate check** — barcode match sheet
3. **Collection stats** — summary dashboard
4. **Add puzzle** — new entry form
5. **Puzzle detail** — completed puzzle (Harbor Lights)
6. **Settings** — local-first preferences
7. **Onboarding welcome** — first-launch tour
8. **Onboarding barcode** — shop-with-confidence page

## Options

```bash
APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh
ORIENTATIONS=portrait ./Scripts/capture-marketing-screenshots.sh
ORIENTATIONS=landscape ./Scripts/capture-marketing-screenshots.sh
SIM_NAME="iPhone 17 Pro Max" APP_STORE_RESIZE=0 ./Scripts/capture-marketing-screenshots.sh
RAW_DIR=marketing-screenshots/iphone/light/portrait ./Scripts/frame-marketing-screenshots.sh
```

## Launch arguments reference

| Screen | Arguments |
|--------|-----------|
| Reset + seed demo | `-ui_test_reset -disable_firebase_analytics -ui_testing_seed_puzzles` |
| Tab | `-snapshot_tab puzzles` / `stats` / `settings` |
| Puzzle detail | `-snapshot_puzzle_detail Harbor Lights` |
| Add puzzle form | `-snapshot_add_puzzle` |
| Duplicate check sheet | `-snapshot_duplicate_check Mountain Sunset` |
| Onboarding | `-snapshot_onboarding` |
| Onboarding page (0–3) | `-snapshot_onboarding_page 1` |

## Framing tips

- **App Store:** upload from `iphone/` and `ipad/` sorted folders — Apple rejects device frames.
- **Marketing:** use `framed/` for a polished look; landscape shots are skipped (frameit is portrait-only).
- **Colors:** iPhone 17 Pro — Deep Blue (default), Cosmic Orange, Silver
