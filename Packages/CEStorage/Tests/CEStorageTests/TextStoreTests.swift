import Foundation
import Testing
import FlickDomain
@testable import CEStorage

@Suite("Disk-backed text schema V1")
struct TextStoreTests {
    @Test func initializeReopenAndFetchPending() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Keep this"))
        _ = try await store.insert(capture)
        let reopened = try await TextStore.open(at: fixture.url)
        let feed = try await reopened.feed()
        #expect(feed.count == 1)
        #expect(feed.first?.capture.id == capture.id)
        #expect(feed.first?.text == "Keep this")
        #expect(feed.first?.capture.status == .pending)
        #expect(feed.first?.note == nil)
    }

    @Test func transitionsRejectSkippingClaim() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Text"))
        _ = try await store.insert(capture)
        let note = try fixture.note(for: capture)
        await #expect(throws: TextStoreError.self) { try await store.complete(note) }
        await #expect(throws: TextStoreError.self) { try await store.retry(capture.id) }
        #expect(try await store.feed().first?.capture.status == .pending)
        #expect(try await store.noteCount() == 0)
    }

    @Test func interruptedProcessingRecoversAfterReopen() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Recover me"))
        _ = try await store.insert(capture)
        #expect(try await store.claimNext()?.id == capture.id)
        let reopened = try await TextStore.open(at: fixture.url)
        #expect(try await reopened.feed().first?.capture.status == .processing)
        try await reopened.recoverInterrupted()
        #expect(try await reopened.claimNext()?.id == capture.id)
        try await reopened.complete(fixture.note(for: capture))
        #expect(try await reopened.feed().first?.capture.status == .filed)
        #expect(try await reopened.noteCount() == 1)
    }

    @Test func repeatedCompletionIsOneNoteWithCanonicalIdentity() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Once"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        let first = try fixture.note(for: capture)
        try await store.complete(first)
        let reopened = try await TextStore.open(at: fixture.url)
        try await reopened.complete(fixture.note(for: capture))
        let item = try #require(await reopened.feed().first)
        #expect(try await reopened.noteCount() == 1)
        #expect(item.note?.id == first.id)
        #expect(item.capture.linkedObjectIDs == [first.id])
        #expect(item.note?.sourceCaptureID == capture.id)
        #expect(item.capture.status == .filed)
    }

    @Test func independentIdenticalTextRemainsIndependent() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        for _ in 0..<2 {
            let capture = Capture(source: .text, rawContentRef: .inlineText("Same"))
            _ = try await store.insert(capture)
            _ = try await store.claimNext()
            try await store.complete(fixture.note(for: capture))
        }
        let feed = try await store.feed()
        #expect(feed.count == 2)
        #expect(Set(feed.map(\.id)).count == 2)
        #expect(Set(feed.compactMap { $0.note?.outputIdempotencyKey }).count == 2)
    }

    @Test func deletionCascadesAndReopenFindsNoOrphan() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Delete"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        let note = try fixture.note(for: capture)
        try await store.complete(note)
        try await store.delete(capture.id)
        let reopened = try await TextStore.open(at: fixture.url)
        #expect(try await reopened.feed().isEmpty)
        #expect(try await reopened.noteCount() == 0)
        try await reopened.complete(note)
        #expect(try await reopened.noteCount() == 0)
    }

    @Test func deletionDuringClaimDoesNotResurrectCapture() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Delete during processing"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        try await store.delete(capture.id)
        try await store.complete(fixture.note(for: capture))
        #expect(try await store.feed().isEmpty)
        #expect(try await store.noteCount() == 0)
    }

    @Test func explicitFailureAndRetryRetainOriginal() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Safe"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        try await store.fail(capture.id)
        #expect(try await store.feed().first?.capture.status == .failed)
        try await store.retry(capture.id)
        #expect(try await store.claimNext()?.rawContentRef == .inlineText("Safe"))
        try await store.complete(fixture.note(for: capture))
        #expect(try await store.noteCount() == 1)
    }

    @Test func realReadOnlyStoreRefusesCaptureAndRollsBack() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        _ = try await TextStore.open(at: fixture.url)
        let readOnly = try await TextStore.open(at: fixture.url, allowsSave: false)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Must not report saved"))
        await #expect(throws: (any Error).self) { try await readOnly.insert(capture) }
        #expect(try await readOnly.feed().isEmpty)
        let reopened = try await TextStore.open(at: fixture.url)
        #expect(try await reopened.feed().isEmpty)
    }

    @Test func completionSaveFailureRollsBackNoteAndStateTogether() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Atomic"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        let readOnly = try await TextStore.open(at: fixture.url, allowsSave: false)
        await #expect(throws: (any Error).self) { try await readOnly.complete(fixture.note(for: capture)) }
        let reopened = try await TextStore.open(at: fixture.url)
        #expect(try await reopened.feed().first?.capture.status == .processing)
        #expect(try await reopened.noteCount() == 0)
    }

    @Test func invalidStoreLocationDoesNotBecomeEmptySuccess() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let blocker = fixture.directory.appending(path: "not-a-directory")
        try Data("blocked".utf8).write(to: blocker)
        await #expect(throws: (any Error).self) {
            try await TextStore.open(at: blocker.appending(path: "store"))
        }
    }

    @Test func explicitRetryCannotResetAnActiveOrCompletedCapture() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("State ownership"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        await #expect(throws: TextStoreError.self) { try await store.retry(capture.id) }
        try await store.complete(fixture.note(for: capture))
        await #expect(throws: TextStoreError.self) { try await store.retry(capture.id) }
        #expect(try await store.feed().first?.capture.status == .filed)
    }

    @Test func failedDeletionPreservesCaptureAndNote() async throws {
        let fixture = try StoreFixture()
        defer { fixture.remove() }
        let store = try await TextStore.open(at: fixture.url)
        let capture = Capture(source: .text, rawContentRef: .inlineText("Keep both"))
        _ = try await store.insert(capture)
        _ = try await store.claimNext()
        try await store.complete(fixture.note(for: capture))
        let readOnly = try await TextStore.open(at: fixture.url, allowsSave: false)
        await #expect(throws: (any Error).self) { try await readOnly.delete(capture.id) }
        let reopened = try await TextStore.open(at: fixture.url)
        #expect(try await reopened.feed().first?.capture.status == .filed)
        #expect(try await reopened.noteCount() == 1)
    }
}

private struct StoreFixture {
    let directory: URL
    var url: URL { directory.appending(path: "text.store") }

    init() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func note(for capture: Capture) throws -> NoteItem {
        guard case let .inlineText(text) = capture.rawContentRef else { throw TextStoreError.invalidCapture }
        let plan = FilingPlan(captureID: capture.id, intents: [.note(summary: text, fullText: text, entities: [])])
        return try NoteItem(entry: plan.entries[0])
    }

    func remove() { try? FileManager.default.removeItem(at: directory) }
}
