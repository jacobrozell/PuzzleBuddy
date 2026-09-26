# Collection import / export

**Status:** **Deferred** — Settings UI removed in 1.1.0 (zero production usage). CSV/JSON **helpers remain** in the codebase for a future re-ship.  
**Flag:** removed (`ProductService.isCollectionImportExportEnabled` deleted)

## Current state (2026-09-21)

| Layer | Status |
|-------|--------|
| Settings UI (import IPDb / export / JSON restore) | **Removed** |
| `IPDbCSVImporter`, `PuzzleCollectionExporter`, JSON backup importer | **Kept** (unit-tested; no Settings entry) |
| `PuzzleStore.importPuzzles` / `importBackup` | **Kept** |

## Future re-ship scope

- Settings → Import from IPDb CSV
- Settings → Export collection (JSON + IPDb-compatible CSV)
- Settings → JSON backup merge / replace restore
- See [`docs/ipdb-csv-import.md`](../../docs/ipdb-csv-import.md), [`docs/collection-export.md`](../../docs/collection-export.md), [`json-backup-restore.md`](json-backup-restore.md)

## Re-ship criteria

- [ ] Clear demand (support requests or analytics after opt-in dogfood)
- [ ] Restore Settings UI + summary sheet
- [ ] Re-add feature flag or ship ungated with UI tests
- [ ] Large CSV device smoke
- [ ] App Store privacy label still accurate (user-initiated file access)
- [ ] Optional: onboarding mention

**Tracked in:** [`FutureIdeas/backlog.md`](../../FutureIdeas/backlog.md)
