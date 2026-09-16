# Testing

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active

Changed behavior must have tests at the lowest level that reliably proves the
contract.

Use:

- unit tests for local behavior;
- integration tests for package/persistence/process boundaries;
- end-to-end tests for critical workflows;
- negative controls for idempotency, authorization, validation, recovery, and
  security boundaries.

## v0.0.0

No application tests are claimed to exist.

Historical test logs are not evidence for this baseline.

## v0.0.1

Package tests must actually execute on the validated Swift toolchain. A package
that fails manifest resolution has not passed testing.

Do not use a test whose only meaningful assertion is equivalent to `true` as a
milestone gate.

### Current commands

- `python3 -m unittest discover -s scripts/tests -v`: governance regression and
  negative controls in disposable repositories.
- `bash scripts/repo-enforce.sh --base origin/main`: portable structural checks.
- `bash scripts/ui-enforce.sh --base origin/main`: UI applicability/evidence gate.
- `bash scripts/validate-packages.sh`: actual manifest evaluation, dependency
  resolution, module compilation, and behavior tests on macOS.
- `git diff --check` and `for script in scripts/*.sh; do bash -n "$script"; done`: whitespace and shell syntax.

FlickDomain's current tests validate data contracts, not persistence. Scaffold
packages have no behavior test target; their build/import checks must pass and
their behavior tests are NOT_APPLICABLE. The app-build step is NOT_APPLICABLE
until `App/Flick.xcodeproj` exists. Historical pipeline stubs are archived rather
than counted as storage/recovery evidence. No app, database, cross-process,
performance, visual, or external-delivery evidence is claimed at bootstrap.

Codable formats are internal pre-release formats. There is no installed app
store/schema to migrate at this stage. The 0.1.0 persistence slice must define
schema versions and migration rules before these values become durable user data.

## Critical future negative controls

- kill after durable capture, before processing;
- kill during processing;
- retry same downstream output key;
- same ingress request ID replayed where supported;
- two independent identical-content captures remain distinct;
- ambiguous EventKit external save does not auto-duplicate;
- denied permissions do not destroy local capture;
- model unavailable does not block capture.

## v0.1.0 candidate

- `bash scripts/validate-packages.sh` evaluates all manifests, builds all modules,
  runs applicable unit/integration tests, and builds the real signed simulator app.
- `bash scripts/test-ios.sh SIMULATOR_UUID` executes the shared Flick scheme's
  native UI tests. The script can select an available iOS 26+ iPhone simulator
  when no UUID is given. It fails INCONCLUSIVE when no runtime is installed.
- Runtime tests require ad-hoc simulator signing; an unsigned build does not
  register the App Group. This is not physical-device provisioning.
- CEStorage tests use on-disk SwiftData stores, reopen them, and exercise actual
  read-only write errors. CEPipelines tests compose those real stores. UI model
  tests use controlled capabilities only to prove presentation ordering; they
  are not counted as persistence evidence.
- Native tests terminate the application after a pending save and after a
  processing claim, then relaunch against the same isolated store. Save delays
  and read-only configuration exercise real state boundaries without fake saved
  rows. Test namespaces and boundary controls are Debug-only and absent in Release.
- App contains composition/lifecycle only, so no redundant application unit-test
  target is added. Package unit/integration tests plus the real app UI suite are
  the applicable tests.
- Native accessibility audits cover contrast, hit regions, descriptions, traits,
  and clipping on the exercised states. Large Dynamic Type, portrait/landscape,
  and high-contrast rendering are exercised separately. These do not substitute
  for human aesthetic approval or claim an audible VoiceOver session occurred.
- The current candidate's tests, screenshots, timing observations, and remaining
  gates are recorded in `verification/v0.1.0/RESULTS.md` and root `UI-REVIEW.md`.
