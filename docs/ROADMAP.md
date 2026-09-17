# Flick Product Roadmap

Version: 1.3\
Last Reviewed: 2026-09-17\
Status: Active planning document

## Purpose

This is the rolling product plan from the repository bootstrap baseline to the
first production App Store release, `1.0.0`.

The roadmap defines sequencing, product outcomes, architectural proof points,
and release gates. It is intentionally revisable: implementation evidence,
platform behavior, usability findings, or an ADR revision may change tasks
without changing Flick's core product promise.

`1.0.0` is not a shell, framework demo, or collection of disconnected
capabilities. It is a complete, coherent, well-designed iPhone application.

## Version model

- `0.0.0`: blank/unproven repository state. Not a product release.
- `0.0.1`: reproducible repository/bootstrap baseline.
- `0.1.0`: first real, usable Flick application increment.
- Pre-1.0 MINOR releases: meaningful product increments.
- `0.x.y` patch releases: compatible fixes after a milestone is cut.
- `1.0.0`: first production App Store release.
- Product version uses numeric `MAJOR.MINOR.PATCH`.
- Build number is a monotonically increasing integer.

## Current baseline

The `0.0.1` bootstrap baseline is represented by commit:

`f802005ad49e9b3074cbc2bc35d6212dedc2ade8`

That commit established eight package manifests, repository governance, hosted
CI, documentation, and 41 `FlickDomain` tests. Repository Governance and Swift
Packages passed against that exact source revision.

`0.1.0 — Text Flick / Running Kernel` is **ACCEPTED** and frozen at annotated
tag `v0.1.0`, targeting `2ec113ca9ea94092d2a00f38a3280938bc08d17f`.
The bootstrap is tagged `v0.0.1` at the commit above.
See [the final verification record](verification/v0.1.0/ACCEPTANCE.md).

The next development milestone is **`0.2.0 — Voice Flick`**. Its implementation
has not begun as part of the v0.1.0 release bookkeeping.

A tag or release must always resolve to the exact validated commit; mutable
release metadata never substitutes for source/CI evidence.

# Product-development model

## Every milestone is a vertical product increment

A MINOR milestone is not complete merely because its framework API works or its
architecture compiles.

Each milestone advances four tracks together:

1. **Product / UI**
   - complete user interaction for the capability;
   - Apple HIG-native behavior;
   - empty/loading/success/error/permission states;
   - accessibility and motion behavior;
   - visual integration with the existing app.

2. **Domain / Reliability**
   - durable state and lifecycle ownership;
   - recovery after interruption;
   - idempotency where effects may repeat;
   - migration/compatibility impact;
   - create/edit/delete semantics appropriate to that capability.

3. **Platform Capability**
   - the Apple framework or device capability that enables the feature;
   - runtime availability/permission behavior;
   - explicit process and trust boundaries.

4. **Verification**
   - unit/integration/UI evidence appropriate to the change;
   - negative controls;
   - performance measurements where relevant;
   - rendered UI evidence;
   - human visual approval for HIGH-criticality UI;
   - hosted CI against the exact source revision.

A milestone does not close while one of these tracks is knowingly incomplete.

## Continuous quality rules

These apply from the first application milestone onward.

- **HIG and accessibility are continuous.** `0.8.0` is the comprehensive audit,
  not the first implementation of Dynamic Type, VoiceOver, contrast, touch
  targets, safe areas, reduced motion, or native navigation.
- **UI debt stays with the feature that creates it.** Voice UX is finished in
  the voice milestone; image/share UX is finished in the image/share milestone.
- **Every capability has failure UX.** Permission denial, persistence failure,
  transcription failure, model unavailability, unresolved routing, and
  ambiguous external export states must be understandable and recoverable where
  recovery is possible.
- **Lifecycle semantics ship with creation semantics.** When Flick begins
  creating a new user-owned object, deletion/ownership behavior is defined in
  that milestone. Editing may be staged only when the roadmap explicitly says
  so.
- **Persistence migrations begin with schema V1.** After `0.1.0`, schema changes
  must preserve or deliberately migrate prior development data.
- **Native integration must earn its place.** Widgets, Live Activities,
  Shortcuts, Action Button integration, and similar surfaces ship only when
  they make Flick materially faster or more natural.
- **No late "make it good" phase.** `0.8.0` hardens an already coherent app; it
  does not rescue unfinished feature UX from earlier releases.

# Milestone map

