#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -d "$root/App/Flick.xcodeproj" ]]; then
  echo 'NOT_APPLICABLE: no application project'
  exit 0
fi
for tool in python3 xcrun xcodebuild; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "INCONCLUSIVE: required tool unavailable: $tool"
    exit 2
  fi
done
device="${1:-}"
if [[ -z "$device" ]]; then
  device="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
choices = [("iOS-26-" in runtime, runtime, device["udid"]) for runtime, devices in data["devices"].items()
           if "iOS-" in runtime and int(runtime.split("iOS-")[-1].split("-")[0]) >= 26
           for device in devices if device["name"].startswith("iPhone") and device.get("isAvailable")]
print(sorted(choices, reverse=True)[0][2] if choices else "")')"
fi
if [[ -z "$device" ]]; then
  echo 'INCONCLUSIVE: no supported iPhone Simulator runtime/device is installed'
  exit 2
fi
output="${FLICK_UI_TEST_DIR:-$(mktemp -d /tmp/flick-ui.XXXXXX)}"
xcodebuild -project "$root/App/Flick.xcodeproj" -scheme Flick \
  -destination "platform=iOS Simulator,id=$device" -derivedDataPath "$output/build" \
  -parallel-testing-enabled NO -resultBundlePath "$output/Flick.xcresult" -collect-test-diagnostics never \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES test
