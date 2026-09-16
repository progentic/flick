# Flick Product Roadmap

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active planning document

## Purpose

This is the rolling plan from the blank `v0.0.0` repository state to the first
production App Store release, `1.0.0`.

The roadmap records intent, sequencing, dependencies, and exit criteria. It is
not a fixed promise of scope or dates. Development evidence may move work
between milestones or require an ADR revision.

## Version model

- `0.0.0`: blank/unproven repository state. Not a product release.
- `0.0.1`: repository bootstrap baseline. No functional app required.
- `0.1.0`: first functioning application kernel.
- Pre-1.0 MINOR releases: meaningful development increments.
- `0.x.y` patch releases: compatible fixes after a milestone is cut.
- `1.0.0`: first production App Store release.
- Product version uses numeric `MAJOR.MINOR.PATCH`.
- Build number is a monotonically increasing integer.

## Milestone map

| Version | Theme | Primary proof |
|---|---|---|
| `0.0.0` | Blank repository | No implementation/build claims |
| `0.0.1` | Repository bootstrap | Docs/governance/packages/CI establish a reproducible baseline |
| `0.1.0` | Running kernel | Durable text capture survives kill/relaunch and creates one local Note |
| `0.2.0` | Voice capture | Durable raw audio, transcription, replay, recovery |
| `0.3.0` | Image + share capture | Explicit import/share, OCR, App Group handoff proven |
| `0.4.0` | Semantic intelligence | Foundation Models + rule fallback + Flick-owned RoutingScorer |
| `0.5.0` | Structured outputs | Tasks/notes/event drafts + least-privilege EventKit export |
| `0.6.0` | System capture surfaces | App Intents/Shortcuts/widgets/Live Activity where supported |
| `0.7.0` | Retrieval + organization | Search, Spotlight, clustering, lifecycle consistency |
| `0.8.0` | Product hardening | Accessibility/HIG/visual/performance/device adaptation evidence |
| `0.9.0` | Release candidate | TestFlight/release/security/privacy/migration gates |
| `1.0.0` | Production | Signed App Store release from exact validated commit |

# Current milestone — 0.0.1 Repository Bootstrap

## Objective

Turn the blank/unproven repository into one reproducible source of truth without
claiming application functionality.

`0.0.1` exists to make later development trustworthy.

## Phase A — Repository authority

- establish the Flick repository root and independent Git history;
- preserve the existing BSD 3-Clause license holder `Proto`;
- install the complete documentation/governance set;
- ensure `MANIFEST.txt` describes files that actually exist rather than future
  files;
- retain the September 15 partial-export review as historical evidence only;
- remove or quarantine corrupted/stale documentation rather than treating it as
  authority;
- set the repository state explicitly to `0.0.0` until every exit gate passes.

## Phase B — Package scaffold

Create/normalize these package boundaries:

```text
Packages/
  FlickDomain/
  CECapture/
  CEIngestion/
  CESemantic/
  CEStorage/
  CEOutput/
  CEPipelines/
  CEUI/
```

Requirements:

- Swift tools 6.3 manifests;
- Swift 6 language mode;
- iOS 26 minimum where platform declarations apply;
- `FlickDomain` Foundation-only;
- sibling infrastructure packages do not depend on one another merely because
  of runtime ordering;
- `CEPipelines` orchestrates protocol-bearing packages but not `CECapture`;
- `CEUI` may depend on `FlickDomain` + the narrow capture protocol;
- no Xcode application target is required for `0.0.1`;
- no placeholder test whose only assertion is equivalent to `true`.

The September 15 partial export must not be imported wholesale. Reuse code only
after its dependencies and abstraction boundaries are reconciled to the target
architecture.

## Phase C — Governance and CI

Establish:

- portable repository governance on Ubuntu;
- macOS package/build validation on a supported macOS runner;
- immutable full-SHA GitHub Action references;
- format/lint/test/build commands that are either genuinely enforceable or
  explicitly `NOT_APPLICABLE`;
- exact-source correlation for CI;
- `CODEOWNERS`;
- pull-request template;
- Private Vulnerability Reporting before application distribution;
- change detection that reports `INCONCLUSIVE` when no trustworthy comparison
  base exists.

Do not make a permanently red CI job an accepted baseline.

## Phase D — ADR review

ADRs 0001–0007 begin `Proposed`.

Before `v0.0.1` is tagged:

- review each ADR against the package scaffold and current platform assumptions;
- leave risky, unexercised decisions `Proposed` when implementation evidence is
  still missing;
- do not mark an ADR `Accepted` merely because other documents reference it.

## v0.0.1 exit gate

All of the following are required:

- repository root/history is unambiguous;
- LICENSE says `Copyright (c) 2026, Proto`;
- docs are internally consistent;
- package manifests resolve on the validated toolchain;
- applicable package tests execute and pass;
- no package dependency points to an absent package;
- governance reports PASS or explicit NOT_APPLICABLE, with no false PASS;
- UI governance reports NOT_APPLICABLE because no application UI is being
  shipped in this milestone;
