# Multi-photo gallery

**Status:** Planned · **Target:** 1.0.0 (expanded sprint)  
**Sprint:** [1.0.0-expanded-feature-sprint.md](../../docs/implementation/1.0.0-expanded-feature-sprint.md)

## Problem

Single cover photo only. Users want box art plus progress/completed shots — table stakes vs Puzzle Tracker and IPDb galleries.

## Scope

- `PuzzlePhotoRecord` SwiftData entity (see sprint doc)
- Detail: horizontal scroll of photos; first photo = cover for list/collage
- Form + detail: add from camera/library; delete; reorder (long-press or Edit)
- Max **5** photos per puzzle
- Legacy `PuzzleRecord.imageData` migrated to first photo on upgrade

## UX

- Caption optional: Box / Progress / Completed (picker or free text — start with sort order only)
- VoiceOver: “Photo 2 of 4”
- Share collage uses cover photo only (unchanged)

## Export

- JSON: include all photos (base64)
- IPDb CSV: omit (images never in CSV)

## Out of scope

- Per-completion photo sets (see puzzle-redo-completions.md)
- Full-screen pinch zoom gallery (nice-to-have; scroll thumbnails minimum for 1.0)
