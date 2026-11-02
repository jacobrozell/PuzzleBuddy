#!/bin/sh
# Xcode Cloud clone hook for XcodeGen apps.
# Copy to <repo>/ci_scripts/ci_post_clone.sh and chmod +x.
# Xcode Cloud only runs ci_scripts at the repository root.
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

yml=""
# Portable shallow search (macOS CI image has python3 and find).
yml=$(find . -name project.yml -not -path '*/.*' -maxdepth 4 | head -n 1)
if [ -z "$yml" ]; then
  echo "No project.yml; assuming the Xcode project is already in git"
  exit 0
fi

brew install xcodegen
(cd "$(dirname "$yml")" && xcodegen generate)
echo "Generated Xcode project from $yml"
