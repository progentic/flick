import Foundation

/// Auto-generated cluster of related captures. Name is user-renamable.
public struct ProjectCluster: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var memberCaptureIDs: [UUID]

    public init(id: UUID = UUID(), name: String, memberCaptureIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.memberCaptureIDs = memberCaptureIDs
    }
}
