import Foundation

/// How a capture entered the system.
public enum CaptureSource: String, Codable, Sendable {
    case voice
    case screenshot
    case text
    case shared
}

/// Reference to the raw captured payload. Media lives under the App Group
/// container; only opaque IDs are persisted — never absolute sandbox URLs
/// (see ADR-0003).
public enum ContentReference: Codable, Sendable, Hashable {
    case inlineText(String)
    case media(id: String)
}

public enum CaptureStatus: String, Codable, Sendable {
    case pending     // durable row written; awaiting processing
    case processing  // claimed by a pipeline drain
    case filed       // output objects created (see linkedObjectIDs)
    case unsorted    // 0.4.0+: routing unresolved after fallback; awaiting user resolution
    case failed      // terminal failure; surfaced, never silently dropped
}

/// Raw capture record. Written with `.pending` BEFORE the processing job is
/// enqueued — this write is the durability boundary (<300ms budget).
public struct Capture: Identifiable, Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let source: CaptureSource
    public let rawContentRef: ContentReference
    public var status: CaptureStatus
    /// Request-level replay identity (also called `captureRequestID`).
    /// Set only where the surface can supply or preserve a stable identity
    /// across retries; a surface without one leaves this nil and separate
    /// executions are treated as separate requests (ADR-0006).
    public let ingressIdempotencyKey: UUID?
    /// Set once filed: the IDs of the output objects created from this
    /// capture, in filing order. Plural because one capture may legitimately
    /// file several outputs (ADR-0006). Provenance link only — duplicate
    /// suppression uses `OutputIdempotencyKey`, and processing is
    /// at-least-once, never exactly-once (ADR-0006, ADR-0007). The reverse
    /// relation (each output's `sourceCaptureID`) is authoritative; this is
    /// the capture-side convenience.
    public var linkedObjectIDs: [UUID]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: CaptureSource,
        rawContentRef: ContentReference,
        status: CaptureStatus = .pending,
        ingressIdempotencyKey: UUID? = nil,
        linkedObjectIDs: [UUID] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.rawContentRef = rawContentRef
        self.status = status
        self.ingressIdempotencyKey = ingressIdempotencyKey
        self.linkedObjectIDs = linkedObjectIDs
    }
}
