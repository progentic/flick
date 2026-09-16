import Foundation
import Testing

import FlickDomain

@Suite("Standalone domain contracts")
struct DomainContractTests {
    private let captureID = UUID(uuidString: "ABCDEFAB-CDEF-ABCD-EFAB-CDEFABCDEFAB")!
    private let instant = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test("Canonical key format is stable across every output kind")
    func canonicalKeyFormat() {
        for kind in OutputKind.allCases {
            let key = OutputIdempotencyKey.derive(captureID: captureID, kind: kind, ordinal: 12)
            #expect(key.rawValue == "ABCDEFAB-CDEF-ABCD-EFAB-CDEFABCDEFAB/\(kind.rawValue)/12")
            let components = OutputIdempotencyKey.parse(key.rawValue)
            #expect(components?.captureID == captureID)
            #expect(components?.kind == kind)
            #expect(components?.ordinal == 12)
        }
    }

    @Test("Mixed payloads preserve their capture, order, and keys through serialization")
    func mixedPlanRoundTrip() throws {
        let intents: [FilingIntent] = [
            .task(title: "Call", dueDate: instant, subtasks: ["Prepare", "Dial"]),
            .event(title: "Meet", start: instant, end: instant.addingTimeInterval(60), location: "Office"),
            .note(summary: "Summary", fullText: "Full text\nwith Unicode: café", entities: ["Office"]),
            .task(title: "Follow up", dueDate: nil, subtasks: []),
        ]
        let plan = FilingPlan(captureID: captureID, intents: intents)
        let decoded = try roundTrip(plan)
        #expect(decoded.captureID == captureID)
        #expect(decoded.entries.map(\.intent) == intents)
        #expect(decoded.entries.map(\.ordinal) == [0, 1, 2, 3])
        #expect(decoded.entries.allSatisfy { $0.captureID == captureID })
        #expect(decoded.entries == plan.entries)
        #expect(Set(decoded.entries.map(\.outputIdempotencyKey)).count == intents.count)
    }

    @Test("Task serialization preserves every populated field and derived identity")
    func taskRoundTrip() throws {
        let plan = FilingPlan(captureID: captureID, intents: [
            .note(summary: "First", fullText: "First", entities: []),
            .task(title: "Call", dueDate: instant, subtasks: ["Prepare", "Dial"]),
        ])
        var original = try TaskItem(entry: plan.entries[1])
        original.projectID = UUID()
        original.completedAt = instant
        let decoded = try roundTrip(original)
        #expect(decoded.id == original.id)
        #expect(decoded.title == "Call")
        #expect(decoded.dueDate == instant)
        #expect(decoded.subtasks == ["Prepare", "Dial"])
        #expect(decoded.projectID == original.projectID)
        #expect(decoded.completedAt == instant)
        #expect(decoded.sourceCaptureID == captureID)
        #expect(decoded.filingOrdinal == 1)
        #expect(decoded.outputIdempotencyKey == plan.entries[1].outputIdempotencyKey)
    }

    @Test("Note serialization preserves every populated field and derived identity")
    func noteRoundTrip() throws {
        let plan = FilingPlan(captureID: captureID, intents: [
            .note(summary: "Summary", fullText: "Body\nSecond line", entities: ["Person", "Place"]),
        ])
        var original = try NoteItem(entry: plan.entries[0])
        original.projectID = UUID()
        let decoded = try roundTrip(original)
        #expect(decoded.id == original.id)
        #expect(decoded.summary == "Summary")
        #expect(decoded.fullText == "Body\nSecond line")
        #expect(decoded.entities == ["Person", "Place"])
        #expect(decoded.projectID == original.projectID)
        #expect(decoded.sourceCaptureID == captureID)
        #expect(decoded.filingOrdinal == 0)
        #expect(decoded.outputIdempotencyKey == plan.entries[0].outputIdempotencyKey)
    }

    @Test("Event draft serialization preserves data without performing delivery")
    func eventRoundTrip() throws {
        let end = instant.addingTimeInterval(60)
        let plan = FilingPlan(captureID: captureID, intents: [
            .event(title: "Meet", start: instant, end: end, location: "Office"),
        ])
        var original = try CalendarEventDraft(entry: plan.entries[0])
        original.eventKitIdentifier = "reference-only"
        let decoded = try roundTrip(original)
        #expect(decoded.id == original.id)
        #expect(decoded.title == "Meet")
        #expect(decoded.start == instant)
        #expect(decoded.end == end)
        #expect(decoded.location == "Office")
        #expect(decoded.eventKitIdentifier == "reference-only")
        #expect(decoded.sourceCaptureID == captureID)
        #expect(decoded.filingOrdinal == 0)
        #expect(decoded.outputIdempotencyKey == plan.entries[0].outputIdempotencyKey)
    }

