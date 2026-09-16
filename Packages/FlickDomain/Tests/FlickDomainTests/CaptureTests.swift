import Foundation
import Testing

@testable import FlickDomain

@Suite("Capture ingress idempotency")
struct CaptureIngressTests {
    @Test("Ingress key defaults to nil: surfaces without a stable request identity leave it unset")
    func defaultsToNil() {
        let capture = Capture(source: .text, rawContentRef: .inlineText("hello"))
        #expect(capture.ingressIdempotencyKey == nil)
    }

    @Test("A surface-supplied stable identity is preserved across encode/decode")
    func stableIdentityRoundTrips() throws {
        let requestID = UUID()
        let capture = Capture(
            source: .text,
            rawContentRef: .inlineText("hello"),
            ingressIdempotencyKey: requestID
        )
        let data = try JSONEncoder().encode(capture)
        let decoded = try JSONDecoder().decode(Capture.self, from: data)
        #expect(decoded.ingressIdempotencyKey == requestID)
    }

    @Test("New captures start pending: saving .pending is enqueueing")
    func startsPending() {
        let capture = Capture(source: .text, rawContentRef: .inlineText("hello"))
        #expect(capture.status == .pending)
    }
}

@Suite("Capture output linkage")
struct CaptureLinkageTests {
    @Test("Linked output IDs default to empty and round-trip in filing order")
    func pluralLinkage() throws {
        var capture = Capture(source: .text, rawContentRef: .inlineText("hello"))
        #expect(capture.linkedObjectIDs.isEmpty)
        let first = UUID()
        let second = UUID()
        capture.linkedObjectIDs = [first, second]
        let data = try JSONEncoder().encode(capture)
        #expect(try JSONDecoder().decode(Capture.self, from: data).linkedObjectIDs == [first, second])
    }
}
