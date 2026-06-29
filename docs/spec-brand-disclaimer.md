# Brand & trademark disclaimer

Inspired by [IPDb](https://www.ipdb.plus/)’s footer: clear, always visible, and separate from marketing copy. Puzzle Buddy shows **brand names** (source field, barcode lookup, CSV import) and may show logos in the future — we need the same clarity.

## Goals

1. **Identification only** — brand text/logos help users catalog puzzles, not imply endorsement.
2. **User trust** — especially when importing from IPDb or using barcode enrichment.
3. **Legal hygiene** — standard nominative fair-use framing; not legal advice.

## Copy (shipped in `LegalCopy.swift`)

### Brand / manufacturer disclaimer

> All brand names and logos are trademarks of their respective owners. Their use in Puzzle Buddy is for identification and personal cataloging only.
>
> Puzzle Buddy is not affiliated with, endorsed by, or sponsored by any puzzle manufacturer or retailer.

### IPDb import addendum

> Puzzle Buddy is not affiliated with IPDb. Imported titles and brands come from your own export and are stored only in your personal collection on this device.

## UI placement

| Location | Component | When shown |
|----------|-----------|------------|
| **Settings → Help & Legal** | `LegalDisclaimerFooter` | Always (primary home for full disclaimer) |
| **Settings → Collection** | Section footer note | Only when `isCollectionImportExportEnabled` |
| **Add / edit form → Source** | Form section footer | When source presets or brand field visible |
| **Quick add from scan** | Section footer | When suggested brand from lookup/cache |
| **IPDb import results** | Section footer | Only when import flag on |

## Design tokens

- Font: `.footnote` (Settings), `.caption` (forms)
- Color: `Brand.textSecondary`
- No icons; plain prose like IPDb
- VoiceOver: single combined label per footer block

## Accessibility

- Identifier: `settings_brand_disclaimer_footer`
- Do not hide in collapsed sections; Settings list scrolls to it

## Future

- If we display manufacturer logos: same disclaimer + no logo without permission policy
- If IPDb partnership ships: add “Data from IPDb” attribution line per agreement
- Link to full legal page on website when terms page exists

## Related

- [barcode-metadata-strategy.md](barcode-metadata-strategy.md) — IPDb data ethics
- [ipdb-csv-import.md](ipdb-csv-import.md) — migration flow