| Version | Product increment | Completion proof |
|---|---|---|
| `0.0.1` | Repository baseline | Reproducible packages, governance, CI, docs |
| `0.1.0` | Text Flick | Real native app; durable text capture, feed, recovery, local Note |
| `0.2.0` | Voice Flick | Record, persist, transcribe, playback, recover, delete |
| `0.3.0` | Image / Share Flick | Explicit image/share capture, OCR, handoff, recovery |
| `0.4.0` | Smart Flick | Task/event/note interpretation, fallback, Unsorted/correction UX |
| `0.5.0` | Useful structured outputs | Editable outputs + least-privilege calendar export |
| `0.6.0` | System-native Flick | Appropriate App Intents/Shortcuts/system surfaces |
| `0.7.0` | Find and manage Flick | Search, organization, indexing, complete lifecycle |
| `0.8.0` | Product-quality complete | Final visual/accessibility/performance/device hardening |
| `0.9.0` | Release complete | TestFlight, migrations, privacy, signing, release gates |
| `1.0.0` | Production | Finished validated App Store application |

# 0.1.0 — Text Flick / Running Kernel

## Product objective

Ship the first real Flick experience.

A user can launch Flick, immediately understand the primary action, type a
thought, persist it, see it in a native chronological feed, leave or kill the
app, return, and find the thought intact. Flick processes the durable capture
asynchronously and materializes exactly one local `NoteItem`.

This milestone is deliberately text-only. It proves the interaction and
reliability model that every later capture surface will reuse.

## Product promise

> A typed thought is durably saved before Flick says it is saved, survives
> process interruption, appears naturally in the feed, and creates one local
> Note without duplicate effects.

## Phase A — Native application foundation

### Platform

- create `App/Flick.xcodeproj`;
- create a shared `Flick` scheme;
- iOS 26 minimum;
- Swift 6 language mode with strict concurrency;
- wire all local packages without creating package cycles;
- establish bundle identifier and App Group identifier;
- App target remains composition/lifecycle only.

### Product / UI

Build the first coherent native shell, not a placeholder screen:

- native SwiftUI navigation and toolbar behavior;
- first-run/empty feed state;
- text capture interaction;
- chronological feed;
- persisted/saving/failure feedback;
- Light and Dark Mode;
- Dynamic Type, including accessibility sizes;
- VoiceOver semantics and logical traversal;
- safe-area/adaptive layout behavior;
- Reduce Motion behavior;
- minimum 44×44 pt primary interaction regions.

Before final visual approval:

- replace the draft ember/paper/ink token values that currently fail the design
  contract's contrast requirements;
- record final adaptive tokens in `DESIGN.md`;
- update `UI-REVIEW.md`;
- render representative UI evidence;
- obtain required human visual approval because aesthetic criticality is HIGH.

### Phase A exit

The app launches on a supported simulator/device and presents a credible,
HIG-native Flick shell. No fake persistence or fake "saved" state is allowed.

## Phase B — Persistence and durable queue

Implement SwiftData schema V1 for the minimum 0.1.0 domain:

- `Capture`;
- `NoteItem`;
- processing state;
- source/provenance relationship;
- deterministic local-output idempotency key;
- nullable ingress idempotency field reserved for later surfaces.

Requirements:

- explicit `ModelConfiguration`;
- reserve App Group storage location from day one;
- `.pending` capture rows are the durable queue;
- state machine for 0.1.0:
  `pending → processing → filed | failed`;
- durable capture write precedes processing;
- launch/foreground recovery returns interrupted processing to a safe retry path;
- `sourceCaptureID` is provenance, not the uniqueness key;
- output creation is idempotent under repeated processing;
- no semantic classification;
- no EventKit;
- no BackgroundTasks dependency for correctness.

Define deletion ownership for the 0.1.0 text capture + Note relationship so the
first user-created object does not ship without lifecycle semantics.

### Phase B exit

Kill/relaunch around each durable transition without losing a capture or
creating duplicate local output.

## Phase C — Text vertical slice

Implement the complete text path:

```text
Text entry
  ↓
CaptureCoordinator.captureText
  ↓
durable Capture(status: .pending)
  ↓
persisted feed reflects capture
  ↓
CEPipelines
  ↓
text pass-through ingestion
  ↓
0.1.0 kernel router
  ↓
exactly one NoteItem
  ↓
Capture(status: .filed)
```

User-facing requirements:

- user can create a text thought;
- UI only confirms save after durable persistence succeeds;
- item appears in the feed from durable state;
- processing is understandable but unobtrusive;
- completed Note presentation remains native and readable;
- persistence failure offers a clear retry path;
- basic local deletion follows the ownership rule established in Phase B.

