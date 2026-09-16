# Flick Architecture Decision Records

Consolidated: 2026-09-11\
Current status: All ADRs are **Proposed**

These records consolidate the current architecture decisions for Flick before the `v0.0.1` bootstrap baseline is treated as complete.

## Index

| ADR | Title | Status |
|---|---|---|
| ADR-0001 | Foundation Models Primary Backend with Rule-Based Fallback | Proposed |
| ADR-0002 | Own Task Model; EventKit Write-Only Export by Default | Proposed |
| ADR-0003 | SwiftData Structured Store with App Group Media Files | Proposed |
| ADR-0004 | FlickDomain Is Foundation-Only | Proposed |
| ADR-0005 | Local-Processing Data-Egress Property | Proposed |
| ADR-0006 | App Group Persistence and Capture-Surface Execution Boundaries | Proposed |
| ADR-0007 | Apple Sample-Code Extrapolation Rulings | Proposed |

## Status rules

- **Proposed**: decision is drafted and may still change during implementation/review.
- **Accepted**: owner has explicitly accepted the decision and implementation evidence does not contradict it.
- **Superseded**: a later ADR replaces the decision.
- **Deprecated**: retained for historical context but no longer governs implementation.

Do not mark an ADR Accepted merely because it is present in the repository.

## Consolidation order

The records are designed to be read in numerical order.

Key cross-record relationships:

- ADR-0001 depends on ADR-0005 for the local-processing privacy boundary.
- ADR-0002 separates local-output idempotency from external EventKit delivery.
- ADR-0003 defines storage/media placement used by ADR-0006.
- ADR-0004 defines the portable domain boundary shared by all packages.
- ADR-0006 separates ingress request replay from downstream output idempotency.
- ADR-0007 records the Apple sample-code rulings that shape milestones 0.1.0 through 0.4.0.

## Required repository reconciliation

After copying these ADRs into the repository, reconcile `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `DESIGN.md`, `UI-REVIEW.md`, and `SECURITY.md` against them before declaring the documentation baseline complete.
