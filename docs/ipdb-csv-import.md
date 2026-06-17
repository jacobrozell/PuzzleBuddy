# IPDb CSV import

Puzzle Buddy includes an IPDb CSV importer for **personal collection exports** — the migration path IPDb documents in their Listview export flow.

**Release status:** Shipped in Settings → Collection → **Import from IPDb CSV**.

## How to export from IPDb

1. Open [IPDb](https://www.ipdb.plus/) and sign in.
2. Open the folder or list you want to export (your collection, wishlist, etc.).
3. In the **Listview toolbar**, tap **Export**.
4. Choose **CSV**.
5. Save the file to Files, iCloud Drive, or email it to yourself.

IPDb may include extra **private fields** you configured; Puzzle Buddy imports common columns and ignores the rest.

## How to import into Puzzle Buddy

1. Open **Settings** → **Collection**.
2. Tap **Import from IPDb CSV**.
3. Select your `.csv` file.
4. Review the summary (imported, duplicates skipped, invalid rows).

## How to export from Puzzle Buddy

1. Open **Settings** → **Collection**.
2. Tap **Export collection** → **Export as IPDb CSV**.
3. Save or share the file from the share sheet.

Exported CSV uses the same column layout as IPDb Listview exports (`Title`, `Brand`, `Piece Count`, `Barcode`, `Folder`, etc.) so you can re-import into Puzzle Buddy or migrate toward IPDb. Use **Export as JSON** for a full local backup including fields IPDb CSV does not support (e.g. missing-pieces flag, image presence).

## Mapped fields

| IPDb / CSV column (flexible names) | Puzzle Buddy field |
|-----------------------------------|-------------------|
| Title, Name, Puzzle Name | Name |
| Brand, Manufacturer | Source |
| Piece Count, Pieces | Pieces |
| Barcode, UPC, EAN | Barcode |
| Status, Folder | Status (Completed / In-Progress / To-Do) |
| Progress Percent | Progress (%) |
| Rating | Rating |
| Difficulty | Difficulty |
| Completion Date | Completion date |
| Notes | Notes |
| Manufacturer ID, SKU | Appended to notes |

## Duplicate handling

- Rows with a **barcode already in your collection** are skipped.
- Rows **without a title** are skipped.
- Import **adds** to your collection; it does not delete existing puzzles.

## Limitations

- **No images** — IPDb CSV exports do not include box photos. Re-add photos in Puzzle Buddy after import.
- **Column names vary** — exports may include custom private fields; we map common aliases but cannot guarantee every IPDb configuration.
- **Not a sync** — this is a one-time migration. Re-importing the same file will skip barcode duplicates.

## Related

- [barcode-metadata-strategy.md](barcode-metadata-strategy.md) — IPDb partnership vs import
- [ipdb-partnership-outreach.md](ipdb-partnership-outreach.md) — partnership email draft
