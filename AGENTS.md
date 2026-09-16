# AGENTS.md

Version: 2.0\
Last Reviewed: 2026-09-16\
Status: Active repository policy

This file is the operating contract for coding agents working on Flick.

## Current baseline

The repository is at conceptual state `v0.0.0`: blank/unproven.

Do not infer implementation completeness from:

- historical verification logs;
- a partial exported source tree;
- package manifests that do not resolve in the current checkout;
- files listed by an old manifest but absent from the checkout;
- tests that did not actually execute;
- an ancestor Git repository discovered outside the Flick root.

The historical partial-export review is retained at
`docs/reviews/2026-09-15-partial-export-review.md`.

## Required read order

Before modifying implementation or governance, read:

1. `docs/REPOSITORY_STATE.md`
2. `docs/GOVERNANCE.md`
3. `docs/INVARIANTS.md`
4. `docs/ARCHITECTURE.md`
5. applicable ADRs under `docs/adr/`
6. `docs/CODING_STYLE.md`
7. `docs/ERROR_HANDLING.md`
8. `docs/TESTING.md`
9. `docs/DEPENDENCIES.md`
10. `DESIGN.md`, `docs/UI_STANDARD.md`, `docs/UI_GOVERNANCE.md`,
    `docs/UI_INVARIANTS.md`, and `docs/UI_REFERENCES.md` when UI is applicable

## Agent rules

- MUST preserve documented invariants.
- MUST establish the actual repository root before using Git history as evidence.
- MUST inspect current files/tests before inventing a new abstraction.
- MUST keep one authoritative implementation for each behavior or policy.
- MUST prefer the narrowest change that satisfies the task.
- MUST update governing documentation when an approved architectural/design
  decision changes.
- MUST add or update tests for changed behavior unless explicitly
  `NOT_APPLICABLE`.
- MUST report required validation that cannot run as `INCONCLUSIVE`, never PASS.
- MUST NOT cite an old verification log as proof of the current checkout.
- MUST NOT weaken tests, governance, lint rules, review criticality, or negative
  controls merely to make work pass.
- MUST NOT commit, push, tag, publish, release, alter branch protection, or
  accept ADRs unless the task explicitly authorizes that action.
- MUST preserve the BSD 3-Clause copyright holder as `Proto` unless the owner
  explicitly changes it.

## Flick-specific architecture rules

- Canonical domain package name: `FlickDomain`.
- `FlickDomain` is Foundation-only.
- Capture crosses a durable-write boundary before ingestion, semantics, or
  external output begins.
- `.pending` capture rows are the durable queue; do not invent a second durable
  queue marker.
- `sourceCaptureID` is provenance.
- ingress replay identity, when a surface can provide one, is separate from
  downstream `outputIdempotencyKey`.
- identical content from two independent requests is not a duplicate.
- local processing is at least once; local visible effects are idempotent.
- write-only EventKit export is create-only by default.
- ambiguous external EventKit side effects are never blindly retried.
- extension/system capture targets perform capture + durable handoff only;
  downstream processing belongs to the main-app pipeline.
- runtime sequence and compile-time package dependencies are separate concerns.
- top-level orchestration coordinates. It MUST NOT absorb classification rules,
  plan construction, output-kind mapping, collection mechanics, and persistence
  into one oversized function.

## UI rules

- Apple HIG is the governing interaction language.
- Prefer native SwiftUI components before custom equivalents.
- Mail and Notes are interaction references, not visual templates.
- Preserve Flick's Aesthetic Intent, Anti-reference, and Visual Signature.
- HIGH aesthetic-criticality work requires explicit human visual approval.
- Rendered UI evidence is required for substantial UI changes.
- No UI state may claim a capture is saved before the durable write succeeds.

## Required change loop

Inspect → establish authority → define job → plan → implement narrowly →
test → run negative controls → render/review UI when applicable →
update docs/evidence → run governance → report exact status.

## Stop conditions

Stop and surface the conflict when:

- requirements contradict an invariant;
- a destructive migration lacks an approved plan;
- a required validation cannot run;
- a comparison base cannot be established;
- HIGH-criticality UI lacks human visual approval;
- a requested exception lacks owner/expiry;
- implementation would require silently changing governance or an accepted ADR.
