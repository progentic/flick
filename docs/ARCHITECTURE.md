# Architecture

> Baseline: bootstrap commit `f802005` passed hosted CI. The v0.1.0 text kernel
> described below is an uncommitted candidate; later-milestone architecture remains
> proposed. Historical partial-source exports are evidence only.

Version: 1.0
Last Reviewed: 2026-09-16
Status: Proposed target architecture

> Public product name: **Flick**. Internal development codename: **Clyde**.
> The codename appears in dev-only material; user-facing surfaces use "Flick".

## Naming

`FlickDomain` is the canonical domain package name. Any historical `CEDomain` reference is stale and must not be reintroduced.

## Implemented v0.1.0 text-kernel boundaries

- `App/Flick.xcodeproj`, target/scheme `Flick`, is the composition/lifecycle root.
  Bundle ID: `com.progentic.flick`; App Group: `group.com.progentic.flick`.
  Entitlements reserve that namespace; physical-device provisioning still requires
  the owner's Apple development team. Simulator runtime tests use ad-hoc signing
  so the App Group entitlement is actually registered.
- `CECapture.CaptureCoordinator` validates nonempty text and awaits an injected
  asynchronous persistence capability. It preserves original text and creates a
  new capture identity for each independent action. No content deduplication.
- `CEStorage.TextStore` is a dedicated `@ModelActor`, constructed off MainActor.
  It owns Schema V1 and an explicit, local-only ModelConfiguration beneath the
  App Group container. Autosave is disabled. No ModelContext/model crosses its
  actor boundary; callers receive Sendable domain snapshots or signals to reload.
- A capture owns its local Note through a cascade relationship. Completion
  inserts the Note and changes capture state to filed in one explicit save.
  A persistent unique output key plus serialized completion prevent duplicate
  visible Notes. A failed save rolls back the entire context operation.
- `CEIngestion.TextIngestion` returns the original text unchanged. The focused
  `CEPipelines.TextNotePlanner` makes one ordinal-zero Note. `TextKernel` only
  recovers/selects work, sequences stages, and finalizes. It coalesces overlapping
  drains so recovery cannot reset an active claim.
- State transitions: pending→processing→filed/failed; interrupted processing→pending
  only through recovery; failed→pending only through explicit retry. Unsorted is
  not part of this kernel. A deterministic ingestion failure marks only that
  capture failed; a persistence failure stops the drain with recoverable state.
- Capture deletion removes its Note in the same save. If deletion wins while
  processing is suspended, completion cannot recreate the missing capture/Note.
  Independent Note deletion/editing does not exist in this slice.
- CEUI's MainActor model consumes persisted snapshots; it never inserts an
  optimistic feed row. Success follows capture-save completion. Async change
  signals trigger reloads, including intermediate processing state. New draft
  text clears the previous capture's success feedback.
- SwiftData/SwiftUI/Observation/OSLog imports are permitted only in their owning
  packages by `.repo-policy.json`. Domain remains Foundation-only. macOS 14 is
  an additional host-test minimum for packages using those frameworks; iOS 26,
  tools 6.3, and Swift 6 mode are unchanged.

Schema V1 is the development migration baseline; future stored-model changes
need a new schema version and tested migration stages. No store is erased or
replaced when opening existing data fails. Debug-only UI-test configuration uses
isolated UUID-named stores and real read-only stores/boundary delays; it is absent
from Release. No semantic, EventKit, voice, media, or background-task feature is
implemented in this milestone.

The `TextV1.store` path and `FlickTextV1` configuration name are stable storage
identities. A future schema version must migrate that existing store rather than
silently switch to a new filename. The encoded Note payload is part of schema
compatibility: breaking Codable changes require an explicit payload migration.

## System Purpose

Flick is a zero-friction capture engine for iOS: voice, text, and screenshot go in;
structured tasks, calendar events, and notes come out — with no manual organization.
Capture is instant and durable; classification happens asynchronously, on-device,
and never blocks the capture path.

## Context and Boundaries

- **In scope:** capture surfaces (in-app button, share extension, Lock Screen widget,
  Dynamic Island Live Activity, Action Button shortcut), durable capture queue,
  ingestion (transcription/OCR), on-device semantic classification (Foundation Models
  primary, rule-based fallback), structured output objects (tasks, event drafts, notes,
  project clusters), unsorted feed with user correction, EventKit calendar export,
  on-device search (FTS + Core Spotlight), optional post-MVP CloudKit sync.
