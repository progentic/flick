# ADR-0004: FlickDomain Is Foundation-Only

Status: Proposed\
Date: 2026-09-11\
Owners: Ian Gordon

## Context

`FlickDomain` is the shared vocabulary between capture, ingestion, semantic, storage, output, UI, and future companion targets.

An earlier stdlib-only idea is unnecessarily restrictive. Real domain objects need stable value types such as dates, UUIDs, time-zone/locale-aware values, Codable support, and other Foundation primitives.

At the same time, allowing platform-service frameworks into `FlickDomain` would couple the core model to persistence, UI, media, or Apple service implementations.

## Decision

`FlickDomain` may depend on Foundation and no higher-level feature framework.

Permitted examples include:

- `Date`
- `UUID`
- `TimeZone`
- `Locale`
- `URL` only where it represents a logical external URL rather than a persisted sandbox file identity
- `Codable`
- `Sendable`
- standard Foundation collections/value types

`FlickDomain` owns pure domain structs and enums such as:

- `Capture`
- `IngestedContent`
- `TaskItem`
- `CalendarEventDraft`
- `NoteItem`
- `ProjectCluster`
- routing/output state enums
- source/provenance identifiers

`FlickDomain` does **not** import or expose implementation types from:

- SwiftData
- EventKit
- AVFoundation
- Speech
- Vision
- NaturalLanguage
- FoundationModels
- SwiftUI / UIKit
- WidgetKit
- ActivityKit
- AppIntents
- Core Spotlight

Persistence adapters, framework handles, and UI-specific objects remain in their owning packages.

## Invariants / Constraints

- Domain types remain value-oriented and framework-agnostic above Foundation.
- SwiftData `@Model` classes are adapters, not domain authorities.
- EventKit identifiers may be stored as primitive provenance values, but EventKit types never cross into `FlickDomain`.
- Raw media framework objects never cross into `FlickDomain`.
- Domain values crossing concurrency boundaries must be designed for `Sendable` use where appropriate.
- App Group file references use opaque media IDs or relative paths rather than absolute sandbox URLs.

## Alternatives Considered

### Stdlib-only domain

Rejected because it adds friction without a meaningful architectural benefit.

### Allow persistence annotations in domain objects

Rejected because it makes storage implementation the domain authority and creates unnecessary coupling.

### Allow Apple service/framework types directly in domain structs

Rejected because it would spread framework availability and lifecycle concerns across package boundaries.

## Consequences

### Positive

- Reusable domain layer for iOS and future companion targets.
- Easier unit testing and serialization.
- Framework boundaries stay explicit.
- Storage and platform integrations can change without redefining the product model.

### Negative / Trade-offs

- Adapter code is required between domain structs and framework-specific types.
- Some identifiers must be represented as primitive values rather than native framework objects.

## Validation

- Package dependency checks verify `FlickDomain` imports Foundation only.
- CI rejects prohibited framework imports under `Packages/FlickDomain`.
- Persistence and EventKit tests use adapters rather than framework types embedded in domain structs.
