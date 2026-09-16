# ADR-0007: Apple Sample-Code Extrapolation Rulings

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Flick's architecture research reviewed Apple sample-code and documentation patterns for Foundation Models, Speech, App Intents, Background Tasks, SwiftData, and related system APIs.

Those samples are useful implementation references, but sample code is not Flick's architecture authority.

The central conclusion is retained:

> Flick must prove a durable, crash-recoverable, duplicate-resistant kernel before adding speech, semantic models, Photos workflows, EventKit export, or extension/system surfaces.

This ADR records which extrapolations are adopted, modified, rejected, or deferred.

## Decision

### Adopt

#### Durable kernel first

0.1.0 remains text-only.

Capture is persisted before any later stage. Recovery re-drives unfinished durable records.

#### SwiftData actor isolation

Storage/queue work is isolated through the storage actor/model-context boundary. Managed persistence objects do not become cross-package concurrency messages; domain identifiers/value types cross boundaries instead.

#### At-least-once processing with idempotent effects

Process termination can cause work to repeat.

Flick never describes execution as exactly once.

Local visible effects are protected by persistent idempotency constraints.

#### <300 ms capture durability target

Capture-to-durable-record is a measured SLO, recorded separately for warm and cold paths. It is not a correctness guarantee.

#### Foundation Models structured generation

`@Generable` / `@Guide` are appropriate for the 0.4.0 structured semantic path.

A fresh model session is used per capture.

#### Speech direction

0.2.0 prefers the iOS 26 SpeechAnalyzer/SpeechTranscriber direction.

Raw audio is persisted as authoritative input before transcription is treated as complete.

`SFSpeechRecognizer` is not the primary design unless a compatibility requirement justifies it.

#### App Intents/system surfaces

System entry points use the same durable capture contract. They never create a second pipeline.

Execution target/mode is surface-specific as defined by ADR-0006.

### Modify

#### Runtime sequence versus package graph

Runtime order is:

```text
Capture
  ↓
Durable Storage / Queue
  ↓
Ingestion
  ↓
Semantic
  ↓
Routing / Local Output
  ↓
UI reflects durable state
```

This runtime sequence does not dictate compile-time package dependencies.

`CEPipelines` is the orchestration layer that composes protocol-backed stages.

Sibling infrastructure packages do not depend on one another merely because one stage follows another at runtime.

#### Provenance versus idempotency

`sourceCaptureID` is provenance.

`outputIdempotencyKey` protects downstream local-output creation.

Ingress replay is a third concern and uses its own request identity as defined in ADR-0006.

#### NaturalLanguage role

NaturalLanguage APIs may provide language/entity/token features.

The fallback classifier is an explicit non-generative rule engine. It is not described as "deterministic" merely because it does not use a generative model.

### Reject or defer

#### BackgroundTasks as a kernel requirement

Rejected.

Launch/foreground recovery must be sufficient for correctness.

Background scheduling can later improve completion latency, but the queue cannot depend on it.

#### `.contentTagging` for primary classification

Rejected.

The general/default Foundation Models path with a constrained structured schema is used for task/event/note interpretation.

`.contentTagging` is reserved for later tags/topics/clustering/retrieval metadata.

#### Model-generated confidence

Rejected.

The model emits interpretation + evidence. Flick computes `RoutingScore` from verifiable signals under ADR-0001.

#### Mandatory long-input summarization

Rejected.

0.4.0 selects chunking, selective extraction, summarization, or another compaction method based on measured regression results.

#### Photos-library polling after relaunch

Rejected by default.

The screenshot-taken notification is only a signal and does not contain the screenshot payload.

Reliable image/screenshot capture uses explicit Share-to-Flick and PhotosPicker import.

#### Assuming App Group configuration proves multi-process SwiftData safety

Rejected.

Shared location is configured from the beginning, but concurrent/multi-process behavior remains provisional until 0.3.0 integration evidence exists.

## Locked Kernel Semantics

### General processing path

```text
User input
   │
   ▼
CaptureCoordinator
   │
   ├── create capture identity
   ├── create/reuse ingress request identity where applicable
   │
   ▼
Durable SwiftData write
status = pending
   │
   ├────────────── process may terminate here
   │
   ▼
CEPipelines claims record
status = processing
   │
   ▼
Ingestion
   │
   ▼
Semantic / routing (when the milestone includes semantics)
   │
   ▼
Idempotent local output
   │
   ▼
status = filed / unsorted / failed
```

If processing is interrupted, recovery re-drives the durable capture. Flick owns the state machine and retry semantics.

### 0.1.0 narrowed vertical slice

0.1.0 performs no semantic classification.

A typed thought is:

1. durably persisted
2. immediately visible from persisted state
3. asynchronously processed through the queue/orchestrator
4. materialized as one idempotent local `NoteItem`
5. correctly recovered after forced termination at each durable boundary

For 0.1.0, the relevant terminal states are `filed` and `failed`. `unsorted` becomes meaningful only when semantic routing exists in 0.4.0.

### 0.2.0 direction

```text
durable raw audio
    ↓
SpeechAnalyzer / SpeechTranscriber
    ↓
durable transcript
    ↓
same downstream queue contract
```

Transcription failure is an ingestion failure, not "Unsorted."

### 0.4.0 direction

```text
SystemLanguageModel general/default
        │
        ▼
@Generable CaptureInterpretation
        │
        ├── kind
        ├── title
        ├── temporal hints
        ├── source-verifiable evidence
        └── extracted structured fields
        │
        ▼
Flick RoutingScorer
        │
        └── RoutingScore → auto-file or Unsorted
```

The model does not emit authoritative confidence.

### Screenshot product decision

Flick does not silently crawl the Photo Library after launch to infer which screenshots the user intended to capture.

Share-to-Flick and explicit PhotosPicker selection are the reliable image-import mechanisms.

## Invariants / Constraints

- Runtime order and compile-time dependencies are separate concerns.
- Capture always crosses durability before intelligence begins.
- `sourceCaptureID`, ingress request identity, and `outputIdempotencyKey` serve different purposes.
- Background scheduling is optional acceleration, not correctness infrastructure.
- Screenshot import is explicit.
- App Group location is not treated as proof of multi-process store safety.
- Apple sample code informs implementation; Flick's ADRs define Flick guarantees.

## Alternatives Considered

### Adopt sample architecture literally

Rejected because samples demonstrate APIs, not Flick's crash/recovery, idempotency, privacy, or package guarantees.

### Keep pseudo-semantic classification in 0.1.0

Rejected because it weakens the kernel correctness proof.

### Use content equality for duplicate suppression

Rejected because identical independent captures are valid user actions.

## Consequences

### Positive

- 0.1.0 remains small enough to prove rigorously.
- Later milestones can use Apple-native APIs without allowing sample structure to dictate package architecture.
- Privacy and idempotency boundaries are explicit before feature expansion.

### Negative / Trade-offs

- Several attractive features move later in the roadmap.
- Flick owns queue/recovery/idempotency behavior that Apple samples do not provide.
- Some platform-boundary assumptions remain provisional until device/toolchain testing.

## Validation

- 0.1.0: kill/relaunch at each durable boundary; one local `NoteItem`; warm/cold capture timing recorded.
- 0.2.0: interruption preserves/finalizes recoverable audio; transcription retries from durable media.
- 0.3.0: App Group cross-process behavior is proven before multi-writer dependence.
- 0.4.0: Foundation Models availability matrix + rule-backend regression corpus + RoutingScorer tests.
- System-surface tests distinguish replay of one request identity from two independent identical-content captures.
