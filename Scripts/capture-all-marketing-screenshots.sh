#!/usr/bin/env bash
# Capture the full App Store matrix: iphone + ipad × dark + light × portrait + landscape.
#
# Usage:
#   ./Scripts/capture-all-marketing-screenshots.sh
#   ORIENTATIONS=portrait ./Scripts/capture-all-marketing-screenshots.sh   # skip landscape
#
# Output:
#   marketing-screenshots/iphone/{dark,light}/{portrait,landscape}/
#   marketing-screenshots/ipad/{dark,light}/{portrait,landscape}/

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for appearance in dark light; do
  echo ""
  echo "════════════════════════════════════════"
  echo " iPhone · $appearance"
  echo "════════════════════════════════════════"
  APPEARANCE="$appearance" "$ROOT/Scripts/capture-marketing-screenshots.sh"

  echo ""
  echo "════════════════════════════════════════"
  echo " iPad · $appearance"
  echo "════════════════════════════════════════"
  APPEARANCE="$appearance" "$ROOT/Scripts/capture-ipad-marketing-screenshots.sh"
done

echo ""
echo "Done. Sorted output:"
find "$ROOT/marketing-screenshots/iphone" "$ROOT/marketing-screenshots/ipad" -name '*.png' 2>/dev/null | sort
