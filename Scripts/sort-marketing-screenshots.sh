#!/usr/bin/env bash
# Move legacy flat marketing screenshots into sorted folders:
#   marketing-screenshots/{iphone|ipad}/{dark|light}/{portrait|landscape}/
#
# Handles old layouts:
#   marketing-screenshots/raw/*.png
#   marketing-screenshots/ipad/raw/*.png
#   marketing-screenshots/framed/*.png
#
# Usage:
#   ./Scripts/sort-marketing-screenshots.sh
#   ./Scripts/sort-marketing-screenshots.sh --dry-run

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/marketing-screenshots"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

move_file() {
  local src="$1"
  local dest="$2"
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "→ $src → $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  echo "→ $(basename "$dest") → $(dirname "$dest")/"
}

classify_raw() {
  local src="$1"
  local device_kind="$2"
  local base
  base="$(basename "$src" .png)"

  local appearance="dark"
  local orientation="portrait"
  local stem="$base"

  if [[ "$base" == *-light-landscape ]]; then
    appearance="light"
    orientation="landscape"
    stem="${base%-light-landscape}"
  elif [[ "$base" == *-dark-landscape ]]; then
    appearance="dark"
    orientation="landscape"
    stem="${base%-dark-landscape}"
  elif [[ "$base" == *-light ]]; then
    appearance="light"
    stem="${base%-light}"
  elif [[ "$base" == *-dark ]]; then
    appearance="dark"
    stem="${base%-dark}"
  elif [[ "$base" == *-landscape ]]; then
    orientation="landscape"
    stem="${base%-landscape}"
  fi

  move_file "$src" "$BASE/$device_kind/$appearance/$orientation/${stem}.png"
}

classify_framed() {
  local src="$1"
  local base
  base="$(basename "$src" .png)"
  base="${base%-framed}"

  local appearance="dark"
  local orientation="portrait"
  local stem="$base"

  if [[ "$base" == *-light-landscape ]]; then
    appearance="light"
    orientation="landscape"
    stem="${base%-light-landscape}"
  elif [[ "$base" == *-dark-landscape ]]; then
    appearance="dark"
    orientation="landscape"
    stem="${base%-dark-landscape}"
  elif [[ "$base" == *-light ]]; then
    appearance="light"
    stem="${base%-light}"
  elif [[ "$base" == *-dark ]]; then
    appearance="dark"
    stem="${base%-dark}"
  elif [[ "$base" == *-landscape ]]; then
    orientation="landscape"
    stem="${base%-landscape}"
  fi

  move_file "$src" "$BASE/framed/iphone/$appearance/$orientation/${stem}-framed.png"
}

shopt -s nullglob

for file in "$BASE/raw"/*.png; do
  [[ -f "$file" ]] || continue
  classify_raw "$file" iphone
done

for file in "$BASE/ipad/raw"/*.png; do
  [[ -f "$file" ]] || continue
  classify_raw "$file" ipad
done

for file in "$BASE/framed"/*.png; do
  [[ -f "$file" ]] || continue
  classify_framed "$file"
done

# Remove empty legacy dirs
if [[ "$DRY_RUN" == 0 ]]; then
  rmdir "$BASE/raw" 2>/dev/null || true
  rmdir "$BASE/ipad/raw" 2>/dev/null || true
  rmdir "$BASE/ipad" 2>/dev/null || true
fi

echo ""
echo "Sorted layout:"
find "$BASE" -name '*.png' | sort | sed "s|$BASE/||"