Do not introduce pseudo-semantic classification merely to make the pipeline
appear more intelligent. Semantic routing begins in `0.4.0`.

## Phase D — Reliability and negative controls

Required evidence:

- kill after durable capture, before processing;
- kill during processing;
- relaunch recovery;
- same output-idempotency key processed repeatedly → one local Note;
- two independent identical-text captures → two captures/Notes;
- persistence failure does not show a false saved state;
- app launch with existing data;
- schema V1 initialization and reopening;
- deletion lifecycle;
- no main-thread blocking during post-capture processing.

Performance:

- measure capture-to-durable-record latency;
- record warm and cold-path observations;
- `<300 ms` remains a target/SLO, not a correctness assertion.

## Phase E — 0.1.0 product integration gate

### Product/UI

- empty, capture, saving, filed, and failure states reviewed;
- final 0.1.0 visual evidence captured;
- Apple HIG matrix complete;
- VoiceOver/Dynamic Type/contrast/reduced-motion checks complete;
- human visual approval recorded in `UI-REVIEW.md`.

### Engineering

- package tests pass;
- new persistence/pipeline/app tests pass;
- repository governance passes;
- UI governance passes;
- app builds through hosted macOS CI;
- no placeholder tests are used as evidence;
- `CHANGELOG.md` accurately describes implemented changes;
- `MANIFEST.txt` reflects the checkout;
- governing docs/ADRs are reconciled to actual implementation.

### 0.1.0 definition of done

A new user can launch Flick and successfully use it as a small but real text
capture application without knowing that later voice, image, semantic, and
system-surface capabilities are still pending.

The app must be reliable, accessible, visually intentional, and native-feeling
within this deliberately narrow scope.

# 0.2.0 — Voice Flick

## User outcome

A user can record a thought naturally and trust Flick not to lose it.

## Scope

- native record/stop interaction integrated into the existing capture surface;
- durable raw audio before transcription completion;
- SpeechAnalyzer/SpeechTranscriber as the preferred iOS 26 path;
- locale/model-asset behavior;
- transcript persisted as derived data;
- playback from the feed/detail experience;
- interruption handling;
- transcription retry UX;
- deletion lifecycle for audio + transcript + linked output;
- permission-denied/restricted UX.

Transcription failure is ingestion failure, not Unsorted.

## Exit

Record → stop → persist → transcribe → display/playback → relaunch → recover →
delete works as one coherent user flow.

Voice UI/accessibility/error handling is complete enough that `0.8.0` does not
need to redesign it.

# 0.3.0 — Image / Share Flick

## User outcome

A user can explicitly send an image or screenshot to Flick and trust the handoff.

## Scope

- PhotosPicker import where appropriate;
- Share-to-Flick extension;
- durable image/media identity and App Group handoff;
- Vision OCR → `IngestedContent`;
- explicit image preview/source affordance;
- OCR error/retry UX;
- cross-process persistence/concurrency spike;
- out-of-process target performs capture + durable write only;
- no silent post-relaunch Photo Library crawl;
- deletion lifecycle for imported media and derived data.

## Exit

Import/share → durable handoff → OCR → feed representation → relaunch/recovery →
delete is complete, with extension boundaries proven rather than assumed.

# 0.4.0 — Smart Flick

## User outcome

Flick begins organizing captures without requiring the user to file them.

## Scope

- production non-generative rule-based backend;
- NaturalLanguage features where useful;
- general/default Foundation Models backend;
- small `@Generable` interpretation schema;
- one fresh session per unrelated capture;
- runtime model availability and token budgeting;
- model emits interpretation/evidence, not authoritative confidence;
- Flick-owned `RoutingScorer`;
- Task / Event / Note interpretation;
- Unsorted state;
- user correction flow;
- correction is understandable and does not destroy the raw capture;
- long-input strategy chosen from regression evidence;
- classification/model unavailable/error states integrated into existing UI.

## Exit

Every supported device has a usable semantic path. Model availability never
blocks capture. Users can understand and correct uncertain routing.

# 0.5.0 — Useful Structured Outputs

## User outcome

Flick's interpreted content becomes actionable rather than merely classified.

## Scope

- complete local `TaskItem`, `NoteItem`, and `CalendarEventDraft` experiences;
- detail/edit flows;
- creation/deletion lifecycle;
- source provenance back to the raw capture;
- output idempotency;
- correction/reclassification behavior;
- EventKit write-only permission by default;
- write-only calendar mode is create-only;
- managed read/update/delete requires explicit full calendar access;
- ambiguous external save is surfaced and never blindly retried.

