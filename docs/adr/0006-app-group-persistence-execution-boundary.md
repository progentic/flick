# ADR-0006: App Group Persistence and Capture-Surface Execution Boundaries

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Flick will eventually accept captures from multiple system surfaces.

Those surfaces do not share one universal "extension process" execution model. The actual process/target boundary depends on the surface and intent configuration.

Examples include:

- share extension code running out of process from the main app
- widget interactions that can execute in widget-extension context
- Live Activity intent behavior that may execute in the app process
- App Intents whose supported execution target/mode is declared per intent

Flick therefore cannot make "all intents are extensions" or "all system surfaces run in the app" an architectural assumption.

A second problem is request replay. An externally invoked request can be delivered or attempted more than once. That is a different idempotency problem from downstream output creation.

## Decision

### Surface-specific execution declarations

Every shipped capture surface documents its actual execution target and mode.

Architecture and tests treat that declaration as part of the surface contract.

No generic "extension process" label is used as a substitute for the real execution target.

Execution-target APIs are version-gated: Apple's current documentation marks
explicit execution-target control (`IntentExecutionTargets` /
`allowedExecutionTargets`) as beta and places it in iOS 27, while
`supportedModes` is the iOS 26 execution-mode API. Flick therefore uses
`allowedExecutionTargets` only behind iOS 27 availability; on iOS 26 the
surface relies on target membership, default execution behavior, and
`supportedModes` (the declared execution target/mode is still documented per
surface regardless of which API expresses it).

### Extension composition root

An out-of-process Share/Widget target must itself construct
`CaptureCoordinator` with a concrete `CaptureStoring` implementation — it is
its own composition root for the capture path. That root may wire `CECapture`
and `CEStorage` only; it must not import `CEPipelines`, `CESemantic`, or
`CEOutput` (enforced by the import-boundary tests in Validation).

### One capture contract everywhere

All surfaces call the same `CaptureCoordinator` contract.

Whether invoked in the main app or out of process, the surface performs only the capture-path responsibility:

1. establish a capture/request identity
2. persist raw payload/media as required
3. durably save the `Capture` row with `status: .pending`

Saving `.pending` **is enqueueing**. There is no second durable queue marker.

A non-durable process-local wake/signal may be sent after the durable write, but correctness never depends on that signal.

### Ingress idempotency is separate from output idempotency

Flick defines an ingress request identity for replayable external calls, such as `captureRequestID` or `ingressIdempotencyKey`.

Rules:

- Replaying the **same request identity** must not create a second capture.
- Two independent user invocations receive different request identities and may create two captures even when their text or media content is identical.
- Capture content itself is never used as the deduplication key.
- `outputIdempotencyKey` remains exclusively responsible for duplicate-resistant downstream visible outputs.

This contract applies when a capture surface can supply or persist a stable
request identity across retries. The current App Intents API does not
document a durable invocation identifier being supplied to `perform()`
(`IntentSystemContext` exposes execution mode, locale, voice-only context,
and a precise timestamp where available, but not a general stable
request/replay ID), so the persistence model reserves a **nullable** ingress
key. A surface without a stable identity must treat separate executions as
separate user requests; Flick must not infer duplicates from content
equality. Surface-specific replay guarantees are validated when those
surfaces are implemented (0.3.0/0.6.0), not promised by the 0.1.0 kernel,
which has no App Intent or extension surfaces.

### Out-of-process responsibility

When a surface executes outside the main app process, it may perform capture + durable write only.

It must not run:

- ingestion
- semantic classification
- routing
- EventKit export
- recovery
- main-app feed/business logic

### Main-app processing responsibility

`CEPipelines` in the main app owns downstream processing and recovery.

On launch/foreground it finds unfinished work, including interrupted `.processing` records, and safely re-drives work under the at-least-once/idempotent-effects model.

### App Group persistence

The App Group container is the shared persistence location for the SwiftData store and shared media as defined by ADR-0003.

This is a location decision, not a concurrency guarantee.

Direct multi-process access to the same SwiftData store remains provisional until the 0.3.0 cross-process integration spike proves it on supported OS/toolchain versions.

If that spike fails, the persistence boundary must be redesigned explicitly rather than hidden behind retries or undocumented workarounds.

## Invariants / Constraints

- Every capture surface routes through `CaptureCoordinator`.
- Durable write occurs before any downstream processing.
- `.pending` rows are the durable queue.
- Ingress replay identity and output idempotency are separate domains.
- Identical content from independent user actions is allowed and must not be deduplicated.
- Processing is at least once; visible local effects are idempotent.
- Background scheduling may improve completion but is never required for correctness.
- The <300 ms capture-to-durable-record target is a measured SLO, not a correctness guarantee.

## Alternatives Considered

### Treat all App Intents/widgets/system surfaces as one extension category

Rejected because execution boundaries differ by surface and configuration.

### Content-based deduplication

Rejected because a user may intentionally capture the same text or image more than once.

### Use `outputIdempotencyKey` to deduplicate capture requests

Rejected because ingress request replay and downstream output creation are different failure domains.

### Let out-of-process surfaces classify/export

Rejected because it duplicates pipeline ownership and complicates concurrency, availability, and recovery.

### Per-extension stores merged later

Rejected because it complicates merge semantics and duplicate handling.

## Consequences

### Positive

- One durable capture contract across all surfaces.
- Replay semantics are explicit.
- Main-app processing remains the single owner of recovery and downstream effects.
- System-surface implementation can follow actual platform execution behavior rather than assumptions.

### Negative / Trade-offs

- Each new surface needs an explicit execution-boundary review.
- Direct shared-store writes remain provisional until tested.
- Captures created while the main app cannot process may remain pending until a later main-app opportunity.

## Validation

- Replay the same external request identity twice; assert one `Capture`.
- Submit identical text through two distinct request identities; assert two captures.
- Verify `outputIdempotencyKey` is not used as the ingress deduplication key.
- Cross-process tests create a pending capture through a separate store/process context and drain it in the main app.
- Import-boundary tests reject semantic/output pipeline dependencies from out-of-process capture targets.
- Kill/relaunch tests verify interrupted processing is re-driven without duplicate local outputs.
