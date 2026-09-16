import Foundation
import Testing
import FlickDomain
import CEStorage
import CEIngestion
@testable import CEPipelines

@Suite("Text kernel with real disk storage")
struct TextKernelTests {
    @Test func repeatedRunsProduceOneNotePerCapture() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try await TextStore.open(at: directory.appending(path: "store"))
        for _ in 0..<2 { _ = try await store.insert(Capture(source: .text, rawContentRef: .inlineText("Same"))) }
        let kernel = TextKernel(store: store)
        try await kernel.run()
        try await kernel.run()
        let feed = try await store.feed()
        #expect(feed.count == 2)
        #expect(feed.allSatisfy { $0.capture.status == .filed && $0.note?.fullText == "Same" })
        #expect(try await store.noteCount() == 2)
    }

    @Test func badCaptureDoesNotStopFollowingWork() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try await TextStore.open(at: directory.appending(path: "store"))
        let first = Capture(createdAt: .distantPast, source: .text, rawContentRef: .inlineText("First"))
        let second = Capture(source: .text, rawContentRef: .inlineText("Second"))
        _ = try await store.insert(first)
        _ = try await store.insert(second)
        let kernel = TextKernel(store: store, ingestion: SelectiveFailure(id: first.id))
        try await kernel.run()
        let feed = try await store.feed()
        #expect(feed.first { $0.id == first.id }?.capture.status == .failed)
        #expect(feed.first { $0.id == second.id }?.capture.status == .filed)
        #expect(try await store.noteCount() == 1)
        try await store.retry(first.id)
        try await TextKernel(store: store).run()
        #expect(try await store.noteCount() == 2)
    }

    @Test func interruptedClaimIsRecoveredByNewKernel() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "store")
        let store = try await TextStore.open(at: url)
        _ = try await store.insert(Capture(source: .text, rawContentRef: .inlineText("Interrupted")))
        let kernel = TextKernel(store: store, afterClaim: { throw CancellationError() })
        await #expect(throws: CancellationError.self) { try await kernel.run() }
        #expect(try await store.feed().first?.capture.status == .processing)
        let reopened = try await TextStore.open(at: url)
        try await TextKernel(store: reopened).run()
        #expect(try await reopened.feed().first?.capture.status == .filed)
        #expect(try await reopened.noteCount() == 1)
    }

    @Test func postCaptureWorkIsNotMainThread() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try await TextStore.open(at: directory.appending(path: "store"))
        _ = try await store.insert(Capture(source: .text, rawContentRef: .inlineText("Background")))
        let kernel = TextKernel(store: store, ingestion: ThreadCheckedIngestion())
        try await kernel.run()
        #expect(try await store.noteCount() == 1)
    }

    @Test func overlappingDrainsDoNotDoubleClaim() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try await TextStore.open(at: directory.appending(path: "store"))
        for index in 0..<10 {
            _ = try await store.insert(Capture(source: .text, rawContentRef: .inlineText("Thought \(index)")))
        }
        let kernel = TextKernel(store: store)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 { group.addTask { try await kernel.run() } }
            try await group.waitForAll()
        }
        #expect(try await store.noteCount() == 10)
        #expect(try await store.feed().allSatisfy { $0.capture.status == .filed })
    }

    private func fixtureDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct SelectiveFailure: TextIngesting {
    let id: UUID
    func ingest(_ capture: Capture) async throws -> IngestedContent {
        if capture.id == id { throw TextIngestionError.unsupportedCapture }
        return try await TextIngestion().ingest(capture)
    }
}

private struct ThreadCheckedIngestion: TextIngesting {
    func ingest(_ capture: Capture) async throws -> IngestedContent {
        checkSynchronousStageThread()
        return try await TextIngestion().ingest(capture)
    }

    private func checkSynchronousStageThread() {
        #expect(!Thread.isMainThread)
    }
}