    @Test("All output constructors reject both incompatible intent kinds")
    func incompatibleIntents() {
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Task", dueDate: nil, subtasks: []),
            .event(title: "Event", start: instant, end: nil, location: nil),
            .note(summary: "Note", fullText: "Text", entities: []),
        ])
        for entry in plan.entries {
            if entry.kind != .task {
                #expect(throws: DomainError.self) { try TaskItem(entry: entry) }
            }
            if entry.kind != .event {
                #expect(throws: DomainError.self) { try CalendarEventDraft(entry: entry) }
            }
            if entry.kind != .note {
                #expect(throws: DomainError.self) { try NoteItem(entry: entry) }
            }
        }
    }

    @Test("New output IDs do not change the plan entry's key")
    func outputIDIndependence() throws {
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Task", dueDate: nil, subtasks: []),
        ])
        let first = try TaskItem(entry: plan.entries[0], id: captureID)
        let second = try TaskItem(
            entry: plan.entries[0],
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        )
        #expect(first.id != second.id)
        #expect(first.outputIdempotencyKey == second.outputIdempotencyKey)
    }

    @Test("Capture round trips retain identity and either raw payload form", arguments: [
        ContentReference.inlineText("Text\nwith café"), .media(id: "opaque-media-id"),
    ])
    func captureRoundTrip(reference: ContentReference) throws {
        let capture = Capture(
            id: captureID, createdAt: instant, source: .shared, rawContentRef: reference,
            ingressIdempotencyKey: captureID, linkedObjectIDs: [captureID]
        )
        let decoded = try roundTrip(capture)
        #expect(decoded.id == capture.id)
        #expect(decoded.createdAt == instant)
        #expect(decoded.source == .shared)
        #expect(decoded.rawContentRef == reference)
        #expect(decoded.status == .pending)
        #expect(decoded.ingressIdempotencyKey == captureID)
        #expect(decoded.linkedObjectIDs == [captureID])
    }

    @Test("Malformed identity fields are rejected for every output", arguments: [
        "negativeOrdinal", "fractionalOrdinal", "missingOrdinal", "invalidCapture", "missingCapture",
    ])
    func malformedOutputs(corruption: String) throws {
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Task", dueDate: nil, subtasks: []),
            .event(title: "Event", start: instant, end: nil, location: nil),
            .note(summary: "Note", fullText: "Text", entities: []),
        ])
        let task = try corruptIdentity(TaskItem(entry: plan.entries[0]), corruption: corruption)
        let event = try corruptIdentity(CalendarEventDraft(entry: plan.entries[1]), corruption: corruption)
        let note = try corruptIdentity(NoteItem(entry: plan.entries[2]), corruption: corruption)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(TaskItem.self, from: task) }
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(CalendarEventDraft.self, from: event) }
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(NoteItem.self, from: note) }
    }

    @Test("Malformed plan entry shapes are rejected", arguments: [
        "negativeOrdinal", "missingIntent", "unknownIntent", "invalidPayload",
    ])
    func malformedPlan(corruption: String) throws {
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Task", dueDate: nil, subtasks: []),
        ])
        var object = try jsonObject(plan)
        var entries = try #require(object["entries"] as? [[String: Any]])
        switch corruption {
        case "negativeOrdinal": entries[0]["ordinal"] = -1
        case "missingIntent": entries[0].removeValue(forKey: "intent")
        case "unknownIntent": entries[0]["intent"] = ["unknown": [String: String]()]
        default: entries[0]["intent"] = ["task": ["title": 42, "subtasks": [String]()] as [String: Any]]
        }
        object["entries"] = entries
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(FilingPlan.self, from: data) }
    }

    @Test("Malformed capture fields are rejected", arguments: ["id", "source", "status", "rawContentRef"])
    func malformedCapture(field: String) throws {
        let capture = Capture(source: .text, rawContentRef: .inlineText("Text"))
        var object = try jsonObject(capture)
        object[field] = "invalid"
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Capture.self, from: data) }
    }

    @Test("The largest representable ordinal remains canonical")
    func maximumOrdinal() throws {
        let key = OutputIdempotencyKey.derive(captureID: captureID, kind: .task, ordinal: .max)
        #expect(OutputIdempotencyKey.parse(key.rawValue)?.ordinal == UInt.max)
        #expect(try roundTrip(key) == key)
    }

    @Test("Additional noncanonical or overflowing keys are rejected", arguments: [
        "/task/+1", "/task/ 1", "/task/1/extra", "/task/1.0",
        "/task/18446744073709551616", "/TASK/1", "/task/",
    ])
    func malformedKeys(suffix: String) throws {
        let raw = captureID.uuidString + suffix
        #expect(OutputIdempotencyKey.parse(raw) == nil)
        let data = try JSONEncoder().encode(raw)
        #expect(throws: DomainError.self) { try JSONDecoder().decode(OutputIdempotencyKey.self, from: data) }
    }

    private func roundTrip<Value: Codable>(_ value: Value) throws -> Value {
        try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value))
    }

    private func corruptIdentity<Value: Encodable>(_ value: Value, corruption: String) throws -> Data {
        var object = try jsonObject(value)
        switch corruption {
        case "negativeOrdinal": object["filingOrdinal"] = -1
        case "fractionalOrdinal": object["filingOrdinal"] = 0.5
        case "missingOrdinal": object.removeValue(forKey: "filingOrdinal")
        case "invalidCapture": object["sourceCaptureID"] = "not-a-uuid"
        default: object.removeValue(forKey: "sourceCaptureID")
        }
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func jsonObject<Value: Encodable>(_ value: Value) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
