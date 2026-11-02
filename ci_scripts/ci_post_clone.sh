#!/bin/sh
# Xcode Cloud clone hook for XcodeGen apps.
# Copy to <repo>/ci_scripts/ci_post_clone.sh and chmod +x.
# Xcode Cloud only runs ci_scripts at the repository root.
set -e
cd "${CI_PRIMARY_REPOSITORY_PATH:-.}"

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

yml=""
# Portable shallow search (macOS CI image has python3 and find).
yml=$(find . -name project.yml -not -path '*/.*' -maxdepth 4 | head -n 1)
if [ -z "$yml" ]; then
  echo "No project.yml; assuming the Xcode project is already in git"
  exit 0
fi

brew install xcodegen

root="$(cd "$(dirname "$yml")" && pwd)"
example="$root/GoogleService-Info.plist.example"
dest="$root/GoogleService-Info.plist"
cp "$example" "$dest"

# A missing or placeholder plist still lets xcodegen run, and the archive
# ships with GA4 off. Fail that path instead of uploading a silent build.
if [ -z "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "error: GOOGLE_SERVICE_INFO_PLIST_BASE64 is not set. Refusing to archive without Firebase." >&2
  exit 1
fi

python3 - "$dest" << 'PY'
import base64, os, pathlib, sys
dest = pathlib.Path(sys.argv[1])
raw = os.environ.get("GOOGLE_SERVICE_INFO_PLIST_BASE64", "")
text = raw.strip()
if text.startswith("<?xml") or text.startswith("<plist"):
    data = text.encode()
else:
    try:
        data = base64.b64decode(text, validate=False)
    except Exception:
        sys.exit("error: GOOGLE_SERVICE_INFO_PLIST_BASE64 is not valid base64")
if b"GOOGLE_APP_ID" not in data or b"REPLACE_WITH" in data:
    sys.exit("error: workflow secret did not decode to a real GoogleService-Info.plist")
dest.write_bytes(data)
print(f"Wrote GoogleService-Info.plist ({len(data)} bytes)")
PY

(cd "$root" && xcodegen generate)
echo "Generated Xcode project from $yml"

# Xcode Cloud will not resolve Swift packages on its own. The generated
# project needs the same pin file a local build already produced.
resolved_src="$root/ci/Package.resolved"
resolved_dest="$root/PuzzleBuddy.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$resolved_src" ]; then
  echo "error: ci/Package.resolved is missing" >&2
  exit 1
fi
mkdir -p "$(dirname "$resolved_dest")"
cp "$resolved_src" "$resolved_dest"
echo "Installed Package.resolved"
