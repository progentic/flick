# Changelog

All notable changes to Flick are recorded in this file.

This changelog describes implemented repository and product changes. Planned
work belongs in `docs/ROADMAP.md`; do not pre-populate release sections with
features that have not been implemented.

The project uses numeric `MAJOR.MINOR.PATCH` product versions and a monotonically
increasing integer build number.

## [Unreleased]

Next development milestone: `0.2.0 — Voice Flick`. No implementation changes yet.

## [0.1.0] - 2026-09-17

**ACCEPTED — Text Flick / Running Kernel.** Annotated tag `v0.1.0` targets
`2ec113ca9ea94092d2a00f38a3280938bc08d17f` and is frozen.

### Changed

- Refine capture into distinct editing, saving, brief saved, and retry states;
  localize processing progress/failure to its feed row and adapt the composer
  layout at accessibility text sizes.
- Add structured, content-free failure diagnostics with operation, identifiers,
  state, scoped attempts, duration, recovery and error taxonomy; test redaction.


### Added

- iOS 26 application target and shared Flick scheme with Swift 6 strict concurrency.
- Native text composer/feed views with durable-save feedback boundaries and accessible failure states.
- Bundle and App Group identifiers reserved for the text kernel.
- Versioned disk-backed SwiftData schema for captures and local Notes, explicit saves,
  interrupted-work recovery, idempotent completion, and cascade deletion.
- Real-store integration tests, including read-only save/rollback failures.
- Text CaptureCoordinator, pass-through ingestion, and an actor-isolated Note pipeline.
- Persisted-change feed refresh and processing/save/load failure retry UI.
- Native UI tests for process termination at durable boundaries, relaunch, independent
  identical text, deletion, no false save feedback, and accessible Light/Dark layouts.
- Adaptive contrast-tested colors and a safe-area capture action that remains reachable
  with the keyboard at accessibility text sizes.
- Non-content capture-to-durable-save timing through OSLog.
- Signed simulator build/run/test entry points and an actual hosted app/UI-test path.
- Application composition now connects capture, persisted feed, retry, and delete capabilities.

### Fixed

- Synchronize editor typing on editable/focused state and persistence/recovery
  assertions on committed records rather than the transient Saved label.
- Verify acknowledged simulator appearance using an app-owned canvas region and
  a real Light negative control; retain hosted diagnostic evidence.

### Verification

- Exact-source hosted governance, package/app build and 78 package tests: PASS.
- Full hosted UI suite: PASS, 12/12, zero failures or skips.
- Human visual approval and approved UI fingerprint: unchanged.
- Native contrast-audit variability remains nonblocking test-infrastructure debt;
  no timestamp-color defect was established and no production styling was changed
  to obtain the final hosted pass.
- See [final verification](docs/verification/v0.1.0/ACCEPTANCE.md).

## [0.0.1] - 2026-09-16

### Added

- Reproducible Flick repository bootstrap baseline.
- Eight Swift package manifests:
  `FlickDomain`, `CECapture`, `CEIngestion`, `CESemantic`, `CEStorage`,
  `CEOutput`, `CEPipelines`, and `CEUI`.
- Forty-one `FlickDomain` tests.
- Repository governance and negative-control tests.
- Hosted GitHub Actions workflows for repository governance and Swift package
  validation.
- Exact-source CI correlation and immutable GitHub Action commit pins.
- Repository policy, architecture, security, release, testing, dependency, and
  UI governance documentation.
- Proposed ADR set covering semantic backends, EventKit permissions, SwiftData
  storage, `FlickDomain`, local-processing data egress, capture-surface
  execution boundaries, and Apple sample-code rulings.
- Apple HIG-native UI contract with Mail and Notes as interaction references.
- CODEOWNERS, Dependabot configuration, pull-request template, editor settings,
  and repository metadata.

### Changed

- Established `FlickDomain` as the canonical domain package.
- Replaced the prior partial-export state with a package graph that resolves and
  builds on the validated toolchains.
- Defined `.pending` captures as the durable queue and separated source
  provenance, ingress request identity, and output idempotency.
- Defined `CEPipelines` as a thin orchestration boundary rather than an owner of
  capture, classification rules, or concrete persistence mechanics.

### Security

- Established the MVP local-processing data-egress property: user capture
  content does not egress to an app-controlled or third-party network service
  during the local capture/processing path.
- Preserved BSD 3-Clause licensing with copyright holder `Proto`.

### Verification

- Bootstrap commit:
  `f802005ad49e9b3074cbc2bc35d6212dedc2ade8`.
- Repository Governance: PASS against the exact bootstrap commit.
- Swift Packages: PASS against the exact bootstrap commit.
- Hosted package validation built all eight packages and passed 41 domain tests.
- Application/UI build: NOT_APPLICABLE for the repository-only bootstrap.
