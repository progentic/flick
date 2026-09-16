#!/usr/bin/env bash
set -euo pipefail
device="${1:?Usage: bash scripts/run-ios.sh SIMULATOR_UUID}"
root="$(cd "$(dirname "$0")/.." && pwd)"
build="${FLICK_APP_BUILD_DIR:-/tmp/flick-development}"
xcodebuild -project "$root/App/Flick.xcodeproj" -scheme Flick \
  -destination "platform=iOS Simulator,id=$device" -derivedDataPath "$build" \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
xcrun simctl bootstatus "$device" -b
xcrun simctl terminate "$device" com.progentic.flick 2>/dev/null || true
xcrun simctl install "$device" "$build/Build/Products/Debug-iphonesimulator/Flick.app"
xcrun simctl launch "$device" com.progentic.flick
