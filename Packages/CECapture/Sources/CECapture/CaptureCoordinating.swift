import FlickDomain

/// Shared text-capture entry point. A future implementation must return only
/// after the capture crosses the durable-write boundary. No storage is supplied
/// by the bootstrap scaffold.
public protocol CaptureCoordinating: Sendable {
    func captureText(_ text: String) async throws -> Capture
}
