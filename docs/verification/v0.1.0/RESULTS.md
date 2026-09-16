# v0.1.0 Text Flick — candidate handoff

Date: 2026-09-16

## Outcome

The local text-capture application is implemented and visually approved by the owner.
It saves a Capture before acknowledging success, displays persisted chronological
state, creates one local Note, recovers interrupted work, supports safe retry,
and deletes the owned Capture/Note relationship together.

**v0.1.0 remains unaccepted.** Human visual approval is PASS for the recorded
fingerprint. Hosted CI on an authorized candidate commit remains INCONCLUSIVE. No current application commit, push,
tag, release, external repository setting change, or ADR acceptance occurred.

## Focused state revision

- `Save Note` → `Saving…` → brief `Saved`; save failure shows `Try again` and
  "Couldn't save note. Your text is still here." Ember focus and semantic error
  tokens distinguish states without coloring the whole interface.
- Feed rows own processing spinners and failure/retry controls. Retrying unfinished
  durable work uses recovery; only persisted failed rows take the failed→pending transition.
- Accessibility sizes remove the headline, expand the editor, and use an inline,
  single-line `Save` action in the scrolling composer.
- Failure diagnostics identify the operation, opaque capture/output, state/stage,
  scoped attempt, duration, recovery and safe error taxonomy. No descriptions,
  paths or capture content are serialized. Storage `state` is the observed model
  context snapshot (potentially an in-flight mutation), and `expected_state` is
  the operation precondition; neither claims a committed disk read. See [diagnostic samples](diagnostics.json).
- Keyboard dismissal uses native navigation-toolbar `Done`, keeping the floating
  keyboard accessory away from the capture action. Schema, package graph and
  deployment requirements are unchanged. Native back navigation is preserved.

### Revision ownership

| Files | Responsibility |
|---|---|
| CEUI `CaptureScreenModel`, `TextFlickView`, `FlickStartupView`, palette/tokens | Short copy, transient save feedback, row-owned recovery controls, adaptive layout and semantic error colors |
| `CaptureCoordinator`, `TextStore`, `TextKernel`, app composition | Record technical failures at the operation that failed; preserve existing throw/rollback/recovery semantics |
| Domain `FailureDiagnostic`; storage/ingestion error declarations | Safe diagnostic data/serialization and static error reasons |
| Domain/CEUI unit tests and `FlickUITests` | Redaction, state expiry, retry ownership, capture disabling, actual native render/audit evidence |
| `.repo-policy.json`, design/security/architecture/review docs and evidence | Permit OSLog in its owning packages, record the implemented contract and explicit owner approval |

## Starting point and preserved work

- Root: `/Users/godzilla/Documents/Projects/flick`, independent repository.
- Base and unchanged HEAD: `f802005ad49e9b3074cbc2bc35d6212dedc2ade8` on `main`.
- The user-supplied ROADMAP revision and CHANGELOG were present at task start.
  Roadmap prose was preserved; only Markdown hard-break whitespace was normalized.
  Implemented changes were added under `[Unreleased]` in the existing changelog.
- BSD 3-Clause LICENSE remains byte-for-byte unchanged, copyright 2026 Proto.
- The v0.0.1 tag is absent locally and on GitHub. The remote check explicitly
  selected/verified the progentic login and received a 404 for that tag.
- Bootstrap hosted success is historical baseline evidence only. It was not used
  as proof that this uncommitted application candidate passes hosted CI.

## Phase status

| Phase | Local status | Evidence and remaining boundary |
| --- | --- | --- |
| A — application foundation | PASS for implementation/automated checks | Real target/shared scheme, simulator launch, native entry/feed/error states, explicit Automatic appearance, adaptive tokens, native audits; human aesthetic approval is recorded under Phase E |
| B — schema and durable queue | PASS | Versioned disk SwiftData schema, explicit saves, 13 real-store tests, rollback on actual read-only failures |
| C — text vertical slice | PASS | CaptureCoordinator → explicit save → persisted feed → actor pipeline → Note; no semantic classification; UI and integration tests |
| D — recovery and performance | PASS for tested simulator scope | Process termination at pending/processing boundaries, relaunch, duplicate controls, deletion, failure/retry; measured timing below |
| E — human visual approval | PASS | Owner approved the exact fingerprint and 18-image candidate on 2026-09-16 |
| E — hosted candidate CI | INCONCLUSIVE | Candidate commit/push not authorized; no exact-candidate hosted execution yet |

No voice, images, semantic models, task/event processing, extensions, App Intents,
widgets, BackgroundTasks, Spotlight, or CloudKit feature was implemented.

