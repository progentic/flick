import Foundation
import FlickDomain

public protocol TextKernelStoring: Sendable {
    func insert(_ capture: Capture) async throws -> Capture
    func feed() async throws -> [CaptureFeedItem]
    func claimNext() async throws -> Capture?
    func recoverInterrupted() async throws
    func complete(_ note: NoteItem) async throws
    func fail(_ captureID: UUID) async throws
    func retry(_ captureID: UUID) async throws
    func delete(_ captureID: UUID) async throws
}

public enum TextStoreError: Error, Sendable, DiagnosticReasonProviding {
    case invalidCapture
    case invalidTransition
    case missingCapture
    case corruptData
    case inconsistentNote
    case groupContainerUnavailable

    public var diagnosticReason: String {
        switch self {
        case .invalidCapture: "invalid_capture"
        case .invalidTransition: "invalid_state_transition"
        case .missingCapture: "capture_not_found"
        case .corruptData: "stored_data_inconsistent"
        case .inconsistentNote: "note_provenance_or_payload_mismatch"
        case .groupContainerUnavailable: "app_group_container_unavailable"
        }
    }
}
