import Foundation

/// An explicitly authored reason identifier, never an error's interpolated payload.
public protocol DiagnosticReasonProviding: Error {
    var diagnosticReason: String { get }
}

/// Content-free failure data shared across package boundaries. Writers belong
/// to the owning service; descriptions, userInfo, payloads, and paths are excluded.
public struct FailureDiagnostic: Codable, Sendable {
    public struct Cause: Codable, Sendable {
        public let errorType: String
        public let errorDomain: String
        public let errorCode: Int
        public let reason: String
    }

    public let category: String
    public let operation: String
    public let captureID: UUID?
    public let outputKey: OutputIdempotencyKey?
    public let state: CaptureStatus?
    public let expectedState: CaptureStatus?
    public let stage: String
    public let attempt: Int
    public let attemptScope: String
    public let durationMS: Double
    public let recovery: String
    public let storeMode: String?
    public let causes: [Cause]

    @available(macOS 13.0, *)
    public init(category: String, operation: String, captureID: UUID? = nil,
                outputKey: OutputIdempotencyKey? = nil, state: CaptureStatus? = nil, expectedState: CaptureStatus? = nil,
                stage: String, attempt: Int, attemptScope: String, duration: Duration,
                recovery: String, storeMode: String? = nil, error: any Error) {
        self.category = category
        self.operation = operation
        self.captureID = captureID
        self.outputKey = outputKey
        self.state = state
        self.expectedState = expectedState
        self.stage = stage
        self.attempt = attempt
        self.attemptScope = attemptScope
        let parts = duration.components
        self.durationMS = Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
        self.recovery = recovery
        self.storeMode = storeMode
        self.causes = Self.errorChain(error)
    }

    /// Stable, structured serialization suitable for a single OSLog record.
    public var logLine: String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8)
        else { return "diagnostic_encoding_failed" }
        return text
    }

    private static func errorChain(_ error: any Error) -> [Cause] {
        var causes: [Cause] = []
        var current: (any Error)? = error
        // Bound nested/cyclic framework errors. Never serialize userInfo itself.
        for _ in 0..<4 {
            guard let failure = current else { break }
            let technical = failure as NSError
            causes.append(Cause(errorType: String(reflecting: type(of: failure)),
                                errorDomain: safeDomain(technical.domain), errorCode: technical.code,
                                reason: (failure as? any DiagnosticReasonProviding)?.diagnosticReason ?? reason(for: technical)))
            current = technical.userInfo[NSUnderlyingErrorKey] as? any Error
        }
        return causes
    }

    private static func safeDomain(_ domain: String) -> String {
        let known = [NSCocoaErrorDomain, NSPOSIXErrorDomain, NSOSStatusErrorDomain,
                     "NSSQLiteErrorDomain", "SwiftData.SwiftDataError", "FlickDomain.DomainError",
                     "CEStorage.TextStoreError", "CECapture.TextCaptureError", "CEIngestion.TextIngestionError"]
        return known.contains(domain) ? domain : "unrecognized_domain_redacted"
    }

    private static func reason(for error: NSError) -> String {
        guard error.domain == NSCocoaErrorDomain else { return "inspect_error_type_and_code" }
        switch CocoaError.Code(rawValue: error.code) {
        case .fileWriteNoPermission: return "write_permission_denied"
        case .fileReadNoPermission: return "read_permission_denied"
        case .fileWriteOutOfSpace: return "insufficient_storage"
        case .fileReadCorruptFile: return "corrupt_file"
        case .fileNoSuchFile, .fileReadNoSuchFile: return "file_missing"
        default: return "inspect_error_type_and_code"
        }
    }
}