- CI checks exact source revisions;
- no old verification log is used as substitute evidence;
- `MANIFEST.txt` matches the checkout;
- the baseline is committed from the exact validated tree.

Only after those gates pass should the commit be tagged `v0.0.1`.

# 0.1.0 — Running Kernel

## Objective

Prove Flick's core correctness invariant using text only:

> A thought becomes a durable local record immediately, survives process
> interruption, and produces one local output without duplicate effects.

### Phase A — Xcode application shell

- create `App/Flick.xcodeproj` and shared `Flick` scheme on macOS;
- iOS 26 minimum, Swift 6 mode, strict concurrency;
- App target is composition/lifecycle only;
- wire local packages;
- establish bundle/App Group identifiers;
- implement the first HIG-compliant native capture/feed shell.

### Phase B — Persistence and queue

- SwiftData schema V1 for Capture + NoteItem + processing state;
- explicit ModelConfiguration;
- reserve App Group store location;
- `.pending` rows are the durable queue;
- state machine: pending → processing → filed/failed;
- launch/foreground recovery;
- `sourceCaptureID` = provenance;
- deterministic `outputIdempotencyKey` = local visible-effect idempotency;
- reserve nullable ingress request identity without promising platform replay
  guarantees where no stable request ID exists.

### Phase C — Text vertical slice

- `CaptureCoordinator.captureText`;
- durable write before UI says "saved";
- feed reflects persisted state;
- text pass-through ingestion;
- no semantic classification;
- kernel router emits exactly one `NoteItem`.

### Phase D — Integration gate

- kill/relaunch at every durable boundary;
- duplicate-output negative controls;
- persistence/recovery tests;
- HIG baseline: Dynamic Type, VoiceOver, safe areas, ≥44×44pt targets,
  Light/Dark, reduced motion, native navigation behavior;
- tag only from exact passing commit.

## 0.1.0 definition of done

A typed thought is durably persisted, immediately visible from persisted state,
processed asynchronously, materialized as one idempotent local Note, and
recovered correctly after forced termination.

# 0.2.0 — Voice Capture

- raw audio becomes durable before transcription completion;
- SpeechAnalyzer/SpeechTranscriber is the preferred iOS 26 path;
- transcript is derived data;
- interruption/kill preserves recoverable audio;
- transcription failure is ingestion failure, not Unsorted;
- playback and deletion lifecycle are tested.

Exit: voice thought can be recorded, killed/relaunched, transcribed, replayed,
and retained without media loss or duplicate local output.

# 0.3.0 — Image and Share Capture

- PhotosPicker explicit import where possible;
- Share-to-Flick;
- Vision OCR to IngestedContent;
- no silent post-relaunch Photos-library crawl to infer screenshot intent;
- cross-process/App Group persistence spike;
- out-of-process capture targets perform capture + durable handoff only.

Exit: shared/imported image survives handoff and produces durable OCR input
without extension-owned downstream processing.

# 0.4.0 — Semantic Intelligence

- production rule-based fallback;
- NaturalLanguage APIs may supply features, not authoritative routing;
- general/default Foundation Models backend with small `@Generable` schema;
- fresh session per unrelated capture;
- runtime availability and token-budget checks;
- model emits interpretation/evidence, not calibrated confidence;
- Flick-owned `RoutingScorer`;
- Unsorted becomes meaningful here;
- long-input compaction strategy selected from measured regression evidence.

Exit: every supported device has a semantic path; model unavailability never
blocks or loses capture.

# 0.5.0 — Structured Outputs

- local TaskItem, NoteItem, CalendarEventDraft;
- source provenance + output idempotency;
- Unsorted correction flow;
- EventKit write-only access by default;
- write-only mode is create-only;
- managed read/update/delete requires explicit full calendar access;
- ambiguous external save is never blindly retried.

# 0.6.0 — System Capture Surfaces

- App Intents / Shortcuts;
- Action Button where supported;
- widgets/controls where supported;
- recording Live Activity where supported;
- execution/process target declared per surface;
- iOS 26 behavior does not depend on iOS 27-only execution-target APIs.

# 0.7.0 — Retrieval and Organization

- FTS/local search;
- Core Spotlight;
- project clustering;
- edit/delete lifecycle across capture, local outputs, media, and indexing;
- EventKit reconciliation only in explicitly enabled full-access
  managed-calendar mode.

# 0.8.0 — Product Hardening

- full Apple HIG and accessibility audit;
- human visual approval for HIGH-criticality surfaces;
- large-data performance;
- battery/storage behavior;
- supported device configurations and adaptive layouts;
- privacy/security review.

# 0.9.0 — Release Candidate

- TestFlight;
- migration rehearsal;
- privacy labels/policy;
- signing/release automation;
- crash/diagnostics policy;
- no unresolved release blockers.

# 1.0.0 — Production

First App Store release from the exact validated, signed release commit.

## Post-1.0 candidates

- CloudKit sync after a separate security/cryptography ADR;
- iPad-specific product design;
- watchOS/macOS companions;
- collaboration/sharing.
