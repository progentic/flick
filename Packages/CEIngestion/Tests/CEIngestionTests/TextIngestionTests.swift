import Testing
import FlickDomain
import CEIngestion

struct TextIngestionTests {
    @Test func preservesOriginalText() async throws {
        let capture = Capture(source: .text, rawContentRef: .inlineText("  Words\nunchanged"))
        let content = try await TextIngestion().ingest(capture)
        #expect(content.rawText == "  Words\nunchanged")
        #expect(content.hints.isEmpty)
        #expect(content.sourceType == .text)
    }

    @Test func rejectsNonText() async {
        let capture = Capture(source: .voice, rawContentRef: .media(id: "opaque"))
        await #expect(throws: TextIngestionError.self) { try await TextIngestion().ingest(capture) }
    }
}
