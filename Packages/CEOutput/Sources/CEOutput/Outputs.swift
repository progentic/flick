import FlickDomain

/// Future create-only calendar export boundary. The caller must establish
/// durable delivery state before attempting export and must not blindly retry
/// an ambiguous result. The scaffold supplies no EventKit implementation.
public protocol EventExporting: Sendable {
    func export(_ draft: CalendarEventDraft) async throws -> String
}
