import Foundation

/// Kind of visible output effect produced from a capture.
///
/// Separate from `CaptureKind`: an `.unclear` classification produces no output
/// object (the capture waits in the unsorted feed instead), so it must not be
/// representable in key derivation (ADR-0006).
public enum OutputKind: String, Codable, Sendable, Hashable, CaseIterable {
    case task
    case event
    case note
}

/// Deterministic idempotency key for a visible output effect (ADR-0006).
///
/// The key is always derived from stable capture inputs — never from a freshly
/// generated output ID, and never supplied by a caller — so a retried pipeline
/// run reproduces the identical key and the storage layer's uniqueness
/// constraint suppresses the duplicate. Processing is at-least-once; this key
/// is what makes re-execution safe, not a promise that execution happens once
/// (ADR-0007).
///
/// Output structs do not store the key: they store their filing ordinal and
/// compute the key from their own capture ID, kind, and ordinal, so a key can
/// never name another capture or kind. This is the output domain only;
/// request-level replay deduplication is the separate, nullable
/// `Capture.ingressIdempotencyKey` identity.
public struct OutputIdempotencyKey: Hashable, Sendable {
    public let rawValue: String

    private init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The stable components a key is derived from.
    public struct Components: Hashable, Sendable {
        public let captureID: UUID
        public let kind: OutputKind
        public let ordinal: UInt
    }

    /// The single authoritative derivation. Identical inputs always yield the
    /// identical key. `UInt` makes a negative ordinal unrepresentable.
    public static func derive(captureID: UUID, kind: OutputKind, ordinal: UInt) -> OutputIdempotencyKey {
        OutputIdempotencyKey(rawValue: "\(captureID.uuidString)/\(kind.rawValue)/\(ordinal)")
    }

    /// Parses a key produced by `derive`; returns nil for anything else.
    ///
    /// Strictly canonical: the UUID must be in `UUID.uuidString` (uppercase)
    /// form and the ordinal must have no leading zeros. Alternate
    /// representations of the same components (lowercase UUID, `007`) are
    /// rejected, because two raw strings naming the same components would
    /// otherwise compare as different keys and defeat the uniqueness
    /// constraint (ADR-0006).
    public static func parse(_ rawValue: String) -> Components? {
        let parts = rawValue.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let captureID = UUID(uuidString: String(parts[0])),
              String(parts[0]) == captureID.uuidString,
              let kind = OutputKind(rawValue: String(parts[1])),
              let ordinal = UInt(parts[2]),
              String(parts[2]) == String(ordinal)
        else { return nil }
        return Components(captureID: captureID, kind: kind, ordinal: ordinal)
    }
}

extension OutputIdempotencyKey: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard OutputIdempotencyKey.parse(rawValue) != nil else {
            throw DomainError.malformedIdempotencyKey(rawValue: rawValue)
        }
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
