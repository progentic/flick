import Foundation

/// Calendar event extracted from a capture. Exported via `EventKitAdapter`
/// with write-only permission by default (ADR-0002).
public struct CalendarEventDraft: Identifiable, Codable, Sendable {
    private static let outputKind: OutputKind = .event

    public let id: UUID
    public var title: String
    public var start: Date
    public var end: Date?
    public var location: String?
    /// Provenance: the capture this draft was filed from. Immutable, because
    /// the idempotency key is computed from it — mutating provenance would
    /// silently change the draft's supposedly stable identity (ADR-0006).
    public let sourceCaptureID: UUID
    /// This draft's stable ordinal within its `FilingPlan`. Assigned by the
    /// plan and carried on the entry — never defaulted, never invented at the
    /// filing site. Together with the capture ID and kind it determines the
    /// idempotency key.
    public let filingOrdinal: UInt
    /// Export provenance only. This identifier grants no read/update/delete
    /// capability under write-only calendar authorization.
    public var eventKitIdentifier: String?

    /// Duplicate-resistant identity for this draft's local filing, derived
    /// from this draft's own capture ID, kind, and filing ordinal — it cannot
    /// name another capture or kind. Guards the local draft filing step; the
    /// EventKit export itself is a separate delivery boundary with its own
    /// ambiguous-state handling (ADR-0002, ADR-0006).
    public var outputIdempotencyKey: OutputIdempotencyKey {
        OutputIdempotencyKey.derive(captureID: sourceCaptureID, kind: Self.outputKind, ordinal: filingOrdinal)
    }

    /// Files the draft described by a persisted plan entry. The entry supplies
    /// the capture identity, the materialized payload, and the stable
    /// ordinal, so a retry resumes the persisted intent instead of
    /// regenerating the draft from re-classification. There is no overload
    /// accepting a separate capture: pairing an entry with any capture other
    /// than the one it was planned from would key the output to the wrong
    /// capture (ADR-0006).
    public init(entry: FilingPlan.Entry, id: UUID = UUID()) throws {
        guard case let .event(title, start, end, location) = entry.intent else {
            throw DomainError.mismatchedFilingIntent(expected: .event, actual: entry.intent.kind)
        }
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.sourceCaptureID = entry.captureID
        self.filingOrdinal = entry.ordinal
    }
}
