# Task Prompt — Bootstrap Flick from v0.0.0 to v0.0.1

You are working on **Flick**, an iOS capture application.

Your task is to turn the current `v0.0.0` blank/unproven repository into the
`v0.0.1` repository bootstrap baseline.

This is a repository/governance/package-scaffold task. It is **not** the
`0.1.0` application implementation.

## Read first

Read, in order:

1. `docs/REPOSITORY_STATE.md`
2. `AGENTS.md`
3. `docs/GOVERNANCE.md`
4. `docs/INVARIANTS.md`
5. `docs/ARCHITECTURE.md`
6. `docs/ROADMAP.md`
7. `docs/adr/README.md`
8. ADR-0001 through ADR-0007
9. `SECURITY.md`
10. `DESIGN.md`
11. `docs/TESTING.md`
12. `docs/DEPENDENCIES.md`
13. `docs/reviews/2026-09-15-partial-export-review.md`

## Starting assumptions

- The repository is conceptually `v0.0.0`.
- Do not assume an app target exists.
- Do not assume packages build.
- Do not assume CI exists.
- Do not assume an old manifest is accurate.
- Do not assume historical verification logs apply to this checkout.
- Do not assume any ADR is Accepted.
- The BSD 3-Clause copyright holder is `Proto`.
- Canonical domain package name is `FlickDomain`.
- Target package manifests use Swift tools 6.3 and Swift 6 language mode.
- Target minimum iOS version is 26 where a package declares a platform.
- A newer installed Xcode/Swift toolchain is allowed, but record the actual
  toolchain and verify compatibility with these minimum package/language
  requirements.

## Historical partial export

A prior local review found:

- only `FlickDomain` and `CEPipelines` had package manifests;
- `CEStorage` and `CEOutput` had protocol sources without package manifests;
- `CEPipelines` referenced missing/unresolvable `CEIngestion`, `CESemantic`,
  and `CEStorage`;
- the host Swift version at that time was older than the package tools version;
- tests did not execute;
- a `PipelineOrchestrator` mixed orchestration, classification, routing,
  plan/model construction, collection mechanics, and persistence.

Treat this as evidence of what **not** to assume.

If any of that source exists in the working tree, preserve it until reviewed,
but do not import it wholesale as the new baseline. Reuse only pieces that fit
the target boundaries and pass current validation.

## Required work

### 1. Establish repository authority

- Confirm the Git root is the Flick directory, not an ancestor repository.
- Inspect branch, status, remotes, tags, and existing files.
- Do not alter remote history.
- Preserve user work.
- Preserve `LICENSE` exactly as BSD 3-Clause with:
  `Copyright (c) 2026, Proto`.
- Make `MANIFEST.txt` an inventory of the checkout, not a wish list.

### 2. Install/reconcile documentation

Ensure the repository contains the authoritative docs from this pack.

Do not create parallel architecture/release/security documents with competing
authority.

Keep ADR-0001 through ADR-0007 `Proposed` unless explicit owner authorization
and adequate evidence justify a status change.

### 3. Scaffold/normalize package boundaries

Target package layout:

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

Rules:

```text
FlickDomain    -> Foundation only
CECapture      -> FlickDomain
CEIngestion    -> FlickDomain
CESemantic     -> FlickDomain
CEStorage      -> FlickDomain
CEOutput       -> FlickDomain
CEPipelines    -> FlickDomain + CEIngestion + CESemantic + CEStorage + CEOutput
CEUI           -> FlickDomain + narrow CECapture protocol
```

No cycle.

Sibling infrastructure packages do not depend on each other merely because one
stage follows another at runtime.

`CEPipelines` must not depend on `CECapture`.

Do not create the Xcode application target in this task unless required solely
to validate the package scaffold. The actual app shell belongs to `0.1.0`.

### 4. Keep orchestration thin

Do not reproduce the reviewed god-orchestrator shape.

A high-level `PipelineOrchestrator` may:

- select/recover work;
- call one stage after another;
- finalize the overall processing result.

It should not also own:

- classification rules;
- routing thresholds;
- filing-intent mapping;
- filing-plan domain construction;
- output-kind model creation;
- array/capacity/iteration mechanics;
- concrete persistence operations.

Create focused collaborators only where the current scaffold genuinely needs
them. Do not over-engineer empty abstractions for future work.

### 5. Governance scripts/policy

Establish repository governance equivalent to the approved Repo Starter
contract:

- `PASS`, `FAIL`, `INCONCLUSIVE`, `NOT_APPLICABLE`;
- trustworthy Git change detection;
- architecture/metadata checks;
- package/tool validation where applicable;
- UI governance separated from non-UI governance;
- no false PASS when a required tool/evidence is missing.

At `v0.0.1`, UI governance should be `NOT_APPLICABLE` unless this task actually
introduces application UI.

### 6. GitHub CI

Create:

- portable `Repository Governance` workflow on Ubuntu;
- Swift/package validation on a compatible macOS runner;
- app-build step that is `NOT_APPLICABLE` until `App/Flick.xcodeproj` exists;
- immutable full-SHA GitHub Action pins;
- checkout of the exact PR/source revision being validated;
- `persist-credentials: false` unless a later authorized workflow genuinely
  requires credentials.

Do not make Xcode-only commands required on Ubuntu.

Do not add a required SwiftLint step unless the workflow deliberately installs
and pins a verified SwiftLint version or the runner contract guarantees it.

### 7. Repository metadata

Prepare:

- `CODEOWNERS`;
- PR template;
- Dependabot configuration where appropriate;
- `.editorconfig`;
- `.gitattributes`;
- `.gitignore`;
- repository policy environment/config files required by governance.

Do not require CODEOWNERS approval if the repository currently has only one
maintainer and that would prevent the author from merging their own PR.

Private Vulnerability Reporting is an external GitHub setting; report it as a
remaining external action if you cannot configure it.

### 8. Testing

Run current package tests on the actual validated toolchain.

A manifest-version failure means tests did not execute.

Do not use placeholder `#expect(true)`-style tests as evidence.

Where the scaffold has no behavior to test, compile/import validation may be
`NOT_APPLICABLE` or narrowly scoped; do not invent meaningless tests.

### 9. Validation

At minimum report:

- Git root and repository state;
- installed Xcode/Swift versions where available;
- package manifest resolution;
- package test results;
- package dependency gaps;
- governance result;
- UI governance result;
- CI files created;
- exact files changed;
- unresolved external actions.

Run `git diff --check`.

Run shell syntax validation for shell scripts.

If a required platform check cannot run locally, report `INCONCLUSIVE`; do not
substitute a historical log.

## v0.0.1 acceptance gate

Do **not** call the bootstrap complete unless:

- repository root/history is unambiguous;
- license holder is Proto;
- docs are internally consistent;
- `MANIFEST.txt` matches the checkout;
- package manifests resolve;
- no package dependency points to an absent package;
- applicable package tests execute and pass;
- governance is PASS/NOT_APPLICABLE with no false PASS;
- UI governance is NOT_APPLICABLE if no UI exists;
- CI uses exact-source correlation and immutable action refs;
- no old verification record is used as proof of the current checkout.

## Git restrictions

Do not commit, tag, push, publish, alter branch protection, or change external
repository settings unless explicitly authorized.

When the work is ready, stop with:

1. concise BLUF;
2. exact validation results;
3. unresolved items;
4. proposed commit contents/message;
5. statement that `v0.0.1` is ready to commit/tag **only if** every gate is met.

Do not start `0.1.0` application work in this task.
