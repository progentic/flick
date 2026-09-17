# Dark Mode validation discrepancy after synchronization repairs

Base: `840cfb31c76c62a93732db3dee5b7ce4f697c674`.
Status: **INCONCLUSIVE for acceptance**. No production color change is justified
by the evidence recorded here. The two questions below remain separate.

## 1. What did the app render?

The original [hosted run](https://github.com/progentic/flick/actions/runs/35179131737)
retained no artifacts (GitHub API returned `total_count: 0`). Its original PNG and
app traits cannot be recovered. Its log reports an iPhone 17e, iOS 26.5,
Xcode 26.6, and a light single-pixel result of 249. Do not infer the entire hosted
screen from that value alone.

A local full-order reproduction used a newly created and erased iPhone 17e,
iOS 26.5 (23F77), Xcode 27.0 / Swift 6.4. This reproduces the device/runtime
version and order; it does not pretend to match the hosted Xcode/SDK build.
The prefix was capture/relaunch/delete → accessibility-size layout → dark feed
audit. The reported device appearance was Dark (2), but the editor-owned region
was uniformly `(250,250,248)`: mean 249.333, spread 0, fully opaque. The full
screenshot was also light. Thus this local discrepancy was not a status-bar pixel
or antialiased-edge artifact.

- [Reported Dark, rendered Light](diagnostics/dark-mode/reported-dark-rendered-light.png)
- [Actual sampled editor region](diagnostics/dark-mode/light-editor-region.png)

A separate read-only LLDB diagnostic during the reproduced discrepancy showed
window/root-controller overrides 0 (unspecified), while their actual interface
traits and UIScreen were Light (1). The screen's preferred text size was L.
The debugger-assisted execution is diagnostic evidence, not a passing test run.

### Revised appearance evidence

The predicate now samples an 8×8-point region inside the empty editor, below its
placeholder and away from its border. The test checks editor visibility, emptiness,
minimum height, and containment inside editor/app bounds. It retains the exact
app screenshot, cropped region, pixel rectangle, image scale/orientation,
reported device appearance, app state, size classes, launch arguments, simulator
ID, and OS version. The crop and measurement derive from the same screenshot.
Public XCTest does not expose the app's color-scheme trait, so that limitation is
explicit in the metadata.

The Dark predicate requires an opaque, uniform region (brightness spread ≤12)
with mean brightness <80. The same predicate is applied to a real Light screenshot
and must return false; the Light control must independently exceed 200.

An event-driven test-host fixture now calls `simctl ui <device> appearance`, reads
back the selected setting and acknowledges the request UUID. The test checks the
simulator identity and still requires matching app-owned pixels. No app data or
synthetic UI success is injected. No fixed sleeps or test retries are used.

Observed Dark region: `(22,19,16)`, mean 19, spread 0, fully opaque.
Observed Light control: `(250,250,248)`, mean 249.333, spread 0, fully opaque.
Both the positive and negative controls executed successfully.

- [Acknowledged and rendered Dark](diagnostics/dark-mode/acknowledged-dark.png)
- [Dark editor region](diagnostics/dark-mode/dark-editor-region.png)

## 2. Is the timestamp actually low contrast?

The native contrast audit passed in a standalone direct-Dark run on an erased
simulator, then failed in ordered runs despite correct Dark rendering. Explicit
normal text-size isolation and a scoped auditor-trait experiment did not reliably
resolve the result. The unsuccessful trait override was removed; all native audit
categories and error propagation remain unchanged.

The failure identifies the timestamp. Its captured image contains a dominant
background `(22,19,16)` and foreground `(210,201,187)`. Standard sRGB relative
luminance calculation gives this color pair **11.291:1**. The pre-audit timestamp
pixels were identical between two successive screenshots. The native audit's
background screenshot masks out the timestamp; it must not be mistaken for
an app animation or missing production text.

- [Native audit's flagged timestamp image](diagnostics/dark-mode/flagged-timestamp.png)

This does not establish insufficient production contrast. Nor does a single
standalone pass prove the native audit is always correct or the discrepancy is
merely random. Timestamp content changes with time and is another variable.
No `foregroundColor` experiment or other CEUI modification has been made.
A production change would require a deterministic independent reproduction and
new affected visual evidence/approval.

## 3. Local simulator system-process crash

The owner supplied four crash-dialog screenshots on 2026-09-17 (filenames
`Screenshot 2026-09-17 at 17.50.10.png`, `17.50.31.png`, `17.50.43.png`, and
`17.50.54.png`). The displayed report identifies `Family` / `com.apple.family`,
not Flick. It is a background process parented by `launchd_sim`, with
`SimulatorTrampoline` responsible. Its coalition identifies the disposable
investigation simulator `5E766822-9414-49A2-A2D9-317E5BBC9FA5`.

The report's event time is 16:40:03 -0400, not the screenshot capture time.
Termination is `EXC_CRASH (SIGABRT)` / signal 6. The visible exception and
crashed-thread stacks show `+[SpringBoardUI load]`, a Foundation assertion, and
abort during image loading. No Flick frame appears in those displayed stacks.
This establishes a local simulator system-process crash; it does not establish
that Flick crashed, that the crash caused either audit outcome, or that the
hosted Xcode 26.6 runner experienced the same failure.

[Apple Developer Forums](https://developer.apple.com/forums/tags/simulator?page=3)
also lists an Xcode 27 beta Family.app crash report with the same process and
simulator context. This is corroborating incident reporting, not an Apple root
cause determination or proof that the two incidents have identical causes.

Local installed tooling remains Xcode 27.0 (27A266a), Swift 6.4, with iOS 26.5
(23F77) used for this investigation. Xcode 26.6 is not installed in
`/Applications`; a local matched-toolchain reproduction is NOT RUN. The hosted
workflow explicitly selects Xcode 26.6 and records its actual environment.
The owner authorized a diagnostic/test-infrastructure candidate despite the
known local 11/12 result. That authorization does not waive any acceptance gate.
Production `TextFlickView.swift`, color tokens, and app behavior remain unchanged.

## Evidence and gates

| Run/check | Result |
|---|---|
| Original full ordered reproduction with region diagnostics | FAIL, 11/12; actual light canvas in requested-Dark test |
| Acknowledged system appearance, direct Dark launch, fresh standalone audit | PASS |
| Same fixture in full original order | FAIL, 11/12; rendering correct, native timestamp contrast issue |
| Explicit normal text size, three-test prefix | PASS, 3/3 |
| Same text-size fixture, full suite | FAIL, 11/12; native timestamp contrast issue |
| Real Light Mode negative control | PASS; same Dark predicate rejects Light |
| Diagnostic test target build | PASS |
| Packages and app build | PASS; 78 executed package tests, all eight builds/resolution, app build |
| Repository/UI governance and negative controls | PASS; 16 governance tests, unchanged approved fingerprint |
| Auditor trait-context experiment | Not retained; did not reliably resolve full run |
| New hosted candidate | Pending at record creation; owner authorized the diagnostic push on 2026-09-17 while the local full-suite gate remains red |

Local bundles: `/tmp/flick-region-ordered/Flick.xcresult`,
`/tmp/flick-region-clean-dark/Flick.xcresult`,
`/tmp/flick-region-final-order/Flick.xcresult`,
`/tmp/flick-region-font-order/Flick.xcresult`, and
`/tmp/flick-region-acceptance/Flick.xcresult`.

The workflow change retains exact-source xcresults, execution/environment logs,
and simulator appearance acknowledgements for seven days, including failures.
The old hosted screenshot is unavailable; future evidence must not be silently
substituted for that original run.

The production/approved visual fingerprint remains unchanged:
`42ddc9eafa76a54815d03b4a3849995a2dc528c8bba29b9091b9fae1e9975dae`.
The original 18-image gallery and approval record are untouched. These diagnostic
images are separate evidence, not regenerated approval artifacts.

Acceptance still requires exact-candidate hosted governance PASS, package/app
build PASS, and the complete UI suite 12/12 with no skips. No exception, filtered
audit issue, expected failure, tag, or release is part of this investigation.
