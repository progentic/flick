import Foundation
import SwiftData
import OSLog
import FlickDomain

@ModelActor
public actor TextStore: TextKernelStoring {
    private static let logger = Logger(subsystem: "com.progentic.flick", category: "storage")
    private var operationAttempts: [String: Int] = [:]
    private var allowsWrites = true
    private var observers: [UUID: AsyncStream<Void>.Continuation] = [:]

    public func changes() -> AsyncStream<Void> {
        let id = UUID()
        let pair = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        observers[id] = pair.continuation
        pair.continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(id) }
        }
        pair.continuation.yield(())
        return pair.stream
    }

    /// Construction runs on a detached task so the model executor is not born
    /// on MainActor. Models and contexts never leave this actor.
    public nonisolated static func open(at url: URL, allowsSave: Bool = true) async throws -> TextStore {
        let start = ContinuousClock.now
        do {
            return try await Task.detached {
                let schema = Schema(versionedSchema: TextSchemaV1.self)
                let configuration = ModelConfiguration("FlickTextV1", schema: schema, url: url,
                                                       allowsSave: allowsSave, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, migrationPlan: TextSchemaMigrationPlan.self,
                                                   configurations: [configuration])
                let store = TextStore(modelContainer: container)
                await store.configure(allowsSave: allowsSave)
                return store
            }.value
        } catch {
            let event = FailureDiagnostic(category: "storage", operation: "open_store", stage: "container_initialization",
                attempt: 1, attemptScope: "open_invocation", duration: start.duration(to: .now),
                recovery: "retry_open_no_reset", storeMode: allowsSave ? "read_write" : "read_only", error: error)
            logger.error("\(event.logLine, privacy: .public)")
            throw error
        }
    }

    public func insert(_ capture: Capture) throws -> Capture {
        try diagnosed(operation: "save_capture", captureID: capture.id, outputKey: nil, state: .pending,
                      stage: "durable_write", recovery: "retry_available") {
            guard capture.source == .text, capture.status == .pending, capture.linkedObjectIDs.isEmpty,
                  case let .inlineText(text) = capture.rawContentRef,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TextStoreError.invalidCapture }
            if let existing = try record(capture.id) {
                guard existing.text == text else { throw TextStoreError.invalidCapture }
                return try value(existing)
            }
            let row = TextSchemaV1.CaptureRecord(id: capture.id, createdAt: capture.createdAt,
                                                text: text, status: CaptureStatus.pending.rawValue,
                                                ingressID: capture.ingressIdempotencyKey)
            modelContext.insert(row)
            try save()
            return try value(row)
        }
    }

    public func feed() throws -> [CaptureFeedItem] {
        try diagnosed(operation: "load_feed", captureID: nil, outputKey: nil, state: nil,
                      stage: "fetch_and_decode", recovery: "reload_available") {
            let descriptor = FetchDescriptor<TextSchemaV1.CaptureRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse), SortDescriptor(\.id)])
            return try modelContext.fetch(descriptor).map { row in
                let capture = try value(row)
                guard row.notes.count <= 1 else { throw TextStoreError.corruptData }
                let note = try row.notes.first.map { try decodeNote($0, capture: capture) }
                guard (capture.status == .filed) == (note != nil) else { throw TextStoreError.corruptData }
                return CaptureFeedItem(capture: capture, note: note)
            }
        }
    }

    public func claimNext() throws -> Capture? {
        let row: TextSchemaV1.CaptureRecord? = try diagnosed(operation: "select_pending_capture", captureID: nil,
            outputKey: nil, state: .pending, stage: "queue_selection", recovery: "retry_available") {
            let pending = CaptureStatus.pending.rawValue
            var descriptor = FetchDescriptor<TextSchemaV1.CaptureRecord>(
                predicate: #Predicate { $0.status == pending }, sortBy: [SortDescriptor(\.createdAt)])
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        guard let row else { return nil }
        return try diagnosed(operation: "claim_capture", captureID: row.id, outputKey: nil, state: .pending,
                             stage: "claim", recovery: "requeue_on_next_run") {
            try transition(row, to: .processing)
            try save()
            return try value(row)
        }
    }

    public func recoverInterrupted() throws {
        try diagnosed(operation: "recover_captures", captureID: nil, outputKey: nil, state: .processing,
                      stage: "recovery", recovery: "retry_available") {
            let processing = CaptureStatus.processing.rawValue
            let descriptor = FetchDescriptor<TextSchemaV1.CaptureRecord>(predicate: #Predicate { $0.status == processing })
            for row in try modelContext.fetch(descriptor) { try transition(row, to: .pending) }
            try save()
        }
    }

    public func complete(_ note: NoteItem) throws {
        try diagnosed(operation: "create_note", captureID: note.sourceCaptureID, outputKey: note.outputIdempotencyKey, state: .processing,
                      stage: "filing", recovery: "requeue_on_next_run") {
            // Deletion may win while processing is suspended. Never resurrect it.
            guard let row = try record(note.sourceCaptureID) else { return }
            guard note.filingOrdinal == 0, note.fullText == row.text else { throw TextStoreError.inconsistentNote }
            let key = note.outputIdempotencyKey.rawValue
            let descriptor = FetchDescriptor<TextSchemaV1.NoteRecord>(predicate: #Predicate { $0.key == key })
            if let existing = try modelContext.fetch(descriptor).first {
                guard existing.sourceCaptureID == row.id, row.status == CaptureStatus.filed.rawValue,
                      existing.capture?.id == row.id else { throw TextStoreError.corruptData }
                _ = try decodeNote(existing, capture: value(row))
                return
            }
            try transition(row, to: .filed)
            do {
                let payload = try JSONEncoder().encode(note)
                let stored = TextSchemaV1.NoteRecord(key: key, id: note.id, sourceCaptureID: row.id,
                                                    payload: payload, capture: row)
                modelContext.insert(stored)
                // Note, relationship, and filed state share one explicit save transaction.
                try save()
            } catch {
                modelContext.rollback()
                throw error
            }
        }
    }

    public func fail(_ captureID: UUID) throws {
        try diagnosed(operation: "mark_failed", captureID: captureID, outputKey: nil, state: .processing,
                      stage: "state_transition", recovery: "retry_available") {
            guard let row = try record(captureID) else { return }
            try transition(row, to: .failed)
            try save()
        }
    }

    public func retry(_ captureID: UUID) throws {
        try diagnosed(operation: "retry_capture", captureID: captureID, outputKey: nil, state: .failed,
                      stage: "requeue", recovery: "retry_available") {
            guard let row = try record(captureID) else { throw TextStoreError.missingCapture }
            guard row.status == CaptureStatus.failed.rawValue else { throw TextStoreError.invalidTransition }
            try transition(row, to: .pending)
            try save()
        }
    }

    public func delete(_ captureID: UUID) throws {
        try diagnosed(operation: "delete_capture", captureID: captureID, outputKey: nil, state: nil,
                      stage: "delete_transaction", recovery: "retry_available") {
            guard let row = try record(captureID) else { return }
            modelContext.delete(row)
            try save()
        }
    }

    /// Diagnostic count used by real-store integration tests to detect orphans.
    public func noteCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<TextSchemaV1.NoteRecord>())
    }

    private func diagnosed<Value>(operation: String, captureID: UUID?, outputKey: OutputIdempotencyKey?,
                                  state: CaptureStatus?, stage: String, recovery: String,
                                  body: () throws -> Value) rethrows -> Value {
        let identity = operation + "/" + (captureID?.uuidString ?? "store")
        operationAttempts[identity, default: 0] += 1
        let start = ContinuousClock.now
        do { return try body() }
        catch {
            let observedState = captureID.flatMap { id in
                (try? record(id)).flatMap { CaptureStatus(rawValue: $0.status) }
            }
            let event = FailureDiagnostic(category: "storage", operation: operation, captureID: captureID,
                outputKey: outputKey, state: observedState, expectedState: state, stage: stage, attempt: operationAttempts[identity]!,
                attemptScope: "store_instance", duration: start.duration(to: .now), recovery: recovery,
                storeMode: allowsWrites ? "read_write" : "read_only", error: error)
            Self.logger.error("\(event.logLine, privacy: .public)")
            throw error
        }
    }

    private func configure(allowsSave: Bool) {
        allowsWrites = allowsSave
        modelContext.autosaveEnabled = false
    }

    private func record(_ id: UUID) throws -> TextSchemaV1.CaptureRecord? {
        let descriptor = FetchDescriptor<TextSchemaV1.CaptureRecord>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    private func transition(_ row: TextSchemaV1.CaptureRecord, to next: CaptureStatus) throws {
        guard let state = CaptureStatus(rawValue: row.status), state.permitsTextTransition(to: next)
        else { throw TextStoreError.invalidTransition }
        row.status = next.rawValue
    }

    private func value(_ row: TextSchemaV1.CaptureRecord) throws -> Capture {
        guard let status = CaptureStatus(rawValue: row.status), status != .unsorted else { throw TextStoreError.corruptData }
        return Capture(id: row.id, createdAt: row.createdAt, source: .text, rawContentRef: .inlineText(row.text),
                       status: status, ingressIdempotencyKey: row.ingressID, linkedObjectIDs: row.notes.map(\.id))
    }

    private func decodeNote(_ row: TextSchemaV1.NoteRecord, capture: Capture) throws -> NoteItem {
        let note = try JSONDecoder().decode(NoteItem.self, from: row.payload)
        guard row.capture?.id == capture.id, row.sourceCaptureID == capture.id,
              note.sourceCaptureID == capture.id, note.filingOrdinal == 0,
              note.id == row.id, note.outputIdempotencyKey.rawValue == row.key,
              case let .inlineText(text) = capture.rawContentRef, note.fullText == text
        else { throw TextStoreError.corruptData }
        return note
    }

    private func save() throws {
        do {
            try modelContext.save()
            for observer in observers.values { observer.yield(()) }
        }
        catch { modelContext.rollback(); throw error }
    }

    private func removeObserver(_ id: UUID) { observers.removeValue(forKey: id) }
}
