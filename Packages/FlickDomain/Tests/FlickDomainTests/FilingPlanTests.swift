import Foundation
import Testing

@testable import FlickDomain

@Suite("FilingPlan binds ordinals to materialized payloads")
struct FilingPlanTests {
    @Test("The plan assigns stable ordinals in intent order")
    func assignsOrdinals() {
        let captureID = UUID()
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: []),
            .task(title: "Call John", dueDate: nil, subtasks: []),
            .note(summary: "s", fullText: "f", entities: []),
        ])
        #expect(plan.entries.map(\.ordinal) == [0, 1, 2])
        #expect(plan.entries.map(\.kind) == [.task, .task, .note])
    }

    @Test("Each entry carries the plan's capture identity")
    func entriesCarryCaptureID() {
        let captureID = UUID()
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: []),
            .note(summary: "s", fullText: "f", entities: []),
        ])
        #expect(plan.entries.allSatisfy { $0.captureID == captureID })
    }

    @Test("An entry owns its key and cannot be rebound through another plan")
    func entryOwnsIdempotencyKey() {
        let firstCaptureID = UUID()
        let secondCaptureID = UUID()
        let first = FilingPlan(captureID: firstCaptureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: [])
        ])
        let second = FilingPlan(captureID: secondCaptureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: [])
        ])
        let expected = OutputIdempotencyKey.derive(
            captureID: firstCaptureID,
            kind: .task,
            ordinal: 0
        )

        #expect(first.entries[0].outputIdempotencyKey != second.entries[0].outputIdempotencyKey)
        #expect(first.entries[0].outputIdempotencyKey == expected)
    }

    @Test("Plan entries derive the same keys the outputs will compute")
    func planMatchesOutputDerivation() throws {
        let captureID = UUID()
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: []),
            .task(title: "Call John", dueDate: nil, subtasks: []),
        ])
        let callJohn = try TaskItem(entry: plan.entries[1])
        #expect(callJohn.sourceCaptureID == captureID)
        #expect(plan.entries[1].outputIdempotencyKey == callJohn.outputIdempotencyKey)
    }

    @Test("A serialized plan preserves payloads, ordinals, and keys")
    func resumeReproducesIntents() throws {
        // Exercises serialization only. Durable recovery and uniqueness
        // enforcement require separate persistence integration tests.
        let captureID = UUID()
        let plan = FilingPlan(captureID: captureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: []),
            .note(summary: "s", fullText: "f", entities: []),
        ])
        let data = try JSONEncoder().encode(plan)
        let resumed = try JSONDecoder().decode(FilingPlan.self, from: data)
        #expect(resumed.entries == plan.entries)
        for (original, decoded) in zip(plan.entries, resumed.entries) {
            #expect(decoded.outputIdempotencyKey == original.outputIdempotencyKey)
        }
        let retried = try TaskItem(entry: resumed.entries[0])
        #expect(retried.title == "Buy milk")
        #expect(retried.sourceCaptureID == captureID)
        #expect(retried.outputIdempotencyKey == plan.entries[0].outputIdempotencyKey)
    }

    // MARK: - Decode corruption controls

    /// Builds a persisted-plan JSON document from raw entry fragments, so
    /// each corruption test crafts exactly one deviation.
    private func planJSON(captureID: UUID, entries: [String]) -> Data {
        let json = """
            {"captureID":"\(captureID.uuidString)","entries":[\(entries.joined(separator: ","))]}
            """
        return Data(json.utf8)
    }

    private func taskEntry(captureID: UUID, ordinal: UInt, title: String) -> String {
        """
        {"captureID":"\(captureID.uuidString)","ordinal":\(ordinal),\
        "intent":{"task":{"title":"\(title)","dueDate":null,"subtasks":[]}}}
        """
    }

    private func noteEntry(captureID: UUID, ordinal: UInt, summary: String) -> String {
        """
        {"captureID":"\(captureID.uuidString)","ordinal":\(ordinal),\
        "intent":{"note":{"summary":"\(summary)","fullText":"f","entities":[]}}}
        """
    }

    @Test("Negative control: a corrupt persisted plan with a duplicate (kind, ordinal) pair is rejected at decode")
    func corruptPlanRejectedAtDecode() {
        // Same (kind, ordinal), different payloads: the canonical sequence
        // check rejects it at index 1, which expects ordinal 1.
        let captureID = UUID()
        let data = planJSON(captureID: captureID, entries: [
            taskEntry(captureID: captureID, ordinal: 0, title: "Buy milk"),
            taskEntry(captureID: captureID, ordinal: 0, title: "Call John"),
        ])
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(FilingPlan.self, from: data)
        }
    }

    @Test("Negative control: a gap in the decoded ordinal sequence is rejected")
    func gapInOrdinalsRejected() {
        let captureID = UUID()
        let data = planJSON(captureID: captureID, entries: [
            taskEntry(captureID: captureID, ordinal: 0, title: "Buy milk"),
            taskEntry(captureID: captureID, ordinal: 2, title: "Call John"),
        ])
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(FilingPlan.self, from: data)
        }
    }

    @Test("Negative control: reordered ordinals in a decoded plan are rejected")
    func reorderedOrdinalsRejected() {
        let captureID = UUID()
        let data = planJSON(captureID: captureID, entries: [
            taskEntry(captureID: captureID, ordinal: 1, title: "Buy milk"),
            taskEntry(captureID: captureID, ordinal: 0, title: "Call John"),
        ])
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(FilingPlan.self, from: data)
        }
    }

    @Test("Negative control: a duplicate ordinal across different kinds is rejected")
    func crossKindDuplicateOrdinalRejected() {
        // Ordinal 0 claimed by both a task and a note: index 1 expects
        // ordinal 1 regardless of kind.
        let captureID = UUID()
        let data = planJSON(captureID: captureID, entries: [
            taskEntry(captureID: captureID, ordinal: 0, title: "Buy milk"),
            noteEntry(captureID: captureID, ordinal: 0, summary: "s"),
        ])
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(FilingPlan.self, from: data)
        }
    }

    @Test("Negative control: an entry naming a different capture than the plan is rejected")
    func foreignCaptureEntryRejected() {
        // An entry spliced in from another capture's plan must not resume:
        // outputs read provenance from the entry alone, so a foreign entry
        // would key the output to the wrong capture.
        let captureID = UUID()
        let otherCaptureID = UUID()
        let data = planJSON(captureID: captureID, entries: [
            taskEntry(captureID: captureID, ordinal: 0, title: "Buy milk"),
            taskEntry(captureID: otherCaptureID, ordinal: 1, title: "Call John"),
        ])
        #expect(throws: DomainError.self) {
            try JSONDecoder().decode(FilingPlan.self, from: data)
        }
    }

    @Test("Each intent case reports its fixed kind")
    func intentKinds() {
        #expect(FilingIntent.task(title: "t", dueDate: nil, subtasks: []).kind == .task)
        #expect(FilingIntent.event(title: "e", start: Date(), end: nil, location: nil).kind == .event)
        #expect(FilingIntent.note(summary: "s", fullText: "f", entities: []).kind == .note)
    }
}
