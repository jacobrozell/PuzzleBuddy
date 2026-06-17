#!/usr/bin/env python3
"""
UPCitemdb corpus spike for Puzzle Buddy Phase 2.

Reads docs/fixtures/upc-corpus.tsv, queries the trial API, writes TSV results,
and prints a summary. Respects UPCitemdb's ~100 requests/day trial limit.

Usage:
  python3 Scripts/upc-lookup-spike.py
  python3 Scripts/upc-lookup-spike.py --limit 12 --delay 1.2
  python3 Scripts/upc-lookup-spike.py --score-only docs/upc-lookup-spike-output.tsv
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

API_URL = "https://api.upcitemdb.com/prod/trial/lookup"
PIECE_PATTERN = re.compile(r"(?i)(\d{2,5})\s*(?:piece|pieces|pc|pce|pcs)\b")
REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CORPUS = REPO_ROOT / "docs/fixtures/upc-corpus.tsv"
DEFAULT_OUTPUT = REPO_ROOT / "docs/upc-lookup-spike-output.tsv"


@dataclass
class CorpusRow:
    brand: str
    expected_title: str
    expected_pieces: int | None
    upc: str
    source: str


@dataclass
class LookupRow:
    brand: str
    upc: str
    expected_title: str
    expected_pieces: int | None
    http_status: int
    api_title: str
    api_brand: str
    parsed_pieces: int | None
    api_hit: bool
    brand_match: bool
    pieces_match: bool
    title_usable: bool
    error: str


def parse_pieces(title: str | None) -> int | None:
    if not title:
        return None
    match = PIECE_PATTERN.search(title)
    return int(match.group(1)) if match else None


def load_corpus(path: Path) -> list[CorpusRow]:
    rows: list[CorpusRow] = []
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for raw in reader:
            pieces_raw = (raw.get("expected_pieces") or "").strip()
            expected_pieces = int(pieces_raw) if pieces_raw.isdigit() else None
            rows.append(
                CorpusRow(
                    brand=(raw.get("brand") or "").strip(),
                    expected_title=(raw.get("expected_title") or "").strip(),
                    expected_pieces=expected_pieces,
                    upc=(raw.get("upc") or "").strip(),
                    source=(raw.get("source") or "").strip(),
                )
            )
    return rows


def fetch_upc(upc: str, timeout: float) -> tuple[int, dict | None, str]:
    url = f"{API_URL}?upc={upc}"
    request = urllib.request.Request(
        url,
        headers={"Accept": "application/json", "User-Agent": "PuzzleBuddy-UPC-Spike/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status = response.getcode()
            body = response.read().decode("utf-8")
            payload = json.loads(body) if body else {}
            return status, payload, ""
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(body) if body else {}
        except json.JSONDecodeError:
            payload = None
        return error.code, payload, body[:200]
    except Exception as error:  # noqa: BLE001 - spike script
        return 0, None, str(error)


def score_row(corpus: CorpusRow, http_status: int, api_title: str, api_brand: str, parsed_pieces: int | None) -> LookupRow:
    api_hit = http_status == 200 and bool(api_title or api_brand)
    expected_brand = corpus.brand.casefold()
    haystack = f"{api_brand} {api_title}".casefold()
    brand_match = expected_brand in haystack if expected_brand else False

    pieces_match = False
    if corpus.expected_pieces is not None and parsed_pieces is not None:
        pieces_match = corpus.expected_pieces == parsed_pieces

    title_usable = api_hit and ("puzzle" in api_title.casefold() or brand_match)

    return LookupRow(
        brand=corpus.brand,
        upc=corpus.upc,
        expected_title=corpus.expected_title,
        expected_pieces=corpus.expected_pieces,
        http_status=http_status,
        api_title=api_title,
        api_brand=api_brand,
        parsed_pieces=parsed_pieces,
        api_hit=api_hit,
        brand_match=brand_match,
        pieces_match=pieces_match,
        title_usable=title_usable,
        error="",
    )


def lookup_corpus(rows: list[CorpusRow], limit: int | None, delay: float, timeout: float) -> list[LookupRow]:
    results: list[LookupRow] = []
    eligible = [row for row in rows if row.upc and row.upc != "TBD"]
    if limit is not None:
        eligible = eligible[:limit]

    for index, corpus in enumerate(eligible):
        if index > 0 and delay > 0:
            time.sleep(delay)

        status, payload, error = fetch_upc(corpus.upc, timeout)
        api_title = ""
        api_brand = ""
        if payload and isinstance(payload, dict):
            items = payload.get("items") or []
            if items:
                first = items[0]
                api_title = (first.get("title") or "").strip()
                api_brand = (first.get("brand") or "").strip()

        parsed_pieces = parse_pieces(api_title)
        row = score_row(corpus, status, api_title, api_brand, parsed_pieces)
        row.error = error
        results.append(row)
        print(f"[{index + 1}/{len(eligible)}] {corpus.upc} -> {status} hit={row.api_hit}", file=sys.stderr)

    return results


def write_results(path: Path, rows: list[LookupRow]) -> None:
    fieldnames = [
        "brand",
        "upc",
        "expected_title",
        "expected_pieces",
        "http_status",
        "api_title",
        "api_brand",
        "parsed_pieces",
        "api_hit",
        "brand_match",
        "pieces_match",
        "title_usable",
        "error",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "brand": row.brand,
                    "upc": row.upc,
                    "expected_title": row.expected_title,
                    "expected_pieces": row.expected_pieces or "",
                    "http_status": row.http_status,
                    "api_title": row.api_title,
                    "api_brand": row.api_brand,
                    "parsed_pieces": row.parsed_pieces or "",
                    "api_hit": int(row.api_hit),
                    "brand_match": int(row.brand_match),
                    "pieces_match": int(row.pieces_match),
                    "title_usable": int(row.title_usable),
                    "error": row.error,
                }
            )


def read_results(path: Path) -> list[LookupRow]:
    rows: list[LookupRow] = []
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for raw in reader:
            expected_pieces_raw = (raw.get("expected_pieces") or "").strip()
            parsed_pieces_raw = (raw.get("parsed_pieces") or "").strip()
            rows.append(
                LookupRow(
                    brand=raw.get("brand", ""),
                    upc=raw.get("upc", ""),
                    expected_title=raw.get("expected_title", ""),
                    expected_pieces=int(expected_pieces_raw) if expected_pieces_raw.isdigit() else None,
                    http_status=int(raw.get("http_status") or 0),
                    api_title=raw.get("api_title", ""),
                    api_brand=raw.get("api_brand", ""),
                    parsed_pieces=int(parsed_pieces_raw) if parsed_pieces_raw.isdigit() else None,
                    api_hit=raw.get("api_hit") == "1",
                    brand_match=raw.get("brand_match") == "1",
                    pieces_match=raw.get("pieces_match") == "1",
                    title_usable=raw.get("title_usable") == "1",
                    error=raw.get("error", ""),
                )
            )
    return rows


def print_summary(rows: list[LookupRow]) -> None:
    total = len(rows)
    if total == 0:
        print("No rows to summarize.")
        return

    def pct(count: int) -> str:
        return f"{count}/{total} ({100 * count / total:.0f}%)"

    api_hits = sum(1 for row in rows if row.api_hit)
    usable = sum(1 for row in rows if row.title_usable)
    brand_ok = sum(1 for row in rows if row.brand_match)
    pieces_ok = sum(1 for row in rows if row.pieces_match)
    rate_limited = sum(1 for row in rows if row.http_status == 429)

    print("\n=== UPC lookup spike summary ===")
    print(f"Rows: {total}")
    print(f"API hit (any title/brand): {pct(api_hits)}")
    print(f"Title usable (puzzle keyword or brand match): {pct(usable)}")
    print(f"Brand match: {pct(brand_ok)}")
    print(f"Pieces match expected: {pct(pieces_ok)}")
    if rate_limited:
        print(f"Rate limited (429): {rate_limited}")
    print("\nGo/no-go threshold from plan: <30% usable titles -> deprioritize generic UPC APIs")
    if usable / total < 0.30:
        print("Recommendation: NO-GO for more UPC API investment (favor box OCR / IPDb).")
    else:
        print("Recommendation: marginal GO — review false positives manually before expanding API work.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run UPCitemdb corpus spike.")
    parser.add_argument("--corpus", type=Path, default=DEFAULT_CORPUS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--limit", type=int, default=None, help="Max UPCs to query (trial API ~100/day).")
    parser.add_argument("--delay", type=float, default=2.5, help="Seconds between requests (UPCitemdb returns 429 TOO_FAST if too fast).")
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--score-only", type=Path, default=None, help="Summarize an existing output TSV.")
    args = parser.parse_args()

    if args.score_only:
        rows = read_results(args.score_only)
        print_summary(rows)
        return 0

    corpus = load_corpus(args.corpus)
    print(f"Corpus: {args.corpus} ({len(corpus)} rows, {sum(1 for r in corpus if r.upc != 'TBD')} with UPCs)", file=sys.stderr)
    results = lookup_corpus(corpus, args.limit, args.delay, args.timeout)
    write_results(args.output, results)
    print(f"Wrote {args.output}", file=sys.stderr)
    print_summary(results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