- **Out of scope:** server-side components, accounts/login, cross-platform clients
  (watchOS/macOS are future companions; `FlickDomain` is kept reusable for them),
  cloud LLM calls, shared/collaborative spaces.
- **External systems:** iOS platform services only — SpeechAnalyzer, Vision (OCR),
  NaturalLanguage, Foundation Models (`SystemLanguageModel`), EventKit, WidgetKit,
  ActivityKit, AppIntents/Shortcuts, Core Spotlight. No backend API exists or is
  required for MVP.
- **Trust boundaries:**
  - App process ↔ extension processes: the App Group container is the
    persistence boundary (ADR-0006). The SwiftData store file and all shared
    media resolve beneath it; media is referenced by opaque IDs or relative
    paths, never absolute sandbox URLs. This establishes the storage location
    only; the extension/main-app concurrency model stays provisional until
    proven by test in 0.3.0 (ADR-0007). The execution target is
    surface-specific, not one generic "extension process": current App Intents
    explicitly target the main app, the App Intents extension, or the widget
    extension through `allowedExecutionTargets`, and runtime mode is
    separately controlled by `supportedModes`. Explicit target control is
    version-gated: Apple's current documentation marks
    `IntentExecutionTargets` / `allowedExecutionTargets` as beta in iOS 27,
    while `supportedModes` is the iOS 26 execution-mode API — so Flick uses
    `allowedExecutionTargets` only behind iOS 27 availability and relies on
    target membership, default execution behavior, and `supportedModes` on
    iOS 26 (ADR-0006). Ordinary widget App Intents
    normally execute in the widget extension; `LiveActivityIntent` executes
    in the app process. Wherever code runs outside the main app process, the
    rule is the same: capture + durable write only; all processing runs in
    the main app. `CaptureCoordinator` is the single entry point in every
    process.
  - App process ↔ iOS system services (mic, photos, calendar): contextual,
    least-privilege permission grants (see `SECURITY.md`). Calendar export
    uses write-only EventKit access by default, and the default export is
    **create-only**: write-only authorization cannot fetch even events Flick
    itself created, so managed update/delete/reconciliation requires an
    explicit full-access grant or user-managed edits through EventKitUI
    (ADR-0002). Photo import prefers PhotosPicker (no library authorization
    needed).
  - Classified objects ↔ EventKit: one-way export. The
    `EKEvent.eventIdentifier` is stored back as a reference, but under the
    default write-only authorization it cannot be resolved later — any
    update/delete/reconciliation path is contingent on full access or
    EventKitUI (ADR-0002).
  - Post-MVP: device ↔ CloudKit private database (account-based protection;
    `FlickDomain` objects only, raw audio excluded by default). Cryptographic
    guarantees are a future requirement, not a current claim (see
    `SECURITY.md`).

## Components

