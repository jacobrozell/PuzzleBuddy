# Multi-photo gallery

**Target:** 1.2.0

## Problem

Single cover photo only. Competitors support progress/WIP galleries.

## Scope

- `PuzzlePhotoRecord` sub-entities or `[Data]` external storage in SwiftData
- Detail: horizontal scroll of photos; mark one as cover
- Add from camera/library on detail and form
- Export: include in JSON backup; omit from IPDb CSV

## UX

- Max 5 photos per puzzle (configurable)
- VoiceOver: “Photo 2 of 4, progress shot”
