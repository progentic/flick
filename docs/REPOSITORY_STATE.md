# Repository State

Version: 1.0\
Last Reviewed: 2026-09-16\
Status: Active

## Current state: v0.0.0

`v0.0.0` is Flick's blank/unproven repository state.

The working tree now contains a bootstrap candidate, not a release. Local
`main` is based on `origin/main` at `a62f2600d4dd48af05d807c2ff5e4a0bffd0a4bf`.
The remote already contained that initial commit; no unrelated local history
was created. No bootstrap commit or tag exists. Current package and governance
evidence is recorded in `verification/bootstrap-v0.0.1.md`.

It is a repository-state marker, not a product release.

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

## Candidate scope

- Eight package manifests follow the target graph.
- FlickDomain supplies reviewed value models and real unit tests.
- CECapture, CEStorage, and CEOutput supply contracts only.
- CEIngestion, CESemantic, CEPipelines, and CEUI are import scaffolds only.
- There is no orchestrator implementation, durable store, EventKit adapter,
  semantic backend, UI, or Xcode app target in this milestone.
- ADR-0001 through ADR-0007 remain Proposed. The scaffold supports their package
  boundaries but does not prove their platform/runtime assumptions.
- Hosted CI and the exact-commit/tag gate remain external until authorized.
