# JSON backup restore

**Target:** 1.1.0  
**Depends on:** collection-import-export.md

## Problem

Export JSON exists today but there is no in-app restore. Users expect full backup/restore (My Puzzle Cabinet, iCollect).

## Scope

1. Settings → Import backup → JSON file picker
2. Merge policy: skip duplicates by UUID, or replace all (user choice)
3. Restore metadata from `PuzzleExportRecord` including `startDate`, tags, barcode
4. Photos: phase 1 restore `hasImage` prompt; phase 2 embed or sidecar images in backup format

## Out of scope

- Cloud sync (separate auth release)
