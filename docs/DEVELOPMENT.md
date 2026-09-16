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
