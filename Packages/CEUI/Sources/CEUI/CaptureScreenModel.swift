import Foundation
import Observation
import FlickDomain

public enum NoteSaveState: Equatable, Sendable { case idle, saving, saved, failed }

@MainActor @Observable
public final class CaptureScreenModel {
    public var draft = "" {
        didSet {
            if draft != oldValue && !isSaving {
                savedFeedbackTask?.cancel()
                saveState = .idle
            }
        }
    }
    public private(set) var items: [CaptureFeedItem] = []
    public private(set) var saveState: NoteSaveState = .idle
    public private(set) var isLoading = true
    public private(set) var loadError: String?
    public private(set) var operationError: String?
    public private(set) var processingUnavailable = false
    public private(set) var retrying: Set<UUID> = []
    private let actions: CaptureActions
    private let savedFeedbackDuration: Duration
    private var savedFeedbackTask: Task<Void, Never>?
    private var loadRevision = 0

    public init(actions: CaptureActions, savedFeedbackDuration: Duration = .seconds(2)) {
        self.actions = actions
        self.savedFeedbackDuration = savedFeedbackDuration
    }

    public var isSaving: Bool { saveState == .saving }
    public var saveFailed: Bool { saveState == .failed }
    public var captureUnavailable: Bool { isLoading || loadError != nil }
    public var canSave: Bool {
        !captureUnavailable && !isSaving && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    public var saveMessage: String? {
        switch saveState {
        case .saved: "Saved"
        case .failed: "Couldn't save note. Your text is still here."
        default: nil
        }
    }

    public func activate() async {
        await reload()
        guard loadError == nil else { return }
        await processPending()
    }

    public func observe() async {
        for await _ in await actions.changes() {
            guard !Task.isCancelled else { return }
            await reload()
        }
    }

    public func save() async {
        guard canSave else { return }
        savedFeedbackTask?.cancel()
        saveState = .saving
        do {
            _ = try await actions.capture.captureText(draft)
            draft = ""
            saveState = .saved
            scheduleSavedFeedbackExpiry()
        } catch {
            saveState = .failed
        }
        guard !saveFailed else { return }
        await reload()
        await processPending()
    }

    public func reload() async {
        loadRevision += 1
        let revision = loadRevision
        do {
            let persisted = try await actions.load()
            guard revision == loadRevision else { return }
            items = persisted
            loadError = nil
        } catch {
            guard revision == loadRevision else { return }
            loadError = "Couldn't open notes."
        }
        isLoading = false
    }

    public func delete(_ id: UUID) async {
        do {
            try await actions.delete(id)
            operationError = nil
            await reload()
        } catch {
            operationError = "Couldn't delete note."
        }
    }

    public func needsRetry(_ item: CaptureFeedItem) -> Bool {
        item.capture.status == .failed || (processingUnavailable && item.note == nil)
    }

    public func retry(_ id: UUID) async {
        guard !retrying.contains(id) else { return }
        retrying.insert(id)
        defer { retrying.remove(id) }
        do {
            if items.first(where: { $0.id == id })?.capture.status == .failed {
                try await actions.retry(id)
            }
            await processPending()
        } catch {
            processingUnavailable = true
        }
        await reload()
    }

    public func processPending() async {
        do {
            try await actions.process()
            processingUnavailable = false
        } catch {
            processingUnavailable = true
        }
        await reload()
    }

    private func scheduleSavedFeedbackExpiry() {
        let duration = savedFeedbackDuration
        savedFeedbackTask = Task { [weak self] in
            do { try await Task.sleep(for: duration) }
            catch { return }
            guard let self, self.saveState == .saved else { return }
            self.saveState = .idle
        }
    }
}
