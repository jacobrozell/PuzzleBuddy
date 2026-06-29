# Box photo OCR (Vision)

**Status:** Planned · **Target:** 1.2.0  
**Competitor reference:** IPDb Digital Assistant (box photo → title, brand, pieces)

## Problem

When barcode cache misses (new puzzle at a store), users must type metadata manually. IPDb’s Digital Assistant is their #1 entry path (~95% of new records). Puzzle Buddy needs an on-device equivalent without paid UPC APIs or IPDb partnership.

## Scope

| In scope | Out of scope |
|----------|--------------|
| On-device Vision OCR on cover/box photo | Live IPDb lookup |
| Suggest title, brand (`source`), piece count | Auto-save without user confirm |
| Prefill add/edit form; user edits before save | Manufacturer logo recognition |
| Barcode remains primary duplicate key | Cloud OCR APIs |

## UX

1. User adds or edits puzzle photo (camera or library).
2. Optional **“Scan box text”** action runs OCR in background.
3. Suggested fields shown with clear “Suggested — review before saving” copy.
4. User accepts, edits, or dismisses suggestions.
5. Duplicate guards unchanged (barcode hard, name+brand soft).

## Technical notes

- `Vision` text recognition (`VNRecognizeTextRequest`) on cropped box image.
- Heuristics: largest numeric cluster → pieces; known brand list optional later; title from dominant text block.
- No network; no Analytics parameters with raw OCR text (PII-safe breadcrumbs only).

## Dependencies

- Photo picker / form flow — shipped
- Barcode duplicate logic — shipped

## Related

- [barcode-metadata-strategy.md](../../docs/barcode-metadata-strategy.md)
- [ongoing/barcode-scan-polish.md](../../ongoing/barcode-scan-polish.md) §14
- [competitive-gap-analysis.md](../../docs/competitive-gap-analysis.md)
