# ADR-0005: Local-Processing Data-Egress Property

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Early Flick security language described the product as having "no network" in the capture-to-classification path.

That statement is too broad.

Flick's intended security property is that user capture content is processed locally and is not sent to an app-controlled or third-party network service during the local processing path. Apple platform frameworks may still perform Apple-managed provisioning, such as downloading model or speech assets. Future CloudKit sync is also a separate feature with different data-egress semantics.

The security claim must describe what Flick actually controls.

## Decision

For the MVP, Flick adopts the following security property:

> User capture content does not egress to an app-controlled or third-party network service during the local capture, ingestion, semantic-classification, and local-output path.

This covers:

- text capture
- raw voice capture
- on-device transcription
- image/OCR ingestion
- rule-based semantic processing
- Foundation Models semantic processing
- local SwiftData/media persistence
- local task/note/event-draft creation

Apple-managed model or speech asset provisioning may use the network. That activity does not authorize Flick to transmit user capture content.

No cloud LLM or application backend is part of the MVP processing path.

### Telemetry and logging

Operational logging must not include raw capture content, transcripts, OCR text, semantic prompts, or extracted private fields by default.

Diagnostics should use non-content metadata such as state transitions, durations, error categories, and opaque identifiers.

### Future sync

CloudKit or any other future sync feature is outside this MVP property.

Before enabling sync, a separate architecture/security decision must define:

- exactly which domain objects leave the device
- whether raw media is eligible
- user controls and defaults
- cryptographic/privacy claims that are actually supported by the chosen configuration
- deletion/revocation behavior

No future sync guarantee is implied by this ADR.

## Invariants / Constraints

- No app-controlled server receives capture content in the MVP processing path.
- No third-party analytics or AI service receives capture content.
- Apple-managed asset downloads are not described as capture-content egress.
- Raw capture data is excluded from routine logs and crash breadcrumbs.
- Adding network processing requires a new ADR and security review.
- Permission to use an Apple framework is not permission to transmit content elsewhere.

## Alternatives Considered

### "No network" as the security property

Rejected because Apple-managed asset provisioning can use the network and the absolute claim is therefore inaccurate.

### Cloud LLM fallback

Rejected for the MVP because it breaks the local-processing data-egress property.

### Silent telemetry of prompts/transcripts for quality improvement

Rejected because it would transmit user capture content outside the local path.

## Consequences

### Positive

- Security language matches the property Flick can control.
- Users can understand the difference between local content processing and Apple-managed asset provisioning.
- Future cloud/sync work cannot silently inherit an overstated privacy claim.

### Negative / Trade-offs

- Product/security copy must avoid the simpler but inaccurate "no network" wording.
- Diagnostics have less raw content available for remote debugging.
- Future sync requires a separate security design.

## Validation

- Network inspection confirms no app-controlled content endpoint exists in the MVP.
- Logging tests and review verify that capture/transcript/OCR/prompt text is not emitted by default.
- Dependency review rejects third-party analytics/AI SDKs that would receive capture content.
- `SECURITY.md` is reconciled to use this property rather than an absolute "no network" claim.