## Exit

Notes, tasks, and event drafts are useful, editable product objects with coherent
lifecycle and error behavior.

# 0.6.0 — System-Native Flick

## User outcome

Capture is available from appropriate iOS surfaces without opening the main app
first.

## Candidate surfaces

- App Intents / Shortcuts;
- Action Button where supported;
- widgets/controls where they materially reduce capture friction;
- recording Live Activity only if it meaningfully improves active recording.

## Rules

- each surface declares its actual execution/process boundary;
- every surface uses the same durable capture contract;
- out-of-process targets do capture + durable handoff only;
- iOS 26 behavior does not depend on iOS 27-only execution-target APIs;
- surface-specific replay/idempotency guarantees are documented only where the
  platform supplies/preserves a stable request identity;
- each surface has accessibility, failure, and permission behavior.

## Exit

System integration feels like an extension of Flick's native capture model, not
a collection of framework demos.

# 0.7.0 — Find and Manage Flick

## User outcome

A growing Flick history remains useful rather than becoming a new junk drawer.

## Scope

- local full-text search;
- Core Spotlight integration;
- organization/project clustering where evidence supports it;
- filtering/browsing needed for real accumulated use;
- edit/delete lifecycle across captures, outputs, media, and indexes;
- storage cleanup/orphan handling;
- full-access managed-calendar reconciliation only when explicitly enabled.

## Feature-complete gate

At the end of `0.7.0`, the intended `1.0.0` feature set is complete.

No major user-facing capability required for the 1.0 product promise should be
intentionally deferred to `0.8.0`.

# 0.8.0 — Product-Quality Complete

## Objective

Turn a feature-complete Flick into a production-quality Flick without adding a
new core product category.

## Scope

- comprehensive Apple HIG review;
- final visual-system/token review;
- accessibility audit;
- VoiceOver traversal across all features;
- Dynamic Type stress testing;
- contrast/high-contrast modes;
- Reduce Motion;
- supported device configurations and adaptive layouts;
- large-data/feed/search performance;
- launch/capture latency;
- battery and storage behavior;
- media cleanup;
- long-session behavior;
- permission and error-state consistency;
- privacy/security review;
- final HIGH-criticality human visual approvals.

## Product-quality gate

At the end of `0.8.0`, the app is expected to look, feel, and behave like the
product intended for release.

This phase does not absorb unfinished feature UX from earlier milestones.

# 0.9.0 — Release Complete / Release Candidate

## Objective

Prove the production candidate can be distributed, upgraded, supported, and
reviewed.

## Scope

- TestFlight candidate;
- schema/data migration rehearsal from supported pre-release state;
- clean-install and upgrade testing;
- signing/provisioning/release automation;
- privacy manifest / privacy labels / public privacy policy;
- crash/diagnostics policy;
- security review and PVR readiness;
- App Store metadata/screenshots;
- release notes;
- final regression suite;
- no unresolved release blocker.

## Release-complete gate

The exact candidate commit can be signed and submitted without code or UX work
being required to make the product complete.

# 1.0.0 — Production

## Definition

Flick 1.0 is a complete iPhone application that lets a user:

- capture text, voice, and supported image/share input with minimal friction;
- trust that every accepted capture is durably preserved;
- receive useful local notes, tasks, and event drafts;
- understand and correct uncertain organization;
- edit, delete, search, and manage accumulated information;
- use appropriate native iOS capture surfaces;
- recover cleanly from supported interruption/failure states.

The app:

- behaves like a native first-party-quality iOS application while retaining a
  distinct Flick identity;
- meets the repository's HIG/accessibility requirements;
- meets documented privacy and local-processing boundaries;
- has validated persistence, migration, recovery, performance, and lifecycle
  behavior;
- ships from the exact validated, signed release commit.

`1.0.0` is not reached merely because an App Store archive can be produced.

# Completion ladder

```text
0.7.0   FEATURE COMPLETE
          ↓
0.8.0   PRODUCT-QUALITY COMPLETE
          ↓
0.9.0   RELEASE COMPLETE
          ↓
1.0.0   PRODUCTION RELEASE
```

# Post-1.0 candidates

These are intentionally outside the 1.0 promise unless later product evidence
changes the roadmap:

- CloudKit sync after a separate security/cryptography ADR;
- iPad-specific product design;
- watchOS/macOS companions;
- collaboration/sharing.
