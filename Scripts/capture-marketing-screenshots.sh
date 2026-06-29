#!/usr/bin/env bash
# Capture App Store marketing screenshots from the iOS Simulator.
#
# Usage:
#   ./Scripts/capture-marketing-screenshots.sh              # dark, iPhone 17 Pro, portrait + landscape
#   APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh
#   SIM_NAME="iPhone 17 Pro Max" ./Scripts/capture-marketing-screenshots.sh
#   ORIENTATIONS=portrait ./Scripts/capture-marketing-screenshots.sh   # portrait only
#
# Output: marketing-screenshots/{iphone|ipad}/{dark|light}/{portrait|landscape}/*.png
# Then run: ./Scripts/frame-marketing-screenshots.sh
#
# App Store 6.5" slot requires 1284×2778 or 1242×2688 (portrait) and matching landscape sizes.
# iPhone 17 Pro captures 1206×2622 portrait; set APP_STORE_RESIZE=0 to keep native pixels.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=app-store-screenshot-size.sh
source "$SCRIPT_DIR/app-store-screenshot-size.sh"
# shellcheck source=simulator-orientation.sh
source "$SCRIPT_DIR/simulator-orientation.sh"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
APPEARANCE="${APPEARANCE:-dark}"
ORIENTATIONS="${ORIENTATIONS:-portrait landscape}"
DEVICE_KIND="${DEVICE_KIND:-iphone}"
MARKETING_BASE="${MARKETING_BASE:-$ROOT/marketing-screenshots}"
BUNDLE_ID="com.jacobrozell.Puzzle-Buddy"
SCHEME="${SCHEME:-PuzzleBuddy}"
PROJECT="$ROOT/PuzzleBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/marketing-screenshots}"
LAUNCH_DELAY="${LAUNCH_DELAY:-6}"
ORIENTATION_SETTLE_SEC="${ORIENTATION_SETTLE_SEC:-1.5}"
APP_STORE_RESIZE="${APP_STORE_RESIZE:-1}"

COMMON_ARGS=(-ui_test_reset -disable_firebase_analytics -ui_testing_seed_puzzles)

slugify() {
  echo "$1" | tr ' ' '-' | tr -d '()' | tr '[:upper:]' '[:lower:]'
}

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME ($APPEARANCE)"
echo "→ Device kind: $DEVICE_KIND"
echo "→ Orientations: $ORIENTATIONS"
echo "→ Output: $MARKETING_BASE/$DEVICE_KIND/$APPEARANCE/{portrait,landscape}"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$ROOT" && xcodegen generate)
fi

CAPTURE_TMP="${TMPDIR:-/tmp}/puzzlebuddy-marketing-capture-$$"
mkdir -p "$CAPTURE_TMP"
trap 'rm -rf "$CAPTURE_TMP"' EXIT

SIM_UDID="$(xcrun simctl list devices available -j | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('name') == name and d.get('isAvailable', True):
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" "$SIM_NAME")"
export SIM_UDID

echo "→ Booting $SIM_NAME ($SIM_UDID)…"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"
xcrun simctl ui "$SIM_UDID" appearance "$APPEARANCE"
xcrun simctl ui "$SIM_UDID" content_size large

echo "→ Building app…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  | xcbeautify --quieter 2>/dev/null || xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/PuzzleBuddy.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app not found at $APP_PATH" >&2
  exit 1
fi

echo "→ Installing app…"
xcrun simctl install "$SIM_UDID" "$APP_PATH"

app_store_resize_png_for_orientation() {
  local path="$1"
  local orientation="$2"
  local width="$APP_STORE_WIDTH"
  local height="$APP_STORE_HEIGHT"

  if [[ "$orientation" == "landscape" ]]; then
    width="$APP_STORE_HEIGHT"
    height="$APP_STORE_WIDTH"
  fi

  verify_screenshot_orientation "$path" "$orientation"

  local w h
  w="$(magick identify -format "%w" "$path")"
  h="$(magick identify -format "%h" "$path")"
  if [[ "$w" == "$width" && "$h" == "$height" ]]; then
    return 0
  fi
  magick "$path" -filter Lanczos -resize "${width}x${height}!" "$path"
}

capture() {
  local slug="$1"
  shift
  local -a args=("$@")

  for orientation in $ORIENTATIONS; do
    local filename="${DEVICE_SLUG}-${slug}.png"
    capture_frame "$filename" "$orientation" "${args[@]}"
  done
}

capture_frame() {
  local filename="$1"
  local orientation="$2"
  shift 2
  local -a args=("$@")
  local out_dir="$MARKETING_BASE/$DEVICE_KIND/$APPEARANCE/$orientation"

  mkdir -p "$out_dir"
  echo "→ Capturing $DEVICE_KIND/$APPEARANCE/$orientation/${filename}..."
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${args[@]}" -snapshot_orientation "$orientation" >/dev/null
  sleep "$LAUNCH_DELAY"
  sleep "$ORIENTATION_SETTLE_SEC"
  local capture_path="$CAPTURE_TMP/$filename"
  xcrun simctl io "$SIM_UDID" screenshot "$capture_path"
  cp "$capture_path" "$out_dir/$filename"
  normalize_screenshot_for_orientation "$out_dir/$filename" "$orientation"
  verify_screenshot_orientation "$out_dir/$filename" "$orientation"
  if [[ "$APP_STORE_RESIZE" == 1 ]]; then
    app_store_resize_png_for_orientation "$out_dir/$filename" "$orientation"
  fi
}

DEVICE_SLUG="$(slugify "$SIM_NAME")"

# App Store priority order — see marketing-screenshots/README.md and docs/release/app-store-connect.md
capture "01-puzzle-list" \
  "${COMMON_ARGS[@]}" -snapshot_tab puzzles

capture "02-duplicate-check" \
  "${COMMON_ARGS[@]}" -snapshot_tab puzzles -snapshot_duplicate_check "Mountain Sunset"

capture "03-collection-stats" \
  "${COMMON_ARGS[@]}" -snapshot_tab stats

capture "04-add-puzzle" \
  "${COMMON_ARGS[@]}" -snapshot_tab puzzles -snapshot_add_puzzle

capture "05-puzzle-detail" \
  "${COMMON_ARGS[@]}" -snapshot_tab puzzles -snapshot_puzzle_detail "Harbor Lights"

capture "06-settings" \
  "${COMMON_ARGS[@]}" -snapshot_tab settings

capture "07-onboarding-welcome" \
  -ui_test_reset -disable_firebase_analytics -snapshot_onboarding

capture "08-onboarding-barcode" \
  -ui_test_reset -disable_firebase_analytics -snapshot_onboarding -snapshot_onboarding_page 1

echo ""
first_png="$(find "$MARKETING_BASE/$DEVICE_KIND/$APPEARANCE" -name '*.png' | sort | head -1)"
echo "Done. Raw screenshots ($(magick identify -format '%wx%h' "$first_png")):"
find "$MARKETING_BASE/$DEVICE_KIND/$APPEARANCE" -name '*.png' | sort
if [[ "$APP_STORE_RESIZE" == 1 ]]; then
  echo "App Store export (portrait): ${APP_STORE_WIDTH}×${APP_STORE_HEIGHT}"
  echo "App Store export (landscape): ${APP_STORE_HEIGHT}×${APP_STORE_WIDTH}"
fi
echo ""
echo "Next: ./Scripts/frame-marketing-screenshots.sh"
