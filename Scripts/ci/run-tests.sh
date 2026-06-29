#!/usr/bin/env bash
set -euo pipefail

DESTINATION="${1:?destination required}"

PROJECT="${CI_XCODE_PROJECT:-PuzzleBuddy.xcodeproj}"
SCHEME="${CI_XCODE_SCHEME:-PuzzleBuddy}"
LOG_FILE="${CI_XCODE_TEST_LOG:-xcodebuild-test.log}"
PARALLEL_TESTING="${CI_PARALLEL_TESTING:-NO}"

echo "::group::Running tests (without building)"
echo "Scheme: $SCHEME (parallel testing: $PARALLEL_TESTING)"

rm -rf TestResults.xcresult
set -o pipefail
xcodebuild test-without-building \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -parallel-testing-enabled "$PARALLEL_TESTING" \
  -derivedDataPath DerivedData \
  -resultBundlePath TestResults.xcresult \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$LOG_FILE"
echo "::endgroup::"
