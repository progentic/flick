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
