# Collection export

Back up your Puzzle Buddy collection from **Settings → Collection → Export collection**.

## Formats

| Format | Best for |
|--------|----------|
| **JSON** | Full structured backup; re-import tooling later |
| **CSV** | Spreadsheets, quick inspection, **IPDb-compatible re-import** |

## Included fields

Name, brand (source), pieces, barcode, status, rating, difficulty, completion date, notes, progress, missing-pieces flag. JSON also includes export timestamp and app version.

## Not included

- **Box photos** — export records `hasImage` in JSON only; CSV omits images. Re-attach photos after any restore workflow.
- Firestore / account data — local collection only.

## Share flow

Export opens the system share sheet so you can save to Files, iCloud Drive, or AirDrop.

## Related

- [ipdb-csv-import.md](ipdb-csv-import.md) — import from IPDb
- [phase-1-polish-plan.md](phase-1-polish-plan.md) — polish checklist
