#!/usr/bin/env bash
# Wrap raw simulator screenshots in iPhone device bezels (ImageMagick + frameit frames).
#
# Usage:
#   ./Scripts/frame-marketing-screenshots.sh
#   FRAME_COLOR="Deep Blue" ./Scripts/frame-marketing-screenshots.sh
#   FRAME_DEVICE="iPhone 17 Pro Max" ./Scripts/frame-marketing-screenshots.sh
#   RAW_DIR=marketing-screenshots/iphone/dark/portrait ./Scripts/frame-marketing-screenshots.sh
#
# Requires: brew install imagemagick
# Output: marketing-screenshots/framed/iphone/{dark|light}/portrait/*-framed.png

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETING_BASE="${MARKETING_BASE:-$ROOT/marketing-screenshots}"
FRAMED_BASE="${FRAMED_BASE:-$MARKETING_BASE/framed}"
FRAMES_DIR="${FRAMES_DIR:-$HOME/.fastlane/frameit/latest}"
FRAME_DEVICE="${FRAME_DEVICE:-iPhone 17 Pro}"
FRAME_COLOR="${FRAME_COLOR:-Deep Blue}"
ROUND_RADIUS="${ROUND_RADIUS:-100}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install with: brew install imagemagick" >&2
  exit 1
fi

if [[ ! -d "$FRAMES_DIR" ]]; then
  echo "→ Downloading device frames…"
  fastlane frameit download_frames
fi

OFFSETS_JSON="$FRAMES_DIR/offsets.json"
if [[ ! -f "$OFFSETS_JSON" ]]; then
  echo "Missing offsets at $OFFSETS_JSON" >&2
  exit 1
fi

read -r OFFSET_X OFFSET_Y SCREEN_WIDTH <<<"$(python3 -c "
import json, sys
device, path = sys.argv[1], sys.argv[2]
data = json.load(open(path))['portrait'][device]
x, y = data['offset'].strip('+').split('+')
print(x, y, data['width'])
" "$FRAME_DEVICE" "$OFFSETS_JSON")"

FRAME_FILE="$FRAMES_DIR/Apple ${FRAME_DEVICE} ${FRAME_COLOR}.png"
if [[ ! -f "$FRAME_FILE" ]]; then
  FRAME_FILE="$(ls "$FRAMES_DIR"/"Apple ${FRAME_DEVICE}"*.png 2>/dev/null | head -1)"
fi
if [[ ! -f "$FRAME_FILE" ]]; then
  echo "No frame PNG found for $FRAME_DEVICE ($FRAME_COLOR) in $FRAMES_DIR" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/puzzlebuddy-frame.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "→ Device: $FRAME_DEVICE ($FRAME_COLOR)"
echo "→ Frame: $(basename "$FRAME_FILE")"
echo "→ Slot: +${OFFSET_X}+${OFFSET_Y} (width ${SCREEN_WIDTH}px)"

frame_one() {
  local shot="$1"
  local raw_dir="$2"
  local appearance
  appearance="$(basename "$(dirname "$raw_dir")")"
  local framed_dir="$FRAMED_BASE/iphone/$appearance/portrait"
  local base
  base="$(basename "$shot" .png)"
  local out="$framed_dir/${base}-framed.png"
  local work="$WORK_DIR/prepared.png"

  mkdir -p "$framed_dir"

  read -r SHOT_W SHOT_H <<<"$(magick identify -format "%w %h" "$shot")"
  if [[ "$SHOT_W" -gt "$SHOT_H" ]]; then
    echo "→ Skipping ${base} (landscape — frameit offsets are portrait-only)"
    return 0
  fi

  echo "→ Framing iphone/$appearance/portrait/${base}..."
  if [[ "$SHOT_W" -ne "$SCREEN_WIDTH" ]]; then
    magick "$shot" -resize "${SCREEN_WIDTH}x" "$work"
    read -r SHOT_W SHOT_H <<<"$(magick identify -format "%w %h" "$work")"
  else
    cp "$shot" "$work"
  fi

  if [[ "$ROUND_RADIUS" -gt 0 ]]; then
    magick "$work" -alpha set \
      \( -size "${SHOT_W}x${SHOT_H}" xc:none \
          -draw "roundrectangle 0,0,$((SHOT_W - 1)),$((SHOT_H - 1)),${ROUND_RADIUS},${ROUND_RADIUS}" \) \
      -compose DstIn -composite "$work"
  fi

  magick "$FRAME_FILE" "$work" \
    -geometry "+${OFFSET_X}+${OFFSET_Y}" -compose DstOver -composite \
    PNG32:"$out"
}

if [[ -n "${RAW_DIR:-}" ]]; then
  if [[ ! -d "$RAW_DIR" ]] || [[ -z "$(ls -A "$RAW_DIR"/*.png 2>/dev/null)" ]]; then
    echo "No raw screenshots in $RAW_DIR." >&2
    exit 1
  fi
  for shot in "$RAW_DIR"/*.png; do
    frame_one "$shot" "$RAW_DIR"
  done
else
  found=0
  for raw_dir in "$MARKETING_BASE/iphone"/{dark,light}/portrait; do
    [[ -d "$raw_dir" ]] || continue
    shopt -s nullglob
    pngs=("$raw_dir"/*.png)
    [[ ${#pngs[@]} -gt 0 ]] || continue
    found=1
    for shot in "${pngs[@]}"; do
      frame_one "$shot" "$raw_dir"
    done
  done
  if [[ "$found" -eq 0 ]]; then
    echo "No portrait iPhone screenshots under $MARKETING_BASE/iphone/{dark,light}/portrait." >&2
    echo "Run ./Scripts/capture-marketing-screenshots.sh first." >&2
    exit 1
  fi
fi

echo ""
echo "Done. Framed screenshots:"
find "$FRAMED_BASE" -name '*-framed.png' | sort
echo ""
echo "App Store Connect: upload iphone|ipad/{dark,light}/{portrait,landscape}/ files only (no bezels)."