| Component | Owns | Does not own |
|---|---|---|
| `CECapture` | Capture surfaces; `CaptureCoordinator` single entry point; immediate durable write into the App Group store (via an injected `CaptureStoring` protocol) | Transcription, classification, UI beyond capture, any concrete storage type |
| `CEIngestion` | Audio→text (SpeechAnalyzer), image→text (Vision OCR + coarse scene classification), text pass-through; NL-derived language/entity/token hints as features for downstream rules; produces `IngestedContent` (a `FlickDomain` type) | `CESemantic` (no dependency), any AVFoundation/Vision detail leaking past its boundary |
| `CESemantic` | `SemanticBackend` protocol; `FoundationModelBackend` (guided generation via `@Generable`, runtime token budgeting); `RuleBasedBackend` (explicit rule backend; NaturalLanguage APIs supply language/entity/token features to the rules); `RoutingScorer` + routing (auto-file vs unsorted) | Persistence, capture UI, calendar writes, any concrete `CEStorage` type |
| `FlickDomain` | Pure domain structs (`Capture`, `TaskItem`, `CalendarEventDraft`, `NoteItem`, `ProjectCluster`, `IngestedContent`); Foundation-only (ADR-0004) | Persistence adapters, platform-service or UI framework imports |
| `CEStorage` | SwiftData persistence via thin `@Model` adapters for captures/tasks/notes/event drafts/project clusters; media files under the App Group container referenced by opaque IDs/relative paths (ADR-0003); durable `ProcessingQueue` (pending captures are the queue); local search index | Classification decisions, EventKit writes, UI, Spotlight indexing (external indexing side effect — package ownership deferred to 0.7.0) |
| `CEOutput` | External output integrations, primarily `EventKitAdapter` (calendar export, write-only permission and create-only semantics by default) | SwiftData persistence, classification decisions, capture |
| `CEPipelines` | **Orchestration layer.** Drains pending captures from the queue and composes storage → ingestion → semantic → output **via protocols** (owns no concrete service types); owns local-output idempotency coordination and the launch recovery pass | Capture creation and any concrete ingestion/semantic/storage/output implementation |
| `CEUI` | SwiftUI views: capture button, chronological feed, task cards, unsorted feed, settings (depends on `FlickDomain` + `CaptureCoordinating` protocol). Native SwiftUI components first — Button, TextField, NavigationStack, toolbars, sheets, menus, system symbols — before custom equivalents; standard controls inherit Liquid Glass automatically (DESIGN.md §0) | Business logic, pipeline orchestration |
| App | Composition root: wires concrete services into `CEPipelines`, triggers lifecycle recovery on launch/foreground, permission gating | Feature logic, processing logic (lives in `CEPipelines`) |

### Orchestration boundary

`CEPipelines` is deliberately thin at its top level.

The top-level orchestrator may select/recover work and sequence protocol-backed
stages, but it must not combine all of the following in one function:

- classification rules;
- routing policy;
- filing-plan construction;
- output-kind/domain-model construction;
- collection allocation/iteration mechanics;
- concrete persistence operations.

If those responsibilities begin accumulating, split them behind focused
mid-level collaborators (for example, recovery selection, filing planning, and
output filing) rather than growing a single god-orchestrator. Serialization
decoding should likewise be separated from domain-invariant validation when the
two concerns become entangled.

Two separate graphs — do not mix them:

**Compile-time package dependencies** (strict, no cycles; enforced by SPM):

```text
FlickDomain      -> Foundation only
CECapture     -> FlickDomain
CEIngestion   -> FlickDomain
CESemantic    -> FlickDomain
CEStorage     -> FlickDomain
CEOutput      -> FlickDomain
CEPipelines   -> FlickDomain + CEIngestion + CESemantic + CEStorage + CEOutput
CEUI          -> FlickDomain + CECapture
App           -> all packages (composition root)
```

Sibling infrastructure packages (`CEIngestion`, `CESemantic`, `CEStorage`,
`CEOutput`) do not depend on one another. `CEPipelines` imports the
protocol-bearing packages it orchestrates but does not depend on `CECapture`,
because processing starts only after capture has crossed the durable-write
boundary. `CEUI` depends on `CECapture` only for the capture protocol used by
the UI. The App target is the composition root and may import all packages.

**Runtime pipeline order** (what happens to a capture over time):

```
Capture (any surface → CaptureCoordinator → durable write, App Group store)
  │
  ▼
ProcessingQueue (SwiftData rows with status .pending — the queue IS the rows)
  │
  ▼  CEPipelines drain loop (main-app process only)
CEStorage fetch → CEIngestion → CESemantic → RoutingScorer
  │                                              │
  │ high routing score                           │ low routing score
  ▼                                              ▼
file Task/Event/Note via CEStorage +            mark .unsorted → Unsorted feed
export via CEOutput (EventKit)                   (user resolves once;
                                                  correction tunes routing)
```

## Data / Control Flow

The runtime flow is orchestrated by `CEPipelines`, not by the packages
themselves (see the runtime pipeline diagram under Components):

- Every arrow after the capture layer runs in a Swift concurrency `Task`,
  on an actor isolated away from `MainActor` (not the BackgroundTasks
  framework — scheduled background execution is deferred, ADR-0007); the user
  never waits past the initial write.
- The semantic layer consumes only `IngestedContent { rawText, sourceType, hints }`
  (a `FlickDomain` type), never raw audio/image — keeping `CESemantic` free of
  AVFoundation/Vision.
