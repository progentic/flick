import Foundation
import SwiftData

/// The durable development schema. Future changes need a new version and stage.
public enum TextSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    public static var models: [any PersistentModel.Type] { [CaptureRecord.self, NoteRecord.self] }

    @Model public final class CaptureRecord {
        @Attribute(.unique) public var id: UUID
        public var createdAt: Date
        public var text: String
        public var status: String
        public var ingressID: UUID?
        @Relationship(deleteRule: .cascade, inverse: \NoteRecord.capture)
        public var notes: [NoteRecord] = []

        public init(id: UUID, createdAt: Date, text: String, status: String, ingressID: UUID?) {
            self.id = id
            self.createdAt = createdAt
            self.text = text
            self.status = status
            self.ingressID = ingressID
        }
    }

    @Model public final class NoteRecord {
        @Attribute(.unique) public var key: String
        public var id: UUID
        public var sourceCaptureID: UUID
        public var payload: Data
        public var capture: CaptureRecord?

        public init(key: String, id: UUID, sourceCaptureID: UUID, payload: Data, capture: CaptureRecord) {
            self.key = key
            self.id = id
            self.sourceCaptureID = sourceCaptureID
            self.payload = payload
            self.capture = capture
        }
    }
}

public enum TextSchemaMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [TextSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}
