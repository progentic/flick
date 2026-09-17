# UI test synchronization repair

## Scope and root cause

Parent candidate: `c279cc339889961747a462f1a9d6b1a2b846e2ad`.
Its [hosted run](https://github.com/progentic/flick/actions/runs/35164427743)
failed with 8/12 UI cases passing. It remains non-releasable.

The hosted log establishes one typing failure without keyboard focus and three
missed `Saved` expectations. Inspection establishes that the old `enter` helper
waited only for existence, although CEUI disables its editor during initial
loading/saving. The log does not establish that a capture was lost.

`waitForSaved` incorrectly synchronized five persistence-oriented scenarios:
capture/relaunch/delete, independent identical captures, post-save recovery,
post-claim recovery, and processing-failure recovery. A two-second presentation
state cannot establish a durable boundary. All five uses are removed.

## Changes

Only `App/FlickUITests/FlickUITests.swift` changes executable code:

- `focusEditorAndType` waits for existence, enabled state and hittability, taps
  the identified editor, then waits for the focus-driven native Done control
  and keyboard before typing. It verifies the entered value. No autofocus or
  coordinate tap is added to the application or harness.
- `waitForNoteReady` observes committed capture/output records and exact visible
  note counts. Identical independent requests must yield two distinct capture
  IDs, two note IDs, two output keys, and matching provenance, including after
  relaunch.
- `waitForPersistedBoundary` observes exactly one matching original capture in
  `pending` or `processing`, with zero outputs, while the existing `after-save`
  or `after-claim` hook holds the real pipeline. Termination therefore occurs
  at the intended durable boundary, independent of transient feedback.
- `waitForRecoveredNote` compares the original capture ID/text and output's
  source ID, requiring exactly one capture/output. The post-claim test compares
  note ID and output key again after a second relaunch.
- The existing saving test retains its pre-write termination/no-false-success
  check and adds a focused `Saving… → Saved → Save Note` sequence. A test-side
  SQLite writer reservation holds the real write until Saving is observed;
  releasing it permits the actual save. The test verifies zero committed
  captures before release and one at acknowledgement. The Saved expectation
  keeps a five-second timeout; the product's two-second duration is untouched.
- Ambiguous `firstMatch` queries become unique-element queries where one element
  is required. Accessibility audits, exact counts, all 12 test methods, crash
  hooks and the complete hosted acceptance workflow remain enabled.

### Test-only observation boundary

The probe resolves only the UUID-isolated test store beneath the Simulator's
shared App Group directory. Ordinary reads use `SQLITE_OPEN_READONLY`, opening
fresh connections to observe committed Schema V1 records, not cached app models.
SQL/schema errors throw and fail the test; they are never converted to passing
state. The acknowledgement writer reservation uses an empty `BEGIN IMMEDIATE`
transaction and closes/rolls it back without any INSERT, UPDATE, DELETE or DDL.
All capture/output data still comes through the real UI and production save path.

This probe is deliberately Simulator/Schema V1 specific. A schema change must
update it explicitly. It is not evidence for production multi-writer support.
No package dependency, project configuration, application source, production
focus/timing, persistence behavior, or approved screenshot is changed.

## Invariant mapping (sources inspected before implementation)

| Task invariant | Existing authority | Protection in this repair |
|---|---|---|
| I1 durable-before-success | [UI-014](../../UI_INVARIANTS.md), [FLK-001](../../INVARIANTS.md), [DESIGN §6](../../../DESIGN.md) | Real writer reservation; zero before release, one committed capture when Saved appears |
| I2 no false success | UI-014; DESIGN §6 | Existing failed-write and pre-write-termination assertions remain |
| I3 draft retention | DESIGN §6, save-failed state | Existing read-only failure/retry test still asserts the exact draft text |
| I4 independent identical captures | FLK-006; [Architecture, implemented capture boundary](../../ARCHITECTURE.md) | Exactly two distinct capture/note IDs and output keys before/after relaunch |
| I5 post-save recovery | FLK-001/002; Architecture, Failure Boundaries | Observe committed pending record before termination; preserve its ID/text after relaunch |
| I6 no duplicate output | FLK-003/004/005; Architecture, Failure Boundaries | Observe committed processing record; require one output with matching provenance and stable output identity/key across relaunches |
| I7 no fake success | [Testing, v0.1.0 candidate](../../TESTING.md); `App/Flick/FlickApp.swift` DEBUG configuration | Existing real pause/read-only hooks remain; no fixture rows or synthetic success inserted |
| I8 unchanged production behavior | Explicit repair task; REPO-008; UI-009/014 | Only UI test code changes; no production focus/timing/state modification |
| I9 unchanged approval | [Governance, UI evidence](../../GOVERNANCE.md); UI-015/016; `scripts/governance.py:208` | Original source fingerprint and all 18 approved screenshot hashes verified unchanged |
| I10 state rather than time | Explicit repair task; REPO-007/008 | Bounded XCTest predicates observe readiness, committed rows or actual feedback; no timing padding |

## Antipattern and negative-pattern review

| Pattern | Result |
|---|---|
| Transient label used for persistence/recovery | Absent. Only the focused acknowledgement helper waits for Saved. Persistent row-status copy checks remain secondary UI assertions. |
| Timing-only synchronization | No sleep/usleep/asyncAfter added; all waits have observable predicates. Existing 120-second DEBUG boundary holds remain unchanged, and tests observe state rather than wait for their timers. |
| Product changes for tests | None. No longer Saved duration, autofocus, or new app test controls. |
| Fake persistence | None. Probe reads records; empty writer reservation never seeds or edits them. |
| Weakened assertions | None. Exact one/two assertions retained and extended to IDs, keys and provenance. |
| Recovery without original identity | Removed: both recovery tests compare the original committed capture ID/text. |
| Duplicate masking | Exact store and UI counts; post-claim recovery also verifies stable output identity/key on a second relaunch. |
| Test-order dependence | Each case receives a fresh `FLICK_TEST_STORE` UUID; relaunches reuse only that case's namespace. |
| Unstable firstMatch selection | No firstMatch remains; stable editor/button identifiers and exact query counts are used. |
| Production-visible test state | None added. Probe and lock live in the UI-test bundle only. |

No global retry, test skipping/filtering in CI, expected-failure marking,
accessibility suppression, assertion warning, dependency update, or production
storage/idempotency change was introduced. Existing landscape coordinate drags
are unchanged scrolling actions, not new coordinate taps.

## Local validation (executed in order)

Toolchain: Xcode 27.0 (27A266a), Swift 6.4. Runtime: iPhone 17 Simulator,
iOS 26.5 (23F77). Requirements remain Swift tools 6.3, Swift 6 mode, iOS 26.

| Check | Result | Evidence |
|---|---|---|
| UI target build-for-testing | PASS | `/tmp/flick-sync-build.log` |
| Dark Mode test individually | PASS | 12.988 seconds; matching `/tmp/flick-sync-testDarkFeedAndAccessibilityAudit.xcresult` |
| Identical captures individually | PASS | 24.640 seconds; `/tmp/flick-sync-testIndependentSameTextCreatesTwoNotes.xcresult` |
| Post-save recovery individually | PASS | 16.743 seconds; `/tmp/flick-sync-testKillAfterDurableSaveBeforeProcessing.xcresult` |
| Post-claim recovery individually | PASS | 22.105 seconds; `/tmp/flick-sync-testKillWhileProcessingRecoversWithoutDuplicate.xcresult` |
| Four formerly failing tests together | PASS, 4/4 | `/tmp/flick-sync-four.xcresult` |
| Focused acknowledgement test | PASS | `/tmp/flick-sync-ack.xcresult`; actual writer reservation/release verified |
| Complete UI suite via repository script | PASS, 12/12 | 247.048 seconds; zero failures, zero skipped; `/tmp/flick-sync-full/Flick.xcresult` |
| Package gates | PASS | 78 tests: Domain 43, Capture 3, Ingestion 2, Storage 13, Pipelines 5, CEUI 12; all eight packages resolve/build |
| App build | PASS | `/tmp/flick-sync-packages/app.log` |
| Repository and UI governance | PASS | Source/import/inventory checks and unchanged explicit human approval |
| Governance negative controls | PASS, 16 tests | `/tmp/flick-sync-governance-tests.log` |
| Workflow/shell/whitespace | PASS | actionlint, shellcheck, bash syntax, git diff --check |
| Hosted exact-candidate gate | INCONCLUSIVE at record creation | Requires the new commit/push and complete hosted run; local results alone do not establish release acceptance |

Commands (all from the repository root):

```sh
xcodebuild -project App/Flick.xcodeproj -scheme Flick \
  -destination 'platform=iOS Simulator,id=FE3A294E-802E-4B5A-A4A7-57928DE57074' \
  -parallel-testing-enabled NO -derivedDataPath /tmp/flick-sync-build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build-for-testing
# Individual and grouped runs use test-without-building with -only-testing
# selectors for the four named cases and separate resultBundlePath values.
# The focused acknowledgement test uses test with its single selector.
FLICK_UI_TEST_DIR=/tmp/flick-sync-full bash scripts/test-ios.sh FE3A294E-802E-4B5A-A4A7-57928DE57074
FLICK_VALIDATION_DIR=/tmp/flick-sync-packages bash scripts/validate-packages.sh
bash scripts/repo-enforce.sh --base c279cc339889961747a462f1a9d6b1a2b846e2ad
bash scripts/ui-enforce.sh --base c279cc339889961747a462f1a9d6b1a2b846e2ad
python3 -m unittest discover -s scripts/tests -v
actionlint
shellcheck scripts/*.sh
for script in scripts/*.sh; do bash -n "$script"; done
git diff --check
```

The full run has no `only-testing`, skip, or retry flags. Focused selections are
local triage only. The full-run directory reuses the local build cache through
a temporary symlink; this changes neither project settings nor test selection.
Temporary logs/bundles are local artifacts. GitHub Actions must run the complete
suite for the exact pushed SHA; no tag or release is authorized by this repair.

## Approved UI

Unchanged fingerprint:
`42ddc9eafa76a54815d03b4a3849995a2dc528c8bba29b9091b9fae1e9975dae`.

`.ui-evidence.json`, application/CEUI source, project files, and all 18 approved
renders remain byte-for-byte unchanged. New test attachments do not replace the
approved gallery. No renewed visual approval is needed for this harness-only edit.
