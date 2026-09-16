import Foundation

/// The fully materialized payload of one planned output.
///
/// The plan stores the complete intent — not just a (kind, ordinal) pair — so
/// a retry resumes these exact payloads instead of regenerating outputs from
/// re-classification. Classification may return results in a different order
/// on retry; the persisted intent is what binds each payload to its ordinal,
/// which is what makes the derived idempotency keys stable (ADR-0006).
public enum FilingIntent: Codable, Sendable, Hashable {
    /// Task payload as produced by classification.
    case task(title: String, dueDate: Date?, subtasks: [String])
    /// Event payload as produced by classification.
    case event(title: String, start: Date, end: Date?, location: String?)
    /// Note payload as produced by classification.
    case note(summary: String, fullText: String, entities: [String])

    /// The output kind this intent files as. Fixed per case, so an intent can
    /// never disagree with its kind.
    public var kind: OutputKind {
        switch self {
        case .task: .task
        case .event: .event
        case .note: .note
        }
    }
}

/// Immutable record of the outputs a capture will file, with stable ordinals
/// bound to their fully materialized payloads.
///
/// The application layer MUST persist the plan before the first filing side
/// effect, and a retry MUST resume the persisted plan instead of regenerating
/// outputs: the plan already contains every payload, so re-running
/// classification on retry is both unnecessary and the source of the
/// order-instability this type exists to prevent (ADR-0006).
///
/// The plan itself is pure data; persistence, the pre-side-effect write
/// ordering, and retry orchestration belong to the application and
/// persistence layers.
public struct FilingPlan: Sendable {
    /// One planned output: the capture it was planned from, its stable
    /// ordinal, and its materialized payload. Ordinals are assigned by the
    /// plan in intent order; `UInt` makes a negative ordinal unrepresentable.
    ///
    /// The entry carries its own capture identity so a filing site cannot
    /// pair an entry from capture A with an arbitrary capture B: outputs are
    /// constructed from the entry alone, and the entry's capture is the only
    /// provenance they accept. A persisted plan whose entries name a
    /// different capture than the plan itself is corrupt (ADR-0006).
    public struct Entry: Codable, Sendable, Hashable {
        public let captureID: UUID
        public let ordinal: UInt
        public let intent: FilingIntent

        /// The output kind this entry files as, derived from its intent.
        public var kind: OutputKind { intent.kind }

        /// Duplicate-resistant identity for this exact planned output. The
        /// capture, kind, and ordinal travel together on the entry, so no plan
        /// or filing caller can substitute a different capture while deriving
        /// the key.
        public var outputIdempotencyKey: OutputIdempotencyKey {
            OutputIdempotencyKey.derive(
                captureID: captureID,
                kind: kind,
                ordinal: ordinal
            )
        }

        internal init(captureID: UUID, ordinal: UInt, intent: FilingIntent) {
            self.captureID = captureID
            self.ordinal = ordinal
            self.intent = intent
        }
    }

    public let captureID: UUID
    public let entries: [Entry]

    /// Materializes a plan from classification-produced intents, assigning
    /// stable ordinals in order. Sequential assignment cannot produce a
    /// duplicate (kind, ordinal) pair.
    public init(captureID: UUID, intents: [FilingIntent]) {
        self.captureID = captureID
        self.entries = intents.enumerated().map { index, intent in
            Entry(captureID: captureID, ordinal: UInt(index), intent: intent)
        }
    }
}

extension FilingPlan: Codable {
    private enum CodingKeys: String, CodingKey {
        case captureID
        case entries
    }

    /// Decoded plans are re-validated against the construction invariants:
    /// every entry must name this plan's capture, and ordinals must form the
    /// canonical sequence 0...n-1. Construction assigns both, so any
    /// deviation — a gap, a reordering, a duplicate ordinal across kinds, or
    /// an entry spliced in from another capture's plan — is persisted
    /// corruption and must not silently resume (ADR-0006).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let captureID = try container.decode(UUID.self, forKey: .captureID)
        let entries = try container.decode([Entry].self, forKey: .entries)
        for (index, entry) in entries.enumerated() {
            guard entry.captureID == captureID else {
                throw DomainError.foreignFilingEntry(
                    entryCaptureID: entry.captureID, planCaptureID: captureID)
            }
            guard entry.ordinal == UInt(index) else {
                throw DomainError.nonsequentialFilingOrdinal(
                    index: index, ordinal: entry.ordinal)
            }
        }
        self.captureID = captureID
        self.entries = entries
    }
}
