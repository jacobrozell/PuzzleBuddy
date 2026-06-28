# Collection import / export (1.1.0)

**Status:** Implemented, gated off for 1.0.0  
**Flag:** `ProductService.isCollectionImportExportEnabled` (launch arg `-enable_collection_import_export`)

## Scope

- Settings → Import from IPDb CSV
- Settings → Export collection (JSON + IPDb-compatible CSV)
- See [`docs/ipdb-csv-import.md`](../../docs/ipdb-csv-import.md) and [`docs/collection-export.md`](../../docs/collection-export.md)

## Ship criteria

- [ ] Re-enable flag for 1.1.0 (Remote Config or static default)
- [ ] JSON restore flow (see json-backup-restore.md)
- [ ] Large CSV device smoke
- [ ] Update App Store privacy label if needed