- `sourceCaptureID` on every output object is non-negotiable: it links each
  structured object back to its raw capture (audit trail + "tap a task, hear the
  original memo"). It is provenance, not the sole uniqueness constraint:
  idempotent output creation is enforced by a deterministic `outputIdempotencyKey`, so a future capture may legitimately produce several outputs without tripping uniqueness. These are two distinct idempotency domains: a nullable request-level `captureRequestID` (`ingressIdempotencyKey`) deduplicates replayed external requests only where the surface can supply a stable request identity — a surface without one treats separate executions as separate requests — while `outputIdempotencyKey` is reserved exclusively for duplicate-resistant visible output effects (ADR-0006).
- Out-of-process surfaces perform capture + durable write only; `CEPipelines`
  in the main app process performs all downstream steps (ADR-0006). The
  execution target is surface-specific (share extension, widget extension,
  app process for `LiveActivityIntent`, per-intent execution target/mode —
  version-gated per the trust-boundary note above), not a single generic
  extension-process model. Each out-of-process target is its own composition
  root for the capture path: it constructs `CaptureCoordinator` with a
  concrete `CaptureStoring` implementation and may wire `CECapture` and
  `CEStorage` only — it must not import `CEPipelines`, `CESemantic`, or
  `CEOutput`.

## Sources of Truth

| Concern | Authority |
|---|---|
| Configuration | `.repo-policy.json` (repo); xcconfig/Info.plist (app target, once created) |
| Persistent data | SwiftData store file + media files beneath the App Group container (media referenced by opaque ID / relative path, never absolute URL) |
| Authentication/authorization | N/A — no accounts; device-level iOS permission grants, requested contextually |
| API/schema | `FlickDomain` structs (pure Swift, Codable) |
| UI design | `DESIGN.md` |
| Release identity | `docs/RELEASES.md` (three-part product versioning: numeric MAJOR.MINOR.PATCH + globally monotonic build integer; 1.0.0 reserved for first App Store release) |

## Failure Boundaries

- **Capture durability:** `Capture` row written with `status: .pending` BEFORE
  anything else can observe it. Saving `.pending` IS enqueueing — there is no
  second durable queue concept. A process-local wake/signal may follow the
  write, but it is not durable state. App killed a millisecond after capture →
  raw capture survives. This ordering holds in every process, including
  extensions (ADR-0006).
- **At-least-once processing with idempotent local output creation:** pending
  captures ARE the queue (no separate queue table). On launch, the recovery
  pass finds `.processing` captures (interrupted mid-run) and returns them to
  `.pending` for the next drain, so execution is inherently at-least-once. Duplicate **local** structured
  outputs are prevented by a persistent uniqueness constraint on the
  deterministic `outputIdempotencyKey`. External side effects such as EventKit export are a
  separate delivery boundary: they require an explicit persisted export state
  machine and MUST NOT be described as effectively-once until ambiguous
  crash-after-save cases have a proven reconciliation policy.
- **Classification failure:** falls back to `RuleBasedBackend`; if that fails or
  the Flick-computed routing score is low → capture stays `.unsorted`,
  surfaced in the Unsorted feed. Nothing is silently dropped or half-filed.
  The model never emits confidence: the `@Generable` schema carries kind,
  structured fields, and evidence (such as quoted source spans); the
  Flick-owned `RoutingScorer` computes a routing score from verifiable
  signals only (evidence validity, required-field completeness, parser
  success, rule/model agreement, ambiguity — ADR-0001).
- **Model unavailability:** `SystemLanguageModel` unavailable/downloading →
  `SemanticError.modelUnavailable` → rule-based path. App is fully functional on
  non-Apple-Intelligence hardware (e.g. iPhone 15 base).
- **Context window budget:** computed at runtime via
  `SystemLanguageModel.contextSize` and `tokenCount(for:)` (ADR-0001). The
  overflow strategy for over-budget captures is deliberately deferred: it is a
  measured 0.4.0 decision over Apple's recommended options (smaller
  sessions/chunks, selecting important context, summarization — of which
  summarization is only one option), not a hard-coded pre-summarization
  requirement. No baked-in token constants.
- **Session isolation:** one fresh `LanguageModelSession` per capture — never reused
  across unrelated captures (avoids context bleed).

