# Repository State

Version: 1.1\
Last Reviewed: 2026-09-17\
Status: Active

## Current baseline: accepted v0.1.0; next milestone v0.2.0

`v0.1.0 — Text Flick / Running Kernel` is **ACCEPTED** at
`2ec113ca9ea94092d2a00f38a3280938bc08d17f`. Hosted governance, all 78 package tests,
app build and the complete 12-test UI suite passed for that exact source.
Human visual approval and the approved fingerprint remain unchanged.

Annotated tag `v0.0.1` targets validated bootstrap
`f802005ad49e9b3074cbc2bc35d6212dedc2ade8`. Annotated tag `v0.1.0` targets the
accepted application commit above. Both were pushed as `progentic` on 2026-09-17.
See [the final verification record](verification/v0.1.0/ACCEPTANCE.md), including
nonblocking native-audit debt and the historical local Xcode 27 failure.

v0.1.0 is frozen. **0.2.0 — Voice Flick** is the next development milestone;
voice implementation is not part of this release bookkeeping. The following
v0.0.0 sections retain historical context, not the current implementation status.

### Authoritative at v0.0.0

- product identity: Flick
- BSD 3-Clause license, copyright `Proto`
- planning/governance documents in this documentation pack
- ADRs as `Proposed`
- roadmap intent and milestone exit criteria

### Not authoritative at v0.0.0

- any application implementation
- any generated Xcode project
- any package dependency graph in an old export
- any historical `MANIFEST.txt` that lists absent files
- any prior build/test result from a different checkout/toolchain
- any ADR marked Accepted elsewhere
- any visual approval from a different implementation

## Historical partial export

A September 15 review observed a partial source export containing:

- `FlickDomain` and `CEPipelines` package manifests;
- protocol source under `CEStorage` and `CEOutput` without package manifests;
- absent `CEIngestion` and `CESemantic` directories required by the pipeline manifest;
- Swift tools 6.3 manifests on a host whose default Swift reported 6.2.4;
- no executed package tests because manifest validation stopped first;
- orchestration code that mixed high-level coordination with classification,
  routing, mapping, allocation/iteration, and persistence responsibilities.

That review is retained under `docs/reviews/` as evidence. It does not become the
new implementation baseline merely by being present.

## Historical bootstrap acceptance boundary

`v0.0.1` is reached only when the bootstrap acceptance gates in
`docs/ROADMAP.md` and `TASK_PROMPT-v0.0.0-to-v0.0.1.md` are satisfied.

Do not tag `v0.0.1` merely because files were copied into the repository.

## Accepted v0.1.0 scope

- Eight-package graph retained; no later-milestone package restructuring.
- Native iOS text capture/feed, disk-backed SwiftData Schema V1, local Note
  completion, retry, deletion, and interrupted-work recovery.
- App target/scheme Flick, iOS 26, Swift 6 strict concurrency; no voice, semantic,
  system-surface, EventKit, or cloud feature.
- ADR-0001 through ADR-0007 remain Proposed. Implementation evidence does not
  substitute for owner acceptance.
- Owner acceptance and milestone tag pushes are recorded in the final verification
  record. No binary distribution or App Store submission was performed.
