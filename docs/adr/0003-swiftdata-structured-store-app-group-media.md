# ADR-0003: SwiftData Structured Store with App Group Media Files

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

Flick must durably preserve captures before transcription, OCR, classification, or export begins.

Structured objects and large binary media have different storage needs. Captures, processing state, tasks, notes, calendar drafts, and project metadata are naturally modeled as structured records. Raw audio and imported images are better represented as files.

Flick also plans out-of-process capture surfaces. Those surfaces need a shared persistence location that the main app can later consume.

Absolute sandbox URLs are not stable identifiers across installation/container changes and must not become domain data.

## Decision

### SwiftData stores structured state

SwiftData is the structured persistence layer for:

- captures
- capture processing state
- local tasks
- notes
- calendar event drafts
- project/organization metadata
- external-export state
- persistent idempotency keys

`CEStorage` owns SwiftData implementation details through thin persistence adapters. `FlickDomain` remains free of SwiftData model annotations.

### The App Group container is the shared storage location

The SwiftData store and shared capture media are placed beneath the configured App Group container.

This decision establishes a storage location. It does **not** by itself prove safe or reliable multi-process SwiftData behavior. That concurrency assumption remains provisional until the 0.3.0 cross-process spike in ADR-0006.

### Media is stored as files

Raw audio and imported images are stored as files, not embedded as large SwiftData payloads by default.

Structured records reference media through:

- opaque media identifiers, and/or
- paths relative to the App Group media root

Absolute sandbox URLs are never persisted as durable identity.

### Media write ordering

A structured record must never claim durable media that cannot be located.

Capture implementations therefore use a staged media write:

1. allocate an opaque media identity / relative path
2. write or finalize the media file in the App Group media area
3. persist/update the structured record that references that media
4. only after the durable capture state exists may downstream processing begin

Long-running recording may maintain an in-progress record and file, but the raw file remains authoritative and interruption recovery must be able to finalize or mark the recording incomplete without silently discarding it.

Orphan files are acceptable after a crash; dangling structured references are not. Orphan cleanup is an explicit maintenance task.

## Invariants / Constraints

- Downstream processing starts only after durable capture state exists.
- Raw media is authoritative input; transcripts/OCR are derived data.
- Persisted domain objects never contain absolute sandbox URLs.
- `CEStorage` owns persistence details; `FlickDomain` owns portable value semantics.
- App Group placement does not imply proven multi-process safety.
- Deleting a capture must have an explicit policy for linked media and derived outputs.

## Alternatives Considered

### Store raw media directly in SwiftData

Rejected as the default because media files have different lifecycle, streaming, replay, and recovery needs from structured records.

### Store absolute file URLs

Rejected because sandbox/container paths are not durable identity.

### Per-extension media/store roots with later merge

Rejected because it complicates ownership, recovery, and duplicate handling.

### Assume App Group configuration proves concurrent store safety

Rejected. That behavior must be established by integration tests on the supported OS/toolchain.

## Consequences

### Positive

- Clean separation between structured state and large media.
- Stable media identity across process boundaries.
- App/extension code can share one conceptual persistence root.
- Domain models remain portable and testable.

### Negative / Trade-offs

- Media and structured state require coordinated lifecycle handling.
- Crash recovery must sweep orphaned media.
- Multi-process persistence remains a test-backed, not configuration-backed, guarantee.

## Validation

- Store-path tests verify the configured App Group location.
- Persistence adapters never serialize absolute sandbox URLs.
- Kill/relaunch tests verify that durable captures retain usable media references.
- Orphan-media cleanup is tested independently from capture correctness.
- 0.3.0 performs a real cross-process persistence spike before multi-writer behavior is treated as accepted.
