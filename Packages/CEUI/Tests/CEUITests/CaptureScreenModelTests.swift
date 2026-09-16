import Foundation
import Testing
import CECapture
import FlickDomain
@testable import CEUI

@MainActor struct CaptureScreenModelTests {
    @Test func failureRetainsDraftAndDoesNotPublishSaved() async {
        let model = await makeModel(capture: CaptureCoordinator { _ in throw CocoaError(.fileWriteNoPermission) })
        model.draft = "A thought"
        await model.save()
        #expect(model.saveFailed)
        #expect(model.draft == "A thought")
        #expect(model.items.isEmpty)
        #expect(model.saveMessage == "Couldn't save note. Your text is still here.")
    }

    @Test func snapshotComesFromReaderNotOptimisticInsert() async {
        let model = await makeModel(capture: CaptureCoordinator { $0 })
        model.draft = "A thought"
        await model.save()
        #expect(model.saveMessage == "Saved")
        #expect(model.draft.isEmpty)
        #expect(model.items.isEmpty)
    }

    @Test func loadFailureIsNotAnEmptyFeedSuccess() async {
        let actions = CaptureActions(capture: CaptureCoordinator { $0 },
            load: { throw CocoaError(.fileReadCorruptFile) }, delete: { _ in }, retry: { _ in }, process: {})
        let model = CaptureScreenModel(actions: actions)
        await model.reload()
        #expect(model.loadError != nil)
        #expect(!model.isLoading)
    }

    @Test func newDraftDoesNotInheritSavedFeedback() async {
        let model = await makeModel(capture: CaptureCoordinator { $0 })
        model.draft = "First thought"
        await model.save()
        #expect(model.saveMessage == "Saved")
        model.draft = "Another, unsaved thought"
        #expect(model.saveMessage == nil)
    }

    @Test func repeatedBindingValueDoesNotEraseSaveResult() async {
        let model = await makeModel(capture: CaptureCoordinator { $0 })
        model.draft = "First thought"
        await model.save()
        model.draft = ""
        #expect(model.saveMessage == "Saved")
        let failed = await makeModel(capture: CaptureCoordinator { _ in throw CocoaError(.fileWriteNoPermission) })
        failed.draft = "Unsaved"
        await failed.save()
        failed.draft = "Unsaved"
        #expect(failed.saveFailed)
        #expect(failed.saveMessage == "Couldn't save note. Your text is still here.")
    }

    @Test func waitingForPersistenceDoesNotClaimSuccess() async {
        let gate = AsyncStream<Void>.makeStream()
        let entered = AsyncStream<Void>.makeStream()
        let coordinator = CaptureCoordinator { capture in
            entered.continuation.yield(())
            for await _ in gate.stream { break }
            return capture
        }
        let model = await makeModel(capture: coordinator)
        model.draft = "Not saved yet"
        let task = Task { await model.save() }
        for await _ in entered.stream { break }
        #expect(model.isSaving)
        #expect(model.saveMessage == nil)
        #expect(model.items.isEmpty)
        gate.continuation.yield(())
        gate.continuation.finish()
        entered.continuation.finish()
        await task.value
        #expect(model.saveMessage == "Saved")
    }

    @Test func successIsBriefAndDoesNotClearANewDraft() async throws {
        let model = CaptureScreenModel(actions: CaptureActions(capture: CaptureCoordinator { $0 },
            load: { [] }, delete: { _ in }, retry: { _ in }, process: {}), savedFeedbackDuration: .milliseconds(20))
        await model.reload()
        model.draft = "First"
        await model.save()
        #expect(model.saveState == .saved)
        try await Task.sleep(for: .milliseconds(50))
        #expect(model.saveState == .idle)
        model.draft = "Second"
        await model.save()
        model.draft = "Still editing"
        try await Task.sleep(for: .milliseconds(50))
        #expect(model.saveState == .idle)
        #expect(model.draft == "Still editing")
    }

    @Test func unavailableStoreDisablesCapture() async {
        let model = CaptureScreenModel(actions: CaptureActions(capture: CaptureCoordinator { capture in
            Issue.record("Unavailable library allowed capture")
            return capture
        }, load: { throw CocoaError(.fileReadCorruptFile) }, delete: { _ in }, retry: { _ in }, process: {}))
        await model.reload()
        model.draft = "Retain this"
        await model.save()
        #expect(!model.canSave)
        #expect(model.loadError == "Couldn't open notes.")
        #expect(model.draft == "Retain this")
    }

    @Test func processingFailureBelongsToUnfinishedRowsAndRetriesSafely() async {
        let capture = Capture(source: .text, rawContentRef: .inlineText("Saved"), status: .pending)
        let item = CaptureFeedItem(capture: capture, note: nil)
        let model = CaptureScreenModel(actions: CaptureActions(capture: CaptureCoordinator { $0 },
            load: { [item] }, delete: { _ in }, retry: { _ in Issue.record("Pending row must not use failed-state transition") },
            process: { throw CocoaError(.fileWriteNoPermission) }))
        await model.activate()
        #expect(model.needsRetry(item))
        #expect(model.operationError == nil)
        await model.retry(capture.id)
        #expect(model.needsRetry(item))
        #expect(model.items.first?.capture.status == .pending)
    }

    private func makeModel(capture: any CaptureCoordinating) async -> CaptureScreenModel {
        let model = CaptureScreenModel(actions: CaptureActions(capture: capture, load: { [] },
                                                   delete: { _ in }, retry: { _ in }, process: {}))
        await model.reload()
        return model
    }
}
