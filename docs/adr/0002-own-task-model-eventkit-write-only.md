# ADR-0002: Own Task Model; EventKit Write-Only Export by Default

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Flick produces local tasks, notes, and calendar event drafts from captures.

Flick task objects need product-specific metadata, including source linkage and later project/subtask behavior. EventKit reminders are not a suitable authoritative task store for that model.

Calendar export has a separate permission problem. Write-only EventKit access supports creating calendar events with less privilege than full calendar access, but write-only access does not support a general read/reconciliation contract for later managed updates and deletes.

The architecture must therefore distinguish:

- local Flick objects
- create-only calendar export under write-only access
- optional capabilities that genuinely require full calendar access
- ambiguous external side effects after process interruption

## Decision

### Flick owns its task model

Tasks are first-class `FlickDomain` objects persisted through `CEStorage`.

EventKit Reminders is not Flick's task store.

`sourceCaptureID` remains provenance linking a task back to the originating capture. Local output idempotency is governed separately by `outputIdempotencyKey`.

### Calendar events are exported through `CEOutput`

`CalendarEventDraft` is a local Flick object.

`CEOutput` owns the EventKit integration boundary.

The default EventKit permission posture is **write-only**.

Under write-only authorization, Flick's supported guarantee is **create-only export**. Flick must not claim that it can reliably fetch, reconcile, update, or delete exported events under write-only access.

An `eventIdentifier` may be retained as export provenance when available, but storing an identifier does not itself grant read/reconciliation capability.

### Full calendar access is an explicit capability escalation

Any feature requiring calendar reads must request full access explicitly and contextually.

Examples include:

- calendar-aware semantic grounding
- managed reconciliation of prior exports
- direct fetch/update/delete workflows that require reading calendar state

Full access is never requested merely because the user exports an event.

The exact product UX for these optional capabilities is deferred to the milestone that implements them.

### External-export state machine

EventKit export uses its own persisted delivery state, separate from local-output idempotency.

A crash can occur after EventKit accepts an external save but before Flick records local acknowledgement. That is an ambiguous external side effect.

In that state Flick must not blindly retry and risk creating a duplicate calendar event.

Under write-only access, ambiguous export is surfaced for review or explicit retry unless a stronger reconciliation mechanism is later proven.

## Invariants / Constraints

- Flick task storage does not depend on EventKit Reminders.
- Full calendar access is never a side effect of basic event export.
- Write-only mode promises create-only export, not managed reconciliation.
- External EventKit effects are never described as exactly-once.
- Local objects remain useful even when calendar permission is denied.
- `sourceCaptureID` is provenance; `outputIdempotencyKey` governs local-output idempotency.

## Alternatives Considered

### EventKit Reminders as the task store

Rejected because Flick's task metadata and source relationships are product-owned and should not be constrained by a system reminder model.

### Full calendar access by default

Rejected because it violates least privilege.

### Treating `eventIdentifier` as sufficient for write-only update/delete

Rejected. Identifier persistence does not create read authorization.

### Blind retry after ambiguous EventKit export

Rejected because it can create duplicate external events.

## Consequences

### Positive

- Least-privilege default permission posture.
- Flick retains full control of its task/domain model.
- External-side-effect ambiguity is represented honestly.
- Calendar-aware features can be added later without weakening the default export path.

### Negative / Trade-offs

- Write-only users do not receive managed update/delete/reconciliation guarantees.
- Full-access features require a second, explicit permission decision.
- Ambiguous exports may require user review.

## Validation

- Basic export tests assert that only write-only permission is requested.
- No basic export path triggers a full-access prompt.
- Write-only tests do not claim direct fetch/update/delete support.
- External-export recovery tests simulate interruption after external save and before local acknowledgement.
- Ambiguous exports do not auto-retry.
- Full-access capabilities, when implemented, have separate permission and reconciliation tests.
