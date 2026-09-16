import Foundation

/// Structured task extracted from a capture. Stored in our own SwiftData-backed
/// `TaskStore` — Reminders/EventKit is deliberately NOT used (ADR-0002).
public struct TaskItem: Identifiable, Codable, Sendable {
    private static let outputKind: OutputKind = .task

    public let id: UUID
    public var title: String
    public var dueDate: Date?
    public var subtasks: [String]
    public var projectID: UUID?
    /// Provenance: the capture this task was filed from. Immutable, because
    /// the idempotency key is computed from it — mutating provenance would
    /// silently change the task's supposedly stable identity (ADR-0006).
    public let sourceCaptureID: UUID
    public var completedAt: Date?
    /// This task's stable ordinal within its `FilingPlan`. Assigned by the
    /// plan and carried on the entry — never defaulted, never invented at the
    /// filing site. Together with the capture ID and kind it determines the
    /// idempotency key.
    public let filingOrdinal: UInt

    /// Duplicate-resistant identity for this task's visible effect, derived
    /// from this task's own capture ID, kind, and filing ordinal — it cannot
    /// name another capture or kind. The storage layer enforces uniqueness on
    /// this key so at-least-once reprocessing cannot file the same task twice
    /// (ADR-0006).
    public var outputIdempotencyKey: OutputIdempotencyKey {
        OutputIdempotencyKey.derive(captureID: sourceCaptureID, kind: Self.outputKind, ordinal: filingOrdinal)
    }

    /// Files the task described by a persisted plan entry. The entry supplies
    /// the capture identity, the materialized payload, and the stable
    /// ordinal, so a retry resumes the persisted intent instead of
    /// regenerating the task from re-classification. There is no overload
    /// accepting a separate capture: pairing an entry with any capture other
    /// than the one it was planned from would key the output to the wrong
    /// capture (ADR-0006).
    public init(entry: FilingPlan.Entry, id: UUID = UUID()) throws {
        guard case let .task(title, dueDate, subtasks) = entry.intent else {
            throw DomainError.mismatchedFilingIntent(expected: .task, actual: entry.intent.kind)
        }
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.subtasks = subtasks
        self.sourceCaptureID = entry.captureID
        self.filingOrdinal = entry.ordinal
    }
}
