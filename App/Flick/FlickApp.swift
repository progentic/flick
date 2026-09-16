import SwiftUI
import Observation
import CEUI
import CECapture
import CEStorage
import CEPipelines
import FlickDomain
import OSLog

@main
struct FlickApp: App {
    @State private var session = ApplicationSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if let model = session.model {
                    TextFlickView(model: model)
                } else {
                    FlickStartupView(failed: session.failed) { Task { await session.open() } }
                }
            }.task { await session.open() }
        }
    }
}

@MainActor @Observable
private final class ApplicationSession {
    private static let logger = Logger(subsystem: "com.progentic.flick", category: "application")
    private var openAttempts = 0
    var model: CaptureScreenModel?
    var failed = false
    private var opening = false

    func open() async {
        guard model == nil, !opening else { return }
        opening = true
        openAttempts += 1
        let start = ContinuousClock.now
        failed = false
        defer { opening = false }
        do {
            model = try await assembleApplication()
        } catch {
            let event = FailureDiagnostic(category: "application", operation: "open_notes", stage: "composition",
                attempt: openAttempts, attemptScope: "application_session", duration: start.duration(to: .now),
                recovery: "retry_open_no_reset", error: error)
            Self.logger.error("\(event.logLine, privacy: .public)")
            failed = true
        }
    }

    private func assembleApplication() async throws -> CaptureScreenModel {
        var url = try TextStoreLocation.applicationURL()
        var allowsSave = true
        var beforeCapture: @Sendable () async throws -> Void = {}
        var beforeProcessing: @Sendable () async throws -> Void = {}
        var afterClaim: @Sendable () async throws -> Void = {}
        #if DEBUG
        let configuration = try UITestConfiguration(base: url)
        url = configuration.url
        allowsSave = !configuration.readOnly
        beforeCapture = configuration.beforeCapture
        beforeProcessing = configuration.beforeProcessing
        afterClaim = configuration.afterClaim
        #endif
        let store = try await TextStore.open(at: url, allowsSave: allowsSave)
        let kernel = TextKernel(store: store, afterClaim: afterClaim)
        let captureDelay = beforeCapture
        let processingDelay = beforeProcessing
        let coordinator = CaptureCoordinator {
            try await captureDelay()
            return try await store.insert($0)
        }
        return CaptureScreenModel(actions: CaptureActions(capture: coordinator,
            load: { try await store.feed() }, delete: { try await store.delete($0) },
            retry: { try await store.retry($0) },
            process: { try await processingDelay(); try await kernel.run() },
            changes: { await store.changes() }))
    }
}

#if DEBUG
/// UI-test configuration is opt-in, isolated by UUID, and absent from Release.
/// Delays stop real operations at boundaries; no fake data or save is injected.
private struct UITestConfiguration {
    let url: URL
    let readOnly: Bool
    let beforeCapture: @Sendable () async throws -> Void
    let beforeProcessing: @Sendable () async throws -> Void
    let afterClaim: @Sendable () async throws -> Void

    init(base: URL) throws {
        let environment = ProcessInfo.processInfo.environment
        guard let namespace = environment["FLICK_TEST_STORE"], let id = UUID(uuidString: namespace) else {
            url = base; readOnly = false; beforeCapture = {}; beforeProcessing = {}; afterClaim = {}
            return
        }
        let directory = base.deletingLastPathComponent().appending(path: "UITests/" + id.uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if environment["FLICK_TEST_OPEN_FAILURE"] == "1" {
            let blocker = directory.appending(path: "blocked")
            try Data("not a directory".utf8).write(to: blocker)
            url = blocker.appending(path: "TextV1.store")
        } else {
            url = directory.appending(path: "TextV1.store")
        }
        readOnly = environment["FLICK_TEST_READ_ONLY"] == "1"
        beforeCapture = Self.delay(environment["FLICK_TEST_PAUSE"] == "saving")
        beforeProcessing = Self.delay(environment["FLICK_TEST_PAUSE"] == "after-save")
        afterClaim = Self.delay(environment["FLICK_TEST_PAUSE"] == "after-claim")
    }

    private static func delay(_ enabled: Bool) -> @Sendable () async throws -> Void {
        { if enabled { try await Task.sleep(for: .seconds(120)) } }
    }
}
#endif
