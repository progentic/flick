import Foundation
import FlickDomain
import CEIngestion
import CEStorage
import OSLog

public actor TextKernel {
    private static let logger = Logger(subsystem: "com.progentic.flick", category: "pipeline")
    private var attempts: [UUID: Int] = [:]
    private let store: any TextKernelStoring
    private let ingestion: any TextIngesting
    private let afterClaim: @Sendable () async throws -> Void
    private var running = false
    private var requested = false

    public init(store: any TextKernelStoring, ingestion: any TextIngesting = TextIngestion(),
                afterClaim: @escaping @Sendable () async throws -> Void = {}) {
        self.store = store
        self.ingestion = ingestion
        self.afterClaim = afterClaim
    }

    public func run() async throws {
        requested = true
        guard !running else { return }
        running = true
        defer { running = false }
        repeat {
            requested = false
            try await recoverAndDrain()
        } while requested
    }

    private func recoverAndDrain() async throws {
        try await store.recoverInterrupted()
        while let capture = try await store.claimNext() {
            try Task.checkCancellation()
            try await afterClaim()
            try await process(capture)
        }
    }

    private func process(_ capture: Capture) async throws {
        attempts[capture.id, default: 0] += 1
        let start = ContinuousClock.now
        let note: NoteItem
        do {
            let text = try await ingestion.ingest(capture)
            note = try TextNotePlanner.makeNote(capture: capture, content: text)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            logFailure(error, capture: capture, stage: "ingestion_and_planning", recovery: "mark_failed",
                       start: start, outputKey: nil)
            try await store.fail(capture.id)
            return
        }
        do { try await store.complete(note) }
        catch {
            logFailure(error, capture: capture, stage: "filing", recovery: "requeue_on_next_run",
                       start: start, outputKey: note.outputIdempotencyKey)
            throw error
        }
    }

    private func logFailure(_ error: any Error, capture: Capture, stage: String, recovery: String,
                            start: ContinuousClock.Instant, outputKey: OutputIdempotencyKey?) {
        let event = FailureDiagnostic(category: "pipeline", operation: "create_note", captureID: capture.id,
            outputKey: outputKey, state: capture.status, stage: stage, attempt: attempts[capture.id]!,
            attemptScope: "kernel_instance", duration: start.duration(to: .now), recovery: recovery, error: error)
        Self.logger.error("\(event.logLine, privacy: .public)")
    }
}

enum TextNotePlanner {
    static func makeNote(capture: Capture, content: IngestedContent) throws -> NoteItem {
        guard content.sourceType == .text, case let .inlineText(original) = capture.rawContentRef,
              content.rawText == original else { throw TextIngestionError.unsupportedCapture }
        let intent = FilingIntent.note(summary: original, fullText: original, entities: [])
        let plan = FilingPlan(captureID: capture.id, intents: [intent])
        return try NoteItem(entry: plan.entries[0])
    }
}
