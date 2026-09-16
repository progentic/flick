import Foundation
import FlickDomain
import CECapture

/// Composition supplies capabilities without exposing storage or pipeline types.
public struct CaptureActions: Sendable {
    public let capture: any CaptureCoordinating
    public let load: @Sendable () async throws -> [CaptureFeedItem]
    public let delete: @Sendable (UUID) async throws -> Void
    public let retry: @Sendable (UUID) async throws -> Void
    public let process: @Sendable () async throws -> Void
    public let changes: @Sendable () async -> AsyncStream<Void>

    public init(capture: any CaptureCoordinating,
                load: @escaping @Sendable () async throws -> [CaptureFeedItem],
                delete: @escaping @Sendable (UUID) async throws -> Void,
                retry: @escaping @Sendable (UUID) async throws -> Void,
                process: @escaping @Sendable () async throws -> Void,
                changes: @escaping @Sendable () async -> AsyncStream<Void> = { AsyncStream { $0.finish() } }) {
        self.capture = capture
        self.load = load
        self.delete = delete
        self.retry = retry
        self.process = process
        self.changes = changes
    }
}
