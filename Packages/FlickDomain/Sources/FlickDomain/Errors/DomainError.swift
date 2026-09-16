import Foundation

/// Domain-layer errors: malformed persisted values and violated filing
/// invariants. Error context may contain input data; callers must decide what
/// is appropriate to include in diagnostics.
public enum DomainError: Error, Sendable {
    /// A persisted idempotency key is not a well-formed `derive` output.
    case malformedIdempotencyKey(rawValue: String)
    /// A decoded plan entry names a different capture than the plan itself;
    /// the entry was spliced in from another capture's plan, or the persisted
    /// plan is corrupt. Entries are bound to their capture at construction,
    /// so this must never occur in a well-formed persisted plan (ADR-0006).
    case foreignFilingEntry(entryCaptureID: UUID, planCaptureID: UUID)
    /// A decoded plan's ordinals do not form the canonical sequence
    /// 0...n-1: a gap, a reordering, or a duplicate ordinal (even across
    /// different kinds). Construction assigns ordinals sequentially, so any
    /// deviation is persisted corruption (ADR-0006).
    case nonsequentialFilingOrdinal(index: Int, ordinal: UInt)
    /// A plan entry's intent does not match the output kind being constructed
    /// from it; each output must be built from an entry of its own kind.
    case mismatchedFilingIntent(expected: OutputKind, actual: OutputKind)
}
