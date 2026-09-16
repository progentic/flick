import FlickDomain

public enum TextIngestionError: Error, Sendable, DiagnosticReasonProviding {
    case unsupportedCapture
    public var diagnosticReason: String { "unsupported_capture_payload" }
}

public protocol TextIngesting: Sendable {
    func ingest(_ capture: Capture) async throws -> IngestedContent
}

public struct TextIngestion: TextIngesting {
    public init() {}

    public func ingest(_ capture: Capture) async throws -> IngestedContent {
        guard capture.source == .text, case let .inlineText(text) = capture.rawContentRef
        else { throw TextIngestionError.unsupportedCapture }
        return IngestedContent(rawText: text, sourceType: .text)
    }
}
