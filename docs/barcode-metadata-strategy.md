# Barcode metadata strategy

Puzzle Buddy’s core barcode value is **offline duplicate checking** (Phases A–C). Optional title/brand/pieces enrichment is **nice-to-have** and should stay cheap.

## Cost reality

| Approach | Cost | Puzzle hit rate |
|----------|------|-----------------|
| **Local duplicate check** | Free | 100% for barcodes you’ve saved |
| **On-device cache** (`BarcodeMetadataCache`) | Free | 100% for barcodes you’ve saved before |
| **UPCitemdb trial** | Free, ~100 req/day | Unknown; often poor for jigsaws |
| **Paid UPC APIs** (Barcode Lookup, Go-UPC, etc.) | $99+/mo typical | Unknown; not justified for 1.0 |

**Decision:** Do not depend on paid UPC APIs. Keep online lookup **off by default**; prefer local data.

## Shipped today

1. **Barcode field + duplicate guard** — exact UPC match against your collection (SwiftData).
2. **Shopping mode** — scan → instant match / no-match, fully offline.
3. **Local metadata cache** — when you save a puzzle with a barcode, name/pieces/source are cached on-device for future scans (no network).
4. **Optional UPCitemdb trial** — Settings toggle “Look up product from barcode”; only runs after local cache misses.

Lookup order: in-memory session cache → `BarcodeMetadataCache` → UPCitemdb (if enabled).

## Recommended next steps (no API bill)

| Priority | Idea | Effort | Notes |
|----------|------|--------|-------|
| **1** | Box photo OCR (Vision) | Medium | Read title/pieces/brand from label text — works when UPC DB fails |
| **2** | Community barcode map (opt-in) | Large | Firebase or IPDb-style shared map; privacy policy + consent |
| **3** | Import CSV with barcodes | Medium | Phase E; bulk garage cataloging |
| **4** | User “remember this barcode” on save | Small | Already covered by `BarcodeMetadataCache` |

## What we are not doing

- Embedding paid API keys in the app
- Requiring network for duplicate checks
- Auto-saving puzzles from lookup without user confirmation

## Related docs

- [spec-barcode-scanner.md](spec-barcode-scanner.md) — full phased spec
- [roadmap.md](roadmap.md) — competitive context
