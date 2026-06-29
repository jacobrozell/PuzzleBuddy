# Collection import / export

**Status:** Implemented — **shipping in 1.0.0** (un-gated)  
**Flag:** `ProductService.isCollectionImportExportEnabled` — default **true** after expanded sprint

## Scope

- Settings → Import from IPDb CSV
- Settings → Export collection (JSON + IPDb-compatible CSV)
- See [`docs/ipdb-csv-import.md`](../../docs/ipdb-csv-import.md) and [`docs/collection-export.md`](../../docs/collection-export.md)

## Ship criteria

- [ ] Default flag `true` in production builds
- [ ] UI tests use `-disable_collection_import_export` if needed (or assert buttons visible)
- [ ] Large CSV device smoke
- [ ] App Store privacy label still accurate (user-initiated file access)
- [ ] Onboarding mentions IPDb import path

**Note:** JSON **restore** UI remains a separate spec ([json-backup-restore.md](json-backup-restore.md)) — export-only for 1.0 unless added in sprint.
