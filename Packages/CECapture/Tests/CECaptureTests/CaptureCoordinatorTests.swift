import Foundation
import Testing
import FlickDomain
import CECapture

struct CaptureCoordinatorTests {
    @Test func persistenceFailureIsNotSuccess() async {
        let coordinator = CaptureCoordinator { _ in throw CocoaError(.fileWriteNoPermission) }
        await #expect(throws: CocoaError.self) { try await coordinator.captureText("Keep this") }
    }

    @Test func preservesTextWithoutContentDeduplication() async throws {
        let coordinator = CaptureCoordinator { capture in
            #expect(capture.status == .pending)
            #expect(capture.ingressIdempotencyKey == nil)
            return capture
        }
        let first = try await coordinator.captureText("  Original text\n")
        let second = try await coordinator.captureText("  Original text\n")
        #expect(first.rawContentRef == .inlineText("  Original text\n"))
        #expect(first.id != second.id)
    }

    @Test func emptyTextIsRejectedBeforePersistence() async {
        let coordinator = CaptureCoordinator { capture in
            Issue.record("Empty capture reached persistence")
            return capture
        }
        await #expect(throws: TextCaptureError.self) { try await coordinator.captureText(" \n\t") }
    }
}
