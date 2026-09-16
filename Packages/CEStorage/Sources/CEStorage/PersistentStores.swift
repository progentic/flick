import FlickDomain
import Foundation

/// Resolves opaque media IDs to file URLs beneath the App Group container
/// at read time. Absolute sandbox URLs are never persisted (ADR-0003).
public protocol MediaResolving: Sendable {
    func url(for mediaID: String) throws -> URL
}

/// The durable queue: pending captures ARE the queue (no separate table).
/// The drain claims rows (.pending → .processing); the launch recovery pass
/// re-enqueues rows stuck in .processing after a crash/kill.
public protocol ProcessingQueue: Sendable {
    /// Atomically claims the next pending capture for processing.
    func claimNextPending() async throws -> Capture?
    /// Re-enqueues interrupted captures. Returns the count re-enqueued.
    func requeueInterrupted() async throws -> Int
    /// Atomically changes a claimed capture from `.processing` to `.unsorted`.
    /// No filing plan exists on this route.
    func markUnsorted(captureID: UUID) async throws
    /// Atomically changes a claimed capture from `.processing` to the
    /// terminal `.failed` state. Reserved for deterministic invariant
    /// violations that no retry can fix — an auto-file classification that
    /// cannot materialize any output. A failed capture is never re-claimed;
    /// the drain continues with the next capture. No filing plan exists on
    /// this route: the violation is detected before any plan is persisted.
    func markFailed(captureID: UUID) async throws
}

/// Persistence seam for Flick-owned task outputs. A future concrete SwiftData
/// implementation belongs in CEStorage so external output integrations stay
/// persistence-agnostic.
public protocol TaskStoring: Sendable {
    /// Inserts by `outputIdempotencyKey`, or returns the existing output's ID
    /// when the key is already present. The returned ID is the canonical ID
    /// that must be written to `Capture.linkedObjectIDs`.
    func save(_ task: TaskItem) async throws -> UUID
    func tasks() async throws -> [TaskItem]
}

/// Persistence seam for Flick-owned note outputs.
public protocol NoteStoring: Sendable {
    /// Inserts by `outputIdempotencyKey`, or returns the existing output's
    /// canonical ID when a retry encounters the same key.
    func save(_ note: NoteItem) async throws -> UUID
    func notes() async throws -> [NoteItem]
}

/// Persistence seam for Flick-owned calendar drafts. Saving a new draft also
/// creates its pending EventKit-delivery record in the same transaction. A
/// separate delivery worker owns the EventKit state machine; the retryable
/// filing loop never calls EventKit directly because a crash after an external
/// save has an ambiguous result under write-only access (ADR-0002, ADR-0006).
public protocol EventDraftStoring: Sendable {
    /// Inserts by `outputIdempotencyKey`, or returns the existing draft's
    /// canonical ID when a retry encounters the same key.
    func save(_ draft: CalendarEventDraft) async throws -> UUID
    func drafts() async throws -> [CalendarEventDraft]
}

/// Durable persistence seam for `FilingPlan`. The orchestrator persists the
/// complete plan BEFORE the first filing side effect; a retry resumes the
/// persisted plan instead of re-running classification, whose result ordering
/// is not stable across runs. The plan is removed once its capture is fully
/// processed. A future concrete SwiftData implementation belongs in CEStorage
/// (ADR-0006).
public protocol FilingPlanStoring: Sendable {
    /// Atomically inserts the candidate when no plan exists for its capture.
    /// If one already exists, leaves it unchanged and returns that stored plan.
    /// A plan is immutable after insertion because an earlier attempt may have
    /// begun filing its entries.
    func saveIfAbsent(_ candidate: FilingPlan) async throws -> FilingPlan
    /// Returns the persisted plan for a capture, when a previous attempt
    /// persisted one before being interrupted.
    func plan(for captureID: UUID) async throws -> FilingPlan?
    /// In one durable transaction: changes the capture from `.processing` to
    /// `.filed`, writes the canonical output IDs in filing order, and removes
    /// its plan. If the transaction does not commit, the capture remains
    /// recoverable with its plan intact.
    func completeFiling(captureID: UUID, linkedObjectIDs: [UUID]) async throws
}

// Future implementation: the concrete store will use SwiftData `@Model` adapters
// over the FlickDomain structs (import SwiftData) with the store file beneath
// the App Group container (ADR-0003, ADR-0006). FlickDomain itself stays
// persistence-agnostic (ADR-0004).
