import Foundation

/// Note extracted from a capture. `fullText` feeds search; `summary` is the
/// one-line display form.
public struct NoteItem: Identifiable, Codable, Sendable {
    private static let outputKind: OutputKind = .note

    public let id: UUID
    public var summary: String
    public var fullText: String
    public var entities: [String]
    public var projectID: UUID?
    /// Provenance: the capture this note was filed from. Immutable, because
    /// the idempotency key is computed from it — mutating provenance would
    /// silently change the note's supposedly stable identity (ADR-0006).
    public let sourceCaptureID: UUID
    /// This note's stable ordinal within its `FilingPlan`. Assigned by the
    /// plan and carried on the entry — never defaulted, never invented at the
    /// filing site. Together with the capture ID and kind it determines the
    /// idempotency key.
    public let filingOrdinal: UInt

    /// Duplicate-resistant identity for this note's visible effect, derived
    /// from this note's own capture ID, kind, and filing ordinal — it cannot
    /// name another capture or kind. The storage layer enforces uniqueness on
    /// this key so at-least-once reprocessing cannot file the same note twice
    /// (ADR-0006).
    public var outputIdempotencyKey: OutputIdempotencyKey {
        OutputIdempotencyKey.derive(captureID: sourceCaptureID, kind: Self.outputKind, ordinal: filingOrdinal)
    }

    /// Files the note described by a persisted plan entry. The entry supplies
    /// the capture identity, the materialized payload, and the stable
    /// ordinal, so a retry resumes the persisted intent instead of
    /// regenerating the note from re-classification. There is no overload
    /// accepting a separate capture: pairing an entry with any capture other
    /// than the one it was planned from would key the output to the wrong
    /// capture (ADR-0006).
    public init(entry: FilingPlan.Entry, id: UUID = UUID()) throws {
        guard case let .note(summary, fullText, entities) = entry.intent else {
            throw DomainError.mismatchedFilingIntent(expected: .note, actual: entry.intent.kind)
        }
        self.id = id
        self.summary = summary
        self.fullText = fullText
        self.entities = entities
        self.sourceCaptureID = entry.captureID
        self.filingOrdinal = entry.ordinal
    }
}
