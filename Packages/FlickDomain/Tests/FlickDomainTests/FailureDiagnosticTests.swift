import Foundation
import Testing
import FlickDomain

struct FailureDiagnosticTests {
    @Test func technicalChainExcludesContentAndPaths() throws {
        let secret = "PRIVATE NOTE CONTENT"
        let cause = NSError(domain: NSPOSIXErrorDomain, code: 30, userInfo: [NSLocalizedDescriptionKey: secret])
        let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteNoPermission.rawValue,
            userInfo: [NSUnderlyingErrorKey: cause, NSLocalizedDescriptionKey: secret,
                       NSFilePathErrorKey: "/private/" + secret])
        let captureID = UUID()
        let event = FailureDiagnostic(category: "storage", operation: "save_capture", captureID: captureID,
            state: .pending, stage: "durable_write", attempt: 2, attemptScope: "store_instance",
            duration: .milliseconds(18), recovery: "retry_available", storeMode: "read_only", error: error)
        let object = try #require(JSONSerialization.jsonObject(with: Data(event.logLine.utf8)) as? [String: Any])
        #expect(object["capture_id"] as? String == captureID.uuidString)
        #expect(object["attempt"] as? Int == 2)
        #expect(event.causes.count == 2)
        #expect(event.causes[0].reason == "write_permission_denied")
        #expect(event.causes[1].errorCode == 30)
        #expect(!event.logLine.contains(secret))
        #expect(!event.logLine.contains("/private/"))
        #expect(event.logLine.contains("read_only"))
    }

    @Test func unknownDomainCannotSmuggleContent() {
        let secret = "a user supplied note in an error domain"
        let error = NSError(domain: secret, code: 99)
        let event = FailureDiagnostic(category: "pipeline", operation: "create_note", stage: "filing",
            attempt: 1, attemptScope: "kernel_instance", duration: .zero, recovery: "requeue", error: error)
        #expect(event.causes.first?.errorDomain == "unrecognized_domain_redacted")
        #expect(!event.logLine.contains(secret))
        #expect(event.causes.first?.errorCode == 99)
    }
}
