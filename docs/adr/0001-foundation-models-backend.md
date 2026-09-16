# ADR-0001: Foundation Models Primary Backend with Rule-Based Fallback

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Semantic classification is a core Flick capability, but capture correctness cannot depend on semantic-model availability.

Apple's on-device Foundation Models framework provides structured generation through `LanguageModelSession`, `@Generable`, and `@Guide`, but model availability is dynamic. Hardware eligibility, Apple Intelligence state, model readiness, and locale support can all affect whether the Foundation Models path is available.

Flick must therefore preserve two separate properties:

1. Capture is always durable before semantic work begins.
2. Semantic classification continues to function, at reduced capability if necessary, when Foundation Models is unavailable.

The model must also not be treated as the authority on how trustworthy its own output is.

## Decision

Flick uses two semantic backends behind a `SemanticBackend` protocol.

### Primary backend: Foundation Models

`FoundationModelBackend` uses the general/default system model with one fresh `LanguageModelSession` per capture.

The primary structured result is a small `@Generable CaptureInterpretation` containing:

- `kind`: task | event | note | uncertain
- title
- temporal hints
- quoted or otherwise source-verifiable evidence
- extracted structured fields appropriate to the kind

The schema contains **no model-generated confidence field**.

The `.contentTagging` specialization is reserved for later capabilities such as semantic tags, topic detection, clustering, and retrieval metadata. It is not the primary task/event/note classifier.

No model tool calling is required for the initial 0.4.0 semantic milestone. Calendar/project grounding is deferred until a later ADR defines an explicit context boundary and implementation evidence shows that tool calling materially improves classification.

### Flick-owned routing score

Flick computes a `RoutingScore` after backend output is validated.

`RoutingScorer` may use verifiable signals such as:

- required-field completeness
- evidence presence in the source capture
- date/time parsing validity
- ambiguity detection
- agreement or conflict between rule and Foundation Models results
- schema and domain validation

The routing score, not a model-authored confidence value, controls auto-file versus Unsorted behavior.

### Fallback backend

`RuleBasedBackend` is a non-generative rules engine.

NaturalLanguage APIs such as `NLLanguageRecognizer`, `NLTagger`, and `NLModel` may provide language/entity/token features to the rule engine. Those APIs are preprocessing inputs; they are not themselves the authoritative classifier.

### Runtime token budgeting

Token budgeting is computed at runtime using the APIs exposed by the installed system model, including `contextSize` and `tokenCount(for:)`.

No context-window size is an architectural constant.

For inputs that exceed the available budget, 0.4.0 must select and validate a compaction strategy against a regression corpus. Candidate strategies include:

- chunking
- selective extraction
- summarization

No strategy is preselected in this ADR because pre-summarization can remove classification-critical details.

### Availability handling

The backend selector explicitly handles:

- device ineligibility
- Apple Intelligence disabled
- model not ready / model assets preparing
- unsupported locale

Each case routes to the rule-based backend. Semantic unavailability must never make capture unavailable.

## Invariants / Constraints

- Classification never blocks capture.
- Classification begins only after the capture crosses the durable-write boundary.
- Semantic work executes away from `MainActor`.
- `CESemantic` consumes `IngestedContent`; it does not consume raw audio or image objects.
- `CESemantic` does not own persistence, EventKit access, or capture UI.
- A fresh model session is used per unrelated capture.
- No backend is allowed to report its own trustworthiness as an authoritative confidence value.
- `RoutingScorer` is the sole authority for routing trust.

## Alternatives Considered

### Cloud LLM classification

Rejected for the MVP because it violates ADR-0005's local-processing data-egress property and adds a network dependency to the semantic path.

### Hard Foundation Models requirement

Rejected because it would make Flick non-functional on unsupported or temporarily unavailable configurations.

### `.contentTagging` as the primary classifier

Rejected. It is reserved for tag/topic/clustering use rather than primary task/event/note routing.

### Hard-coded context limits

Rejected. Runtime model capabilities are the source of truth.

### Mandatory pre-summarization

Rejected. It can remove the exact temporal or intent-bearing language needed for correct routing.

## Consequences

### Positive

- Best-available structured extraction on eligible devices.
- Functional semantic fallback on unsupported devices.
- Routing trust remains app-owned and testable.
- Model-context behavior is isolated between captures.
- Token budgeting can adapt to model/runtime changes.

### Negative / Trade-offs

- Two semantic backends must be maintained.
- `RoutingScorer` requires an explicit regression corpus and threshold tuning.
- Long-input handling remains an implementation decision until 0.4.0 evidence exists.

## Validation

- Backend-selection tests cover all documented availability branches.
- Rule backend has an independent regression corpus.
- `RoutingScorer` tests cover each verifiable input signal.
- No test or schema asserts a model-generated confidence value.
- Long-input strategies are compared against a fixed regression corpus before one becomes the default.
- Semantic failures never delete, hide, or invalidate the durable source capture.
