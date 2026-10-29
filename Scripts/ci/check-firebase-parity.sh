#!/usr/bin/env bash
# iOS CI checks out this repo at workspace root and Android at PuzzleBuddy-Android/.
# The shared checker expects personal-workspace layout (PuzzleBuddy/ + PuzzleBuddy-Android/).
set -euo pipefail

IOS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ANDROID_ROOT="${IOS_ROOT}/PuzzleBuddy-Android"
if [[ ! -d "$ANDROID_ROOT" ]]; then
  ANDROID_ROOT="${PERSONAL_ROOT:-$HOME/Desktop/personal}/PuzzleBuddy-Android"
fi

if [[ -f "$ANDROID_ROOT/scripts/check-firebase-parity.py" ]]; then
  PY="$ANDROID_ROOT/scripts/check-firebase-parity.py"
elif [[ -f "${PERSONAL_ROOT:-$HOME/Desktop/personal}/DaRules/scripts/check-firebase-parity.py" ]]; then
  PY="${PERSONAL_ROOT:-$HOME/Desktop/personal}/DaRules/scripts/check-firebase-parity.py"
else
  echo "check-firebase-parity.py not found" >&2
  exit 2
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ln -s "$IOS_ROOT" "$WORK/PuzzleBuddy"
ln -s "$ANDROID_ROOT" "$WORK/PuzzleBuddy-Android"
exec python3 "$PY" --root "$WORK" --pair "Puzzle Buddy" "$@"
