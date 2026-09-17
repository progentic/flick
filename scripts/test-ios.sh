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
if [[ $# -gt 0 ]]; then shift; fi
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
mkdir -p "$output"
xcrun simctl bootstatus "$device" -b
fixture="$(mktemp -d /tmp/flick-appearance.XXXXXX)"
python3 "$root/scripts/ui_appearance_fixture.py" "$device" "$fixture" > "$output/appearance-fixture.log" 2>&1 &
fixture_pid=$!
cleanup_fixture() {
  kill "$fixture_pid" 2>/dev/null || true
  wait "$fixture_pid" 2>/dev/null || true
  rm -rf "$fixture"
}
trap cleanup_fixture EXIT
export TEST_RUNNER_FLICK_APPEARANCE_FIXTURE="$fixture"
{
  git -C "$root" rev-parse HEAD
  shasum -a 256 "$root/App/FlickUITests/FlickUITests.swift"
  printf 'selected_simulator=%s\n' "$device"
  xcodebuild -version
  swift --version
  xcrun simctl list devices available -j
  xcrun simctl list runtimes -j
} > "$output/environment.txt" 2>&1
xcodebuild -project "$root/App/Flick.xcodeproj" -scheme Flick \
  -destination "platform=iOS Simulator,id=$device" -derivedDataPath "$output/build" \
  -parallel-testing-enabled NO -resultBundlePath "$output/Flick.xcresult" -collect-test-diagnostics never \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES test "$@" 2>&1 | tee "$output/xcodebuild.log"