## Concurrency / Lifecycle

- Swift 6 language mode with strict concurrency checking enabled from day one.
- Capture path: main-actor UI → async `CaptureCoordinator` methods; return once the
  file/row is written, not once transcribed.
- Post-capture pipeline (`ingest → classify → file/output`) runs off the main actor.
- Storage and queue access go through a dedicated `@ModelActor`: the actor serializes its `ModelContext`, and `PersistentIdentifier` is the `Sendable` handle for crossing actor boundaries — a `ModelContext` or managed object is never passed across.
- One `LanguageModelSession` per capture (stateless classification).

## Deployment / Runtime Assumptions

- iOS 26+ deployment target; iPhone-first including iPhone Duo
  (outer/inner/folded — no fixed display/orientation assumptions; size classes,
  safe areas, layout margins only). iPad adaptive layout is post-MVP.
- Swift 6, SwiftUI, SPM multi-package layout under `Packages/`:
  `FlickDomain`, `CECapture`, `CEIngestion`, `CESemantic`, `CEStorage`,
  `CEOutput`, `CEPipelines`, `CEUI`; app target under `App/`
  (`App/Flick.xcodeproj`, created on a Mac).
- Foundation Models (`SystemLanguageModel`) available only on
  Apple-Intelligence-eligible hardware; runtime capability check selects the backend.
- Local-processing data-egress property holds for the MVP (ADR-0005):
  user capture content does not egress to an app-controlled or third-party
  network service during the local processing path; Apple-managed model asset
  provisioning may use the network.
- Screenshot/photo import uses PhotosPicker where possible (selected-item
  access requires no Photo Library authorization).
- Distribution via TestFlight / App Store; no server infrastructure.

## Compatibility Constraints

- Deployment target iOS 26+ (uses SpeechAnalyzer, Foundation Models framework).
- Apple-Intelligence-eligible hardware required for the LLM backend; rule-based
  backend has zero hardware requirement — the app MUST NOT be non-functional on
  older devices.
- SwiftData for structured storage; SQLite FTS5 (or `NSPredicate` full-text if
  volume stays low) for the search index.
- EventKit identifiers stored back on drafts as references; calendar permission
  requested contextually on first event creation, never at launch; write-only
  access for create-only export by default. Write-only authorization cannot
  fetch even Flick-created events, so update/delete/reconciliation requires
  explicit full access or EventKitUI user-managed edits (ADR-0002).

## Key Performance Constraints

- **Capture latency (SLO, not a correctness guarantee):** input → durable local record
  in < 300 ms, measured on representative physical hardware with warm-app and
  cold-entry numbers recorded separately. Classification is async and never
  blocks capture.
- **Time-to-capture:** sub-2 seconds from any surface (widget tap → recording).
- **Idempotent local pipeline effects:** at-least-once processing with duplicate-resistant local structured-output creation, enforced by a persistent `outputIdempotencyKey` uniqueness constraint (`sourceCaptureID` remains provenance only). External exports use their own delivery/reconciliation state machine.

## ADR Index

See `docs/adr/README.md`. All records below are **Proposed** (none accepted):

- ADR-0001: Foundation Models Primary Backend with Rule-Based Fallback.
- ADR-0002: Own Task Model; EventKit Write-Only Export by Default (create-only; ambiguous external saves are not blindly retried).
- ADR-0003: SwiftData Structured Store with App Group Media Files.
- ADR-0004: FlickDomain Is Foundation-Only.
- ADR-0005: Local-Processing Data-Egress Property.
- ADR-0006: App Group Persistence and Capture-Surface Execution Boundaries (surface-specific targets; ingress idempotency separate from output idempotency; extension composition root).
- ADR-0007: Apple Sample-Code Extrapolation Rulings.

## Text state and diagnostic ownership

CEUI owns transient idle/saving/saved/failed presentation; the two-second Saved
indicator follows durable acknowledgement. Feed status comes from persisted
snapshots. A failed drain marks unfinished rows as needing recovery without
pretending their durable status changed. Storage, capture, pipeline, and app
composition write their own structured OSLog events. FlickDomain supplies only
a Foundation-based diagnostic value/serializer; it imports neither OSLog nor
SwiftData. Safe error taxonomy is separate from short user-facing copy.
