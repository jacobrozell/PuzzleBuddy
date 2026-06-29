#!/usr/bin/env bash
# Regenerate AppIcon + LaunchCrestHero from the splash loading GIF (assembled frame).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIF="$ROOT/App/Resources/splash_loading.gif"
APPICON_DIR="$ROOT/App/Assets.xcassets/AppIcon.appiconset"
HERO_DIR="$ROOT/App/Assets.xcassets/LaunchCrestHero.imageset"
WORK="/tmp/puzzle-buddy-app-icon-$$"

# Fully assembled hold frame (see puzzle-scene.jsx timeline).
GIF_FRAME="${GIF_FRAME:-40}"

# LaunchBackground dark + puzzle-scene stage cream.
BRAND_BG="#0a0d12"
CORNER_RATIO="0.22"

mkdir -p "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick (magick) is required." >&2
  exit 1
fi

if [[ ! -f "$GIF" ]]; then
  echo "Missing $GIF — run Scripts/render-loading-gif.mjs first." >&2
  exit 1
fi

# GIF frames are delta-compressed; coalesce the full animation before picking a scene.
magick "$GIF" -coalesce "$WORK/coalesced.gif"
magick "$WORK/coalesced.gif[$GIF_FRAME]" PNG32:"$WORK/hero-tile.png"

generate_marketing_icon() {
  local size="$1"
  local inner
  inner="$(python3 - <<PY
size = $size
print(int(round(size * 0.86)))
PY
)"
  local radius
  radius="$(python3 - <<PY
inner = $inner
print(int(round(inner * $CORNER_RATIO)))
PY
)"

  magick -size "${size}x${size}" "xc:$BRAND_BG" \
    \( "$WORK/hero-tile.png" -resize "${inner}x${inner}" \
       \( -size "${inner}x${inner}" xc:none \
          -draw "fill white roundrectangle 0,0 $((inner - 1)),$((inner - 1)) ${radius},${radius}" \
       \) -alpha off -compose CopyOpacity -composite \) \
    -gravity center -compose over -composite \
    "$2"
}

generate_marketing_icon 1024 "$APPICON_DIR/ios-marketing.png"

generate_icon_size() {
  local px="$1"
  local out="$2"
  magick "$APPICON_DIR/ios-marketing.png" -resize "${px}x${px}" "$out"
}

generate_icon_size 40  "$APPICON_DIR/icon-20@2x.png"
generate_icon_size 60  "$APPICON_DIR/icon-20@3x.png"
generate_icon_size 58  "$APPICON_DIR/icon-29@2x.png"
generate_icon_size 87  "$APPICON_DIR/icon-29@3x.png"
generate_icon_size 76  "$APPICON_DIR/icon-38@2x.png"
generate_icon_size 114 "$APPICON_DIR/icon-38@3x.png"
generate_icon_size 80  "$APPICON_DIR/icon-40@2x.png"
generate_icon_size 120 "$APPICON_DIR/icon-40@3x.png"
generate_icon_size 120 "$APPICON_DIR/icon-60@2x.png"
generate_icon_size 180 "$APPICON_DIR/icon-60@3x.png"
generate_icon_size 128 "$APPICON_DIR/icon-64@2x.png"
generate_icon_size 192 "$APPICON_DIR/icon-64@3x.png"
generate_icon_size 136 "$APPICON_DIR/icon-68@2x.png"
generate_icon_size 152 "$APPICON_DIR/icon-76@2x.png"
generate_icon_size 167 "$APPICON_DIR/icon-83_5@2x.png"

# In-app static hero (cream tile only — matches GIF / BrandMark clip).
magick "$WORK/hero-tile.png" -resize 132x132 "$HERO_DIR/LaunchCrestHero@1x.png"
magick "$WORK/hero-tile.png" -resize 264x264 "$HERO_DIR/LaunchCrestHero@2x.png"
magick "$WORK/hero-tile.png" -resize 396x396 "$HERO_DIR/LaunchCrestHero@3x.png"

echo "Updated AppIcon + LaunchCrestHero from GIF frame $GIF_FRAME."
