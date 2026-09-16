import Foundation
import Testing

@testable import FlickDomain

@Suite("Output models are built from plan entries")
struct OutputModelTests {
    private static func plan(
        captureID: UUID = UUID(),
        intents: [FilingIntent]
    ) -> FilingPlan {
        FilingPlan(captureID: captureID, intents: intents)
    }

    @Test("TaskItem takes its payload and ordinal from the entry — the key cannot name another capture")
    func taskFromEntry() throws {
        let captureID = UUID()
        let plan = Self.plan(captureID: captureID, intents: [
            .task(title: "Buy milk", dueDate: nil, subtasks: []),
            .task(title: "Call John", dueDate: nil, subtasks: []),
        ])
        let buyMilk = try TaskItem(entry: plan.entries[0])
        let callJohn = try TaskItem(entry: plan.entries[1])
        let expectedBuyMilkKey = OutputIdempotencyKey.derive(
            captureID: captureID,
            kind: .task,
            ordinal: 0
        )

        // Even if classification returned the intents in a different order on
        // a retry, each persisted entry still binds its own payload to its
        // own ordinal: retries resume the plan, never the classifier's
        // latest ordering (ADR-0006).
        #expect(buyMilk.title == "Buy milk")
        #expect(buyMilk.sourceCaptureID == captureID)
        #expect(buyMilk.filingOrdinal == 0)
        #expect(callJohn.title == "Call John")
        #expect(callJohn.filingOrdinal == 1)
        #expect(buyMilk.outputIdempotencyKey != callJohn.outputIdempotencyKey)
        #expect(buyMilk.outputIdempotencyKey == plan.entries[0].outputIdempotencyKey)
        #expect(buyMilk.outputIdempotencyKey == expectedBuyMilkKey)
    }

    @Test("NoteItem and CalendarEventDraft take payload and ordinal from their entries")
    func noteAndEventFromEntries() throws {
        let captureID = UUID()
        let start = Date()
        let plan = Self.plan(captureID: captureID, intents: [
            .note(summary: "s", fullText: "f", entities: ["e"]),
            .event(title: "Dentist", start: start, end: nil, location: "Main St"),
        ])
        let note = try NoteItem(entry: plan.entries[0])
        let event = try CalendarEventDraft(entry: plan.entries[1])
        let expectedEventKey = OutputIdempotencyKey.derive(
            captureID: captureID,
            kind: .event,
            ordinal: 1
        )
        #expect(note.summary == "s")
        #expect(note.entities == ["e"])
        #expect(note.outputIdempotencyKey == OutputIdempotencyKey.derive(captureID: captureID, kind: .note, ordinal: 0))
        #expect(event.title == "Dentist")
        #expect(event.start == start)
        #expect(event.location == "Main St")
        #expect(event.outputIdempotencyKey == expectedEventKey)
    }

    @Test("Negative control: building an output from another kind's entry throws")
    func mismatchedIntentThrows() {
        let captureID = UUID()
        let plan = Self.plan(captureID: captureID, intents: [
            .note(summary: "s", fullText: "f", entities: []),
        ])
        #expect(throws: DomainError.self) {
            try TaskItem(entry: plan.entries[0])
        }
    }

    @Test("Models round-trip; the derived key follows the persisted ordinal")
    func codableRoundTrip() throws {
        let captureID = UUID()
        let plan = Self.plan(captureID: captureID, intents: [
            .task(title: "t", dueDate: nil, subtasks: []),
        ])
        let task = try TaskItem(entry: plan.entries[0])
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        #expect(decoded.filingOrdinal == 0)
        #expect(decoded.sourceCaptureID == captureID)
        #expect(decoded.outputIdempotencyKey == task.outputIdempotencyKey)
    }
}
