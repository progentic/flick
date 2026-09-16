# Repository State

Version: 1.0\
Last Reviewed: 2026-09-16\
Status: Active

## Current baseline: validated v0.0.1 bootstrap; active v0.1.0 candidate

The repository bootstrap commit is `f802005ad49e9b3074cbc2bc35d6212dedc2ade8`.
Hosted Repository Governance and Swift Packages passed against that exact commit.
The local v0.0.1 tag is absent. No tag has been created or moved during application work.

The current working tree implements a v0.1.0 text-kernel candidate. This is not
an accepted/released v0.1.0: human visual approval is recorded for the current
fingerprint, while hosted CI on its future exact candidate commit remains required. Current evidence is recorded in
`verification/v0.1.0/RESULTS.md`. The following v0.0.0 sections are historical
bootstrap context, not a claim that the current checkout is blank.

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

## Next state: v0.0.1

`v0.0.1` is reached only when the bootstrap acceptance gates in
`docs/ROADMAP.md` and `TASK_PROMPT-v0.0.0-to-v0.0.1.md` are satisfied.

Do not tag `v0.0.1` merely because files were copied into the repository.

## Current candidate scope

- Eight-package graph retained; no later-milestone package restructuring.
- Native iOS text capture/feed, disk-backed SwiftData Schema V1, local Note
  completion, retry, deletion, and interrupted-work recovery.
- App target/scheme Flick, iOS 26, Swift 6 strict concurrency; no voice, semantic,
  system-surface, EventKit, or cloud feature.
- ADR-0001 through ADR-0007 remain Proposed. Implementation evidence does not
  substitute for owner acceptance.
- No application commit, push, tag, or hosted CI run has been authorized by the
  current task. See the current results for exact local checks and open gates.
