import Foundation

/// A read-only projection of persisted capture and local Note state.
public struct CaptureFeedItem: Identifiable, Sendable {
    public var id: UUID { capture.id }
    public let capture: Capture
    public let note: NoteItem?

    public init(capture: Capture, note: NoteItem?) {
        self.capture = capture
        self.note = note
    }

    public var text: String {
        guard case let .inlineText(text) = capture.rawContentRef else { return "" }
        return text
    }
}
