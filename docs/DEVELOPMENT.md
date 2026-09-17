# Developing Flick

Flick is a native iOS app. For current implementation status, verification
results, and open acceptance gates, see [Repository state](REPOSITORY_STATE.md)
and [Candidate results](verification/v0.1.0/RESULTS.md).

## Requirements

- macOS with a compatible Xcode installation and an iOS 26+ iPhone simulator.
- Swift 6 language mode and Swift tools 6.3 or newer for package manifests.
- Git and Python 3 for repository checks.

The installed toolchain may be newer than these requirements. Record the actual
versions used; installed tooling alone does not prove a build or test passed.

## Run and test

Run these commands from the repository root. Replace `SIMULATOR_UUID` with an
available iPhone simulator identifier from the first command.

```sh
xcrun simctl list devices available
bash scripts/run-ios.sh SIMULATOR_UUID
bash scripts/test-ios.sh SIMULATOR_UUID
bash scripts/validate-packages.sh
```

Simulator runs use ad-hoc signing to register App Group entitlements. Physical
device provisioning requires the owner's Apple development team. These scripts
do not configure an Apple account or distribution settings.

## Repository checks

```sh
bash scripts/repo-enforce.sh --base origin/main
bash scripts/ui-enforce.sh --base origin/main
python3 -m unittest discover -s scripts/tests -v
git diff --check
```

After intentional file changes, regenerate the inventory with
`bash scripts/repo-enforce.sh --inventory-write`.

Read [AGENTS.md](../AGENTS.md) before changing implementation or governance.
See [Architecture](ARCHITECTURE.md), [Testing](TESTING.md),
[Design](../DESIGN.md), and [the documentation index](README.md) for the
project's technical contracts and design rules.

## UI test fixtures and failure evidence

Use `scripts/test-ios.sh` to run UI tests. It starts a local, event-driven helper
that applies simulator appearance with `simctl` and acknowledges the observed
setting. The test runner verifies the selected simulator, then measures the
app-owned canvas; the app contains no testing appearance override. Direct Xcode
UI-test execution without this fixture fails with a setup message.

For local triage, pass Xcode selectors after the device UUID, for example
`bash scripts/test-ios.sh SIMULATOR_UUID -only-testing:FlickUITests/FlickUITests/testDarkFeedAndAccessibilityAudit`.
The hosted gate passes no selectors and runs all 12 tests. Each case selects its
appearance and normal text size explicitly; the accessibility-size case overrides
only its own launch argument.

Hosted runs retain the `.xcresult`, execution log, simulator/runtime/toolchain
metadata, and appearance acknowledgements for seven days, including failures.
Canvas attachments include the complete app screenshot, sampled region, bounds,
RGB statistics, reported device appearance and available size-class attributes.
Public XCTest does not expose the app's actual color-scheme trait; the rendered
region is the appearance assertion's evidence. Light Mode is a negative control
for the same Dark Mode predicate.
