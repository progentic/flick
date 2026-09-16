import Foundation
import FlickDomain
import OSLog

public enum TextCaptureError: Error, Sendable, DiagnosticReasonProviding {
    case emptyText
    public var diagnosticReason: String { "empty_note" }
}

public struct CaptureCoordinator: CaptureCoordinating {
    private static let logger = Logger(subsystem: "com.progentic.flick", category: "capture")
    private let persist: @Sendable (Capture) async throws -> Capture

    /// The capability must return only after the explicit durable save succeeds.
    public init(persist: @escaping @Sendable (Capture) async throws -> Capture) {
        self.persist = persist
    }

    public func captureText(_ text: String) async throws -> Capture {
        let start = ContinuousClock.now
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TextCaptureError.emptyText }
        let capture = Capture(source: .text, rawContentRef: .inlineText(text))
        do {
            let saved = try await persist(capture)
            Self.recordDuration(start.duration(to: .now))
            return saved
        } catch {
            let event = FailureDiagnostic(category: "capture", operation: "save_capture", captureID: capture.id,
                state: .pending, stage: "durable_write", attempt: 1, attemptScope: "capture_request",
                duration: start.duration(to: .now), recovery: "retry_available_draft_retained", error: error)
            Self.logger.error("\(event.logLine, privacy: .public)")
            throw error
        }
    }

    private static func recordDuration(_ duration: Duration) {
        let parts = duration.components
        let milliseconds = Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
        logger.notice("capture_durable duration_ms=\(milliseconds, privacy: .public)")
    }
}