## Actual platforms and requirements

- Local toolchain: Xcode 27.0 (27A266a), Apple Swift 6.4 (swiftlang-6.4.0.34.1).
- Final runtime evidence: iPhone 17 Simulator, iOS 26.5 (23F77).
- Host: Apple M4 Max, macOS 27.0.
- Requirements retained: Swift tools 6.3, Swift 6 language mode, iOS 26 minimum.
- macOS 14 was explicitly added as a host-test minimum for packages using modern
  Apple frameworks; the iOS target was not lowered.
- Bundle/group: `com.progentic.flick` / `group.com.progentic.flick`.
- Runtime simulator builds use ad-hoc signing so the App Group entitlement is
  registered. Device provisioning and distribution signing are not established.

Initial iOS 27 preview checks helped identify issues, but the final gallery and
application acceptance evidence below come from iOS 26.5. The app now explicitly
follows system appearance through
[UIUserInterfaceStyle = Automatic](https://developer.apple.com/documentation/bundleresources/information-property-list/uiuserinterfacestyle).
A pixel assertion verifies that a supposedly dark run really renders a dark
canvas. Mode-setting success alone is not treated as visual evidence.

## Validation results

| Gate | Status | Observed result |
| --- | --- | --- |
| Eight manifests/dependency resolution | PASS | Every evaluated manifest resolves; no absent dependency or cycle |
| Eight package builds | PASS | Foundation-only domain and owning-package framework boundaries retained |
| FlickDomain | PASS | 43 executed tests |
| CECapture | PASS | 3 executed tests |
| CEIngestion | PASS | 2 executed tests |
| CEStorage | PASS | 13 executed on-disk integration tests |
| CEPipelines | PASS | 5 tests composing real disk storage, including failure isolation and overlapping drains |
| CEUI | PASS | 12 state/contrast tests; controlled-capability tests prove presentation ordering, not database behavior |
| CESemantic / CEOutput behavior tests | NOT_APPLICABLE | Deferred scaffold/interface packages, still compiled |
| Application UI suite | PASS | 12 cases across the final-source suite and corrected transient-Saved observation rerun |
| Native accessibility | PASS for exercised states | Contrast, hit regions, descriptions, traits, clipping; Light/Dark and error states; 2 additional Increase Contrast audits |
| Debug simulator app build | PASS | Built and launched with real App Group storage |
| Release simulator app build | PASS | Executable contains none of the four FLICK_TEST_* control keys |
| Repository governance | PASS | Structural, metadata, dependency/import, inventory/checksum and CI source controls |
| Governance negative controls | PASS | 16 tests, including stale screenshots/source and missing human approval |
| UI governance | PASS | Current source/render hashes and explicit owner approval match |
| Workflow/shell/whitespace checks | PASS | actionlint, ShellCheck, bash syntax, git diff --check, and nonignored untracked text whitespace |
| Hosted macOS application CI | INCONCLUSIVE | Workflow path added; candidate commit/push is not authorized, so no new hosted run exists |
| Physical device / spoken VoiceOver / external keyboard | NOT RUN | Limits of local automated evidence; no claim of manual/device validation |

Total executed package tests: **78**. Native UI cases: **12**, with additional
reruns for accessibility and adaptive evidence. No placeholder test is counted.

### Commands and evidence locations

```sh
FLICK_VALIDATION_DIR=/tmp/flick-state-packages-final bash scripts/validate-packages.sh
python3 -m unittest discover -s scripts/tests -v
bash scripts/repo-enforce.sh --base origin/main
bash scripts/ui-enforce.sh --base origin/main
for script in scripts/*.sh; do bash -n "$script"; done
actionlint
shellcheck scripts/*.sh
git diff --check
```

The final aggregate run revalidated every package after the state/logging changes.
Controlled presentation tests remain separate from real SwiftData integration tests.

Full application command:

```sh
xcodebuild -project App/Flick.xcodeproj -scheme Flick \
  -destination 'platform=iOS Simulator,id=FE3A294E-802E-4B5A-A4A7-57928DE57074' \
  -parallel-testing-enabled NO -derivedDataPath /tmp/flick-state-app \
  -resultBundlePath /tmp/flick-state-ui-toolbar.xcresult \
  -collect-test-diagnostics never CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES test
# Focused corrected observation uses the same command with:
# -only-testing:FlickUITests/FlickUITests/testCaptureRelaunchAndDelete
# -resultBundlePath /tmp/flick-state-ui-saved.xcresult
```

Current local bundles/logs:

- `/tmp/flick-state-ui-toolbar.xcresult`: 11/12 cases passed; the Saved observation
  failed because XCTest resumed after the two-second indicator expired.
- `/tmp/flick-state-ui-saved.xcresult`: corrected capture/relaunch/delete test;
  dismisses the keyboard before saving to observe the real brief acknowledgement.
  No application timing change or fake success was introduced.
- `/tmp/flick-state-ui-toolbar-high.xcresult`: two passing audits with actual Simulator
  Increase Contrast enabled on the exact device; setting restored afterward.
- `/tmp/flick-state-packages-final/`: actual evaluated manifests/build/test logs.
- `/tmp/flick-state-release.log`: successful Release build with
  `-configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'`
  and `-derivedDataPath /tmp/flick-state-release`.

Temporary bundles are local diagnostics. Portable screenshots and accessibility
hierarchies are retained in [the gallery](GALLERY.md), with hashes recorded in
`.ui-evidence.json` and root SHA256SUMS.txt.

## Reliability and ownership proof

- Capture acknowledgement is downstream of an explicit ModelContext.save.
- Schema V1 stores capture text/status/provenance and Note payload/key; pending
  rows are the queue. ModelContext and managed objects stay inside TextStore's
  dedicated ModelActor, constructed away from MainActor.
- Note creation, inverse relationship, and filed state share one explicit save.
  Read-only failures roll back both Note and state. Reopened stores verify outcomes.
- Repeated completion retains the canonical Note ID and one persistent key.
  Independent identical text produces independent Captures/Notes.
- Recovery requeues interrupted processing. Explicit retry accepts failed captures
  only; it cannot reset an active claim. Overlapping drains are coalesced.
- One deterministic ingestion failure does not stop unrelated work. A store write
  failure stops processing while retaining recoverable durable state.
- Capture owns its Note. Deletion cascades; completion after deletion cannot
  resurrect either object. A failed deletion preserves both.
- App tests terminate the process after a durable pending save and after a durable
  processing claim, then relaunch the same store. These are actual app/process
  tests, separate from unit reopen tests and controlled UI-model capabilities.
- The original capture remains accessible from the Note detail. No debug controls
  appear in the user flow. Debug-only test modes use isolated UUID store paths;
  the Release executable was checked for their absence.

## Performance observations

The earlier, pre-state-revision simulator run recorded (historical timing evidence):

| Path | Samples | Median | Range |
| --- | --- | --- | --- |
| First accepted capture after each app launch | 9 | 17.83 ms | 15.97–21.17 ms |
| Subsequent capture in the same process | 1 | 1.88 ms | 1.88 ms |

The clock spans CaptureCoordinator entry (including validation) through a
successful explicit persistence operation. It excludes typing and complete app
startup. These are recent-launch/first-write and warm observations on a simulator,
not a physical-device cold-boot benchmark or a statistical latency guarantee.
All observed values were below the 300 ms SLO; that target is not a correctness
assertion. [Raw non-content timing samples](timing.json) record the context.

## Visual and accessibility review

[UI-REVIEW.md](../../../UI-REVIEW.md) contains the exercised HIG matrix and honest
VoiceOver/keyboard notes. The gallery includes 18 actual renders and matching
native accessibility hierarchies. Largest Dynamic Type uses an inline scrolling Save action and omits the marketing
headline; normal text sizes retain the safe-area action. Native back navigation remains.

Native tests found and drove fixes to disabled-button contrast, multiline labels,
repeated-binding feedback, and appearance configuration. The state revision initially failed the Dark Mode hit-region audit on a status
label. Moving normal row status into the combined navigation label fixed it; the
final run passed without an audit exemption. The toolbar revision also exposed a transient-observation test race: the first
snapshot query ran 2.6 seconds after the tap, beyond the two-second Saved window.
The corrected test dismisses the keyboard before saving and asserts the same
Saved label. Gallery images come from the passing scenario executions. No failed or mislabeled dark image is kept
as current proof.

The owner's visual decision is **VISUAL APPROVAL — PASS**, recorded on 2026-09-16
in [the supplied review](VISUAL-APPROVAL.md). The implementation/design fingerprint is:

`42ddc9eafa76a54815d03b4a3849995a2dc528c8bba29b9091b9fae1e9975dae`

UI governance verifies this fingerprint, screenshot hashes, and the explicit
owner approval. It now passes. Approval came from the owner's review, not from
automated test results.

## Open items and readiness

### Required acceptance gates

1. Authorization for a candidate commit/push, followed by hosted CI passing on
   that exact candidate commit. The workflow calls `scripts/test-ios.sh`, which
   runs the enabled FlickUITests target without test filters (static inspection).
2. Hosted CI must execute the complete final UI suite. If it does not, require
   one final 12/12 aggregate run before release acceptance. The owner accepted
   the corrected focused Saved-observation rerun as sufficient before commit.

### Limits / risks

- Physical-device provisioning and runtime behavior remain unverified.
- This execution environment has the working CoreSimulator/XCTest backend but
  no bundled Simulator.app GUI. Interactive GUI launch was unavailable; use the
  captured gallery or open the project in a full Xcode GUI installation.
- Native accessibility metadata/audits and keyboard automation do not claim a
  spoken VoiceOver session or physical external-keyboard test.
- The warm timing sample is small; device/performance claims require more evidence.
- Shared App Group placement is not multi-process SwiftData proof. That remains
  deferred to 0.3.0. The current app owns one store actor and one coalescing kernel.

No ADR was accepted. No later milestone was started. The v0.0.1 tag remains absent.

### Candidate decision

**Visually approved for the exact recorded candidate.** Overall release acceptance
remains open pending exact-candidate hosted CI. The owner explicitly withheld
commit, push, tag, and release authorization in the visual approval.

Nonblocking follow-ups: privacy-mark or hash long-lived diagnostic identifiers
before production; remove/clarify the duplicate Note detail heading in later
polish; inspect initial and scrolled landscape positions on a physical device.
See [UI-REVIEW.md](../../../UI-REVIEW.md).

Proposed commit message:

```text
feat(kernel): Add durable text capture

WHAT: Add the native text app, schema V1, Note pipeline, and recovery tests.

WHY: Deliver the first usable capture flow with explicit durable-save semantics.

HOW IMPROVED: Keep persistence actor-isolated and verify the UI against real stores.
```

## Changelog summary

[Unreleased] records the actual app/scheme, disk schema, recovery and deletion,
text coordinator/ingestion/pipeline, persisted feed/failure UX, adaptive colors,
UI/integration tests, timing telemetry, and signed simulator validation scripts.
It contains no implemented claim for voice, semantics, EventKit, or system surfaces.

## Exact files changed during this task

Compared with a hash snapshot taken before implementation, preserving the owner's
pre-existing ROADMAP/CHANGELOG work. Full checkout inventory is MANIFEST.txt.

### Added

- `.ui-evidence.json`
- `Packages/FlickDomain/Sources/FlickDomain/Errors/FailureDiagnostic.swift`
- `Packages/FlickDomain/Tests/FlickDomainTests/FailureDiagnosticTests.swift`
- `docs/verification/v0.1.0/diagnostics.json`
- `docs/verification/v0.1.0/ui/16-saved.png`
- `docs/verification/v0.1.0/ui/16-saved-accessibility.txt`
- `App/Flick.xcodeproj/project.pbxproj`
- `App/Flick.xcodeproj/xcshareddata/xcschemes/Flick.xcscheme`
- `App/Flick/Flick.entitlements`
- `App/Flick/FlickApp.swift`
- `App/FlickUITests/FlickUITests.swift`
- `Packages/CECapture/Sources/CECapture/CaptureCoordinator.swift`
- `Packages/CECapture/Tests/CECaptureTests/CaptureCoordinatorTests.swift`
- `Packages/CEIngestion/Sources/CEIngestion/TextIngestion.swift`
- `Packages/CEIngestion/Tests/CEIngestionTests/TextIngestionTests.swift`
- `Packages/CEPipelines/Sources/CEPipelines/TextKernel.swift`
- `Packages/CEPipelines/Tests/CEPipelinesTests/TextKernelTests.swift`
- `Packages/CEStorage/Sources/CEStorage/TextKernelStoring.swift`
- `Packages/CEStorage/Sources/CEStorage/TextSchemaV1.swift`
- `Packages/CEStorage/Sources/CEStorage/TextStore.swift`
- `Packages/CEStorage/Sources/CEStorage/TextStoreLocation.swift`
- `Packages/CEStorage/Tests/CEStorageTests/TextStoreTests.swift`
- `Packages/CEUI/Sources/CEUI/CaptureActions.swift`
- `Packages/CEUI/Sources/CEUI/CaptureScreenModel.swift`
- `Packages/CEUI/Sources/CEUI/FlickColorTokens.swift`
- `Packages/CEUI/Sources/CEUI/FlickPalette.swift`
- `Packages/CEUI/Sources/CEUI/FlickStartupView.swift`
- `Packages/CEUI/Sources/CEUI/TextFlickView.swift`
- `Packages/CEUI/Tests/CEUITests/CaptureScreenModelTests.swift`
- `Packages/CEUI/Tests/CEUITests/ColorContrastTests.swift`
- `Packages/FlickDomain/Sources/FlickDomain/Capture/CaptureFeedItem.swift`
- `Packages/FlickDomain/Sources/FlickDomain/Capture/TextKernelState.swift`
- `docs/verification/v0.1.0/GALLERY.md`
- `docs/verification/v0.1.0/RESULTS.md`
- `docs/verification/v0.1.0/timing.json`
- `docs/verification/v0.1.0/ui/01-empty-light-accessibility.txt`
- `docs/verification/v0.1.0/ui/01-empty-light.png`
- `docs/verification/v0.1.0/ui/02-text-entry-accessibility.txt`
- `docs/verification/v0.1.0/ui/02-text-entry.png`
- `docs/verification/v0.1.0/ui/03-note-ready-accessibility.txt`
- `docs/verification/v0.1.0/ui/03-note-ready.png`
- `docs/verification/v0.1.0/ui/04-durable-pending-accessibility.txt`
- `docs/verification/v0.1.0/ui/04-durable-pending.png`
- `docs/verification/v0.1.0/ui/05-processing-accessibility.txt`
- `docs/verification/v0.1.0/ui/05-processing.png`
- `docs/verification/v0.1.0/ui/06-save-failure-retry-accessibility.txt`
- `docs/verification/v0.1.0/ui/06-save-failure-retry.png`
- `docs/verification/v0.1.0/ui/07-saving-accessibility.txt`
- `docs/verification/v0.1.0/ui/07-saving.png`
- `docs/verification/v0.1.0/ui/08-open-failure-accessibility.txt`
- `docs/verification/v0.1.0/ui/08-open-failure.png`
- `docs/verification/v0.1.0/ui/09-dark-accessibility-size-accessibility.txt`
- `docs/verification/v0.1.0/ui/09-dark-accessibility-size.png`
- `docs/verification/v0.1.0/ui/10-dark-feed-accessibility.txt`
- `docs/verification/v0.1.0/ui/10-dark-feed.png`
- `docs/verification/v0.1.0/ui/11-processing-failure-accessibility.txt`
- `docs/verification/v0.1.0/ui/11-processing-failure.png`
- `docs/verification/v0.1.0/ui/12-light-accessibility-audit-accessibility.txt`
- `docs/verification/v0.1.0/ui/12-light-accessibility-audit.png`
- `docs/verification/v0.1.0/ui/13-landscape-accessibility.txt`
- `docs/verification/v0.1.0/ui/13-landscape.png`
- `docs/verification/v0.1.0/ui/14-large-type-feed-accessibility.txt`
- `docs/verification/v0.1.0/ui/14-large-type-feed.png`
- `docs/verification/v0.1.0/ui/15-note-original-capture-accessibility.txt`
- `docs/verification/v0.1.0/ui/15-note-original-capture.png`
- `docs/verification/v0.1.0/ui/high-contrast-10-dark-feed-accessibility.txt`
- `docs/verification/v0.1.0/ui/high-contrast-10-dark-feed.png`
- `docs/verification/v0.1.0/ui/high-contrast-12-light-accessibility-audit-accessibility.txt`
- `docs/verification/v0.1.0/ui/high-contrast-12-light-accessibility-audit.png`
- `scripts/run-ios.sh`
- `scripts/test-ios.sh`

### Modified

- `.github/workflows/packages.yml`
- `.repo-policy.json`
- `AGENTS.md`
- `CHANGELOG.md`
- `DESIGN.md`
- `Packages/CECapture/Package.swift`
- `Packages/CEIngestion/Package.swift`
- `Packages/CEPipelines/Package.swift`
- `Packages/CEStorage/Package.swift`
- `Packages/CEUI/Package.swift`
- `Packages/FlickDomain/README.md`
- `README.md`
- `SECURITY.md`
- `UI-REVIEW.md`
- `docs/ARCHITECTURE.md`
- `docs/DEPENDENCIES.md`
- `docs/GOVERNANCE.md`
- `docs/README.md`
- `docs/REPOSITORY_STATE.md`
- `docs/ROADMAP.md`
- `docs/TESTING.md`
- `scripts/governance.py`
- `scripts/tests/test_governance.py`
- `scripts/validate_packages.py`
- `MANIFEST.txt`
- `SHA256SUMS.txt`
