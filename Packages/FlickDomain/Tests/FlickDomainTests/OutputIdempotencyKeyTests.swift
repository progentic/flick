import Foundation
import Testing

@testable import FlickDomain

@Suite("OutputIdempotencyKey derivation")
struct OutputIdempotencyKeyTests {
    @Test("Derivation is deterministic: identical inputs yield the identical key")
    func deterministic() {
        let captureID = UUID()
        let first = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0)
        let second = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0)
        #expect(first == second)
    }

    @Test("Repeated derivation reproduces the same key")
    func retryReproducesKey() {
        // Simulates two pipeline attempts over the same capture: the second
        // attempt must derive the same key even though it would mint a fresh
        // output ID. Key derivation never touches the output's own ID.
        let captureID = UUID()
        let attemptOne = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0)
        let attemptTwo = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0)
        #expect(attemptOne == attemptTwo)
        #expect(attemptOne.rawValue.contains(captureID.uuidString))
    }

    @Test("Distinct ordinals distinguish multiple outputs from one capture")
    func ordinalsDistinguishOutputs() {
        let captureID = UUID()
        let first = OutputIdempotencyKey.derive(captureID: captureID, kind: .task, ordinal: 0)
        let second = OutputIdempotencyKey.derive(captureID: captureID, kind: .task, ordinal: 1)
        #expect(first != second)
    }

    @Test("Distinct kinds produce distinct keys")
    func kindsDistinguishOutputs() {
        let captureID = UUID()
        let note = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0)
        let task = OutputIdempotencyKey.derive(captureID: captureID, kind: .task, ordinal: 0)
        #expect(note != task)
    }

    @Test("Negative control: identical content alone never implies duplication — distinct captures yield distinct keys")
    func identicalContentDistinctCaptures() {
        // Two independent captures with byte-identical text are separate
        // requests; their output keys must not collide.
        let first = OutputIdempotencyKey.derive(captureID: UUID(), kind: .note, ordinal: 0)
        let second = OutputIdempotencyKey.derive(captureID: UUID(), kind: .note, ordinal: 0)
        #expect(first != second)
    }

    @Test("Key survives a Codable round trip")
    func codableRoundTrip() throws {
        let key = OutputIdempotencyKey.derive(captureID: UUID(), kind: .event, ordinal: 2)
        let data = try JSONEncoder().encode(key)
        #expect(try JSONDecoder().decode(OutputIdempotencyKey.self, from: data) == key)
    }

    @Test("Negative control: decoding an arbitrary string throws instead of minting a key")
    func malformedKeyRejected() {
        for bad in ["", "not-a-key", "///", "\(UUID().uuidString)/bogus/0", "\(UUID().uuidString)/note/-1"] {
            let data = Data("\"\(bad)\"".utf8)
            #expect(throws: DomainError.self) {
                try JSONDecoder().decode(OutputIdempotencyKey.self, from: data)
            }
        }
    }

    @Test("parse round-trips a derived key and rejects garbage")
    func parseRoundTrip() {
        let captureID = UUID()
        let key = OutputIdempotencyKey.derive(captureID: captureID, kind: .task, ordinal: 3)
        let components = OutputIdempotencyKey.parse(key.rawValue)
        #expect(components?.captureID == captureID)
        #expect(components?.kind == .task)
        #expect(components?.ordinal == 3)
        #expect(OutputIdempotencyKey.parse("garbage") == nil)
    }

    @Test("Negative control: non-canonical representations are rejected — same components must never compare as different keys")
    func nonCanonicalRejected() {
        let captureID = UUID(uuidString: "ABCDEFAB-CDEF-ABCD-EFAB-CDEFABCDEFAB")!
        let canonical = OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 7)
        #expect(OutputIdempotencyKey.parse(canonical.rawValue) != nil)

        // Lowercase UUID: same components, different raw string.
        let lowercase = "\(captureID.uuidString.lowercased())/note/7"
        #expect(lowercase != canonical.rawValue)
        #expect(OutputIdempotencyKey.parse(lowercase) == nil)

        // Leading-zero ordinal: same components, different raw string.
        let padded = "\(captureID.uuidString)/note/007"
        #expect(OutputIdempotencyKey.parse(padded) == nil)

        // Decoding is strict too: a non-canonical stored key throws instead
        // of entering the store under a second identity.
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(OutputIdempotencyKey.self, from: Data("\"\(lowercase)\"".utf8))
        }
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(OutputIdempotencyKey.self, from: Data("\"\(padded)\"".utf8))
        }
    }
}
