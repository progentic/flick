import Foundation

public extension CaptureStatus {
    /// Allowed text-kernel transitions. Processing→pending is launch recovery;
    /// failed→pending is an explicit retry. Unsorted belongs to a later milestone.
    func permitsTextTransition(to next: CaptureStatus) -> Bool {
        switch (self, next) {
        case (.pending, .processing), (.processing, .filed), (.processing, .failed),
             (.processing, .pending), (.failed, .pending): true
        default: false
        }
    }
}
