import Foundation

public enum CaptureKind: String, Codable, Sendable {
    case task
    case event
    case note
    case unclear
}

public enum ContentHint: Codable, Sendable, Hashable {
    case sceneClassification(String) // e.g. "screenshot-of-text" (Vision)
    case language(String)            // BCP-47 tag (NLLanguageRecognizer)
    case entity(String)              // named entity surfaced during ingest
}

/// Normalized capture: plain text + structured hints. This — not raw
/// audio/image — is what the semantic layer consumes, keeping `CESemantic`
/// free of AVFoundation/Vision (see ADR-0001).
public struct IngestedContent: Codable, Sendable {
    public let rawText: String
    public let sourceType: CaptureSource
    public let hints: [ContentHint]

    public init(rawText: String, sourceType: CaptureSource, hints: [ContentHint] = []) {
        self.rawText = rawText
        self.sourceType = sourceType
        self.hints = hints
    }
}
