import XCTest
import UIKit
import SQLite3

final class FlickUITests: XCTestCase {
    @MainActor func testCaptureRelaunchAndDelete() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.otherElements["emptyFeed"].waitForExistence(timeout: 15) || app.staticTexts["No notes yet."].exists)
        record(app, "01-empty-light")
        try focusEditorAndType(app, "Walk by the river this evening")
        XCTAssertEqual(app.buttons["saveThought"].label, "Save Note")
        record(app, "02-text-entry")
        // Finish editing before observing the persisted feed.
        dismissKeyboard(app)
        app.buttons["saveThought"].tap()
        try waitForNoteReady(app, text: "Walk by the river this evening", count: 1)
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        record(app, "03-note-ready")
        app.staticTexts["Walk by the river this evening"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Original capture")).element.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Walk by the river this evening").count, 2)
        record(app, "15-note-original-capture")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Walk by the river this evening"].exists)
        let row = app.buttons.matching(identifier: "captureRow").element
        if row.exists { row.swipeLeft() } else { app.staticTexts["Walk by the river this evening"].swipeLeft() }
        app.buttons["Delete"].tap()
        app.buttons["Delete note"].tap()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
    }

    @MainActor func testKillAfterDurableSaveBeforeProcessing() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-save"
        app.launch()
        try focusEditorAndType(app, "Keep the original across a kill")
        app.buttons["saveThought"].tap()
        let captured = try waitForPersistedBoundary(app, state: "pending", text: "Keep the original across a kill")
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Saved · Finishing note…"].waitForExistence(timeout: 10))
        record(app, "04-durable-pending")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launch()
        try waitForRecoveredNote(app, capture: captured)
        XCTAssertEqual(app.staticTexts.matching(identifier: captured.text).count, 1)
    }

    @MainActor func testKillWhileProcessingRecoversWithoutDuplicate() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-claim"
        app.launch()
        try focusEditorAndType(app, "One thought, one local note")
        app.buttons["saveThought"].tap()
        let captured = try waitForPersistedBoundary(app, state: "processing", text: "One thought, one local note")
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Saved · Finishing note…"].waitForExistence(timeout: 10))
        record(app, "05-processing")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launch()
        let firstRecovery = try waitForRecoveredNote(app, capture: captured)
        app.terminate()
        app.launch()
        let secondRecovery = try waitForRecoveredNote(app, capture: captured)
        XCTAssertEqual(firstRecovery, secondRecovery, "Recovery must retain the same output identity/key")
        XCTAssertEqual(app.staticTexts.matching(identifier: captured.text).count, 1)
    }

    @MainActor func testFailureDoesNotClaimSavedAndRetryRetainsText() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
        app.terminate()
        app.launchEnvironment["FLICK_TEST_READ_ONLY"] = "1"
        app.launch()
        try focusEditorAndType(app, "Do not lose this draft")
        app.buttons["saveThought"].tap()
        XCTAssertTrue(app.staticTexts["Couldn't save note. Your text is still here."].waitForExistence(timeout: 10))
        XCTAssertNotEqual(app.buttons["saveThought"].label, "Saved")
        XCTAssertEqual(input(app).value as? String, "Do not lose this draft")
        dismissKeyboard(app)
        XCTAssertEqual(app.buttons["saveThought"].label, "Try again")
        record(app, "06-save-failure-retry")
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
        app.buttons["saveThought"].tap()
        XCTAssertNotEqual(app.buttons["saveThought"].label, "Saved")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_READ_ONLY")
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
    }

    @MainActor func testSavingDoesNotAnnounceSuccessEarly() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "saving"
        app.launch()
        try focusEditorAndType(app, "Wait for the real save")
        app.buttons["saveThought"].tap()
        XCTAssertTrue(app.buttons["saveThought"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveThought"].isEnabled)
        XCTAssertNotEqual(app.buttons["saveThought"].label, "Saved")
        XCTAssertEqual(app.buttons["saveThought"].label, "Saving…")
        record(app, "07-saving")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
        try assertSaveAcknowledgement(app)
    }

    @MainActor func testExistingDataLoadFailureAndRecovery() throws {
        let app = configuredApp()
        app.launch()
        try focusEditorAndType(app, "Existing data stays safe")
        app.buttons["saveThought"].tap()
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchEnvironment["FLICK_TEST_OPEN_FAILURE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["retryOpen"].waitForExistence(timeout: 15))
        record(app, "08-open-failure")
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_OPEN_FAILURE")
        app.launch()
        XCTAssertTrue(app.staticTexts["Existing data stays safe"].waitForExistence(timeout: 15))
    }

    @MainActor func testIndependentSameTextCreatesTwoNotes() throws {
        let app = configuredApp()
        app.launch()
        try saveAndWaitForNotes(app, text: "Same words, another thought", count: 1)
        let first = try storeProbe(app).captures()
        try saveAndWaitForNotes(app, text: "Same words, another thought", count: 2)
        let second = try storeProbe(app).captures()
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(second.count, 2)
        XCTAssertEqual(Set(second.map(\.id)).count, 2)
        XCTAssertTrue(second.contains(first[0]))
        let notes = try storeProbe(app).notes()
        XCTAssertEqual(Set(notes.map(\.id)).count, 2)
        XCTAssertEqual(Set(notes.map(\.key)).count, 2)
        XCTAssertEqual(Set(notes.map(\.captureID)), Set(second.map(\.id)))
        app.terminate()
        app.launch()
        try waitForNoteReady(app, text: "Same words, another thought", count: 2)
        XCTAssertEqual(try storeProbe(app).captures(), second)
        XCTAssertEqual(try storeProbe(app).notes(), notes)
    }

    @MainActor func testDarkAndAccessibilityTextLayout() throws {
        let app = configuredApp(dark: true)
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        try waitForCanvasAppearance(app, dark: true)
        try focusEditorAndType(app, "A longer thought stays readable with larger text.")
        XCTAssertFalse(app.staticTexts["A thought worth keeping."].exists)
        dismissKeyboard(app)
        for _ in 0..<4 {
            if app.buttons["saveThought"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertEqual(app.buttons["saveThought"].label, "Save")
        XCTAssertTrue(app.buttons["saveThought"].isHittable)
        XCTAssertLessThan(app.buttons["saveThought"].frame.height, 90)
        app.buttons["saveThought"].tap()
        dismissKeyboard(app)
        record(app, "09-dark-accessibility-size")
        for _ in 0..<3 {
            if app.staticTexts["Note ready"].exists && app.staticTexts["Note ready"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        record(app, "14-large-type-feed")
    }

    @MainActor func testDarkFeedAndAccessibilityAudit() throws {
        let app = configuredApp(dark: true)
        app.launch()
        try waitForCanvasAppearance(app, dark: true)
        try focusEditorAndType(app, "Take a quiet moment tomorrow.")
        app.buttons["saveThought"].tap()
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        record(app, "10-dark-feed")
        let canvas = try captureCanvas(app, name: "dark-canvas")
        XCTAssertTrue(canvas.isDark, "The empty editor canvas must render dark; see attached region evidence")
        print("AUDIT_RUNNER_TRAITS: \(UITraitCollection.current)")
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
    }

    @MainActor func testLightAccessibilityAudit() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
        let canvas = try captureCanvas(app, name: "light-canvas-negative-control")
        XCTAssertTrue(canvas.isLight, "The negative control must actually render a light canvas")
        XCTAssertFalse(canvas.isDark, "The same Dark Mode predicate must reject Light Mode")
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
        record(app, "12-light-accessibility-audit")
    }

    @MainActor func testLandscapeCaptureRemainsReachable() throws {
        let app = configuredApp()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        try focusEditorAndType(app, "A thought in landscape")
        XCTAssertTrue(app.buttons["saveThought"].isHittable)
        app.buttons["saveThought"].tap()
        dismissKeyboard(app)
        for _ in 0..<2 {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Note ready"].isHittable)
        record(app, "13-landscape")
        app.staticTexts["A thought in landscape"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Original capture")).element.waitForExistence(timeout: 5))
    }

    @MainActor func testProcessingFailureKeepsDurableThoughtAndCanRecover() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-save"
        app.launch()
        try focusEditorAndType(app, "Safe while processing cannot write")
        app.buttons["saveThought"].tap()
        let captured = try waitForPersistedBoundary(app, state: "pending", text: "Safe while processing cannot write")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launchEnvironment["FLICK_TEST_READ_ONLY"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["Saved · Note not ready"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Retry"].exists)
        app.buttons["Retry"].tap()
        XCTAssertTrue(app.staticTexts["Saved · Note not ready"].waitForExistence(timeout: 10))
        record(app, "11-processing-failure")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_READ_ONLY")
        app.launch()
        try waitForRecoveredNote(app, capture: captured)
    }

    @MainActor private func assertSaveAcknowledgement(_ app: XCUIApplication) throws {
        try focusEditorAndType(app, "Observe the real save acknowledgement")
        dismissKeyboard(app)
        let probe = try storeProbe(app)
        let lock = try probe.holdWriter()
        defer { lock.release() }
        app.buttons["saveThought"].tap()
        waitForElement(app.buttons["saveThought"], predicate: "label == 'Saving…'")
        XCTAssertFalse(app.buttons["saveThought"].isEnabled)
        XCTAssertEqual(try probe.captures().count, 0)
        lock.release()
        // Only this presentation test observes the transient acknowledgement.
        waitForElement(app.buttons["saveThought"], predicate: "label == 'Saved'", timeout: 5)
        XCTAssertEqual(try probe.captures().count, 1)
        record(app, "16-saved")
        waitForElement(app.buttons["saveThought"], predicate: "label == 'Save Note'")
        try waitForNoteReady(app, text: "Observe the real save acknowledgement", count: 1)
    }

    @MainActor private func saveAndWaitForNotes(_ app: XCUIApplication, text: String, count: Int) throws {
        try focusEditorAndType(app, text)
        dismissKeyboard(app)
        app.buttons["saveThought"].tap()
        try waitForNoteReady(app, text: text, count: count)
    }

    @MainActor private func waitForNoteReady(_ app: XCUIApplication, text: String, count: Int) throws {
        let probe = try storeProbe(app)
        try waitForStore(probe) { try $0.hasCompletedNotes(text: text, count: count) }
        waitForCount(app.staticTexts.matching(identifier: "Note ready"), count: count)
        XCTAssertEqual(app.staticTexts.matching(identifier: text).count, count)
    }

    @MainActor private func waitForPersistedBoundary(_ app: XCUIApplication, state: String, text: String) throws -> StoredCapture {
        let probe = try storeProbe(app)
        try waitForStore(probe) { try $0.isAtBoundary(state: state, text: text) }
        let capture = try XCTUnwrap(probe.captures().only)
        XCTAssertEqual(capture.text, text)
        XCTAssertEqual(capture.state, state)
        XCTAssertEqual(try probe.notes().count, 0)
        return capture
    }

    @discardableResult
    @MainActor private func waitForRecoveredNote(_ app: XCUIApplication, capture: StoredCapture) throws -> StoredNote {
        try waitForNoteReady(app, text: capture.text, count: 1)
        let probe = try storeProbe(app)
        let restored = try XCTUnwrap(probe.captures().only)
        let note = try XCTUnwrap(probe.notes().only)
        XCTAssertEqual(restored.id, capture.id)
        XCTAssertEqual(restored.text, capture.text)
        XCTAssertEqual(note.captureID, capture.id)
        return note
    }

    @MainActor private func waitForStore(_ probe: StoreProbe, condition: @escaping (StoreProbe) throws -> Bool) throws {
        // XCTest polls committed snapshots; SQL errors fail the test, not a retry.
        var failure: Error?
        let predicate = NSPredicate { _, _ in
            do { return try condition(probe) }
            catch { failure = error; return true }
        }
        let observed = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [observed], timeout: 15), .completed)
        if let failure { throw failure }
    }

    @MainActor private func waitForCount(_ query: XCUIElementQuery, count: Int) {
        let predicate = NSPredicate(format: "count == %d", count)
        let observed = XCTNSPredicateExpectation(predicate: predicate, object: query)
        XCTAssertEqual(XCTWaiter.wait(for: [observed], timeout: 15), .completed)
        XCTAssertEqual(query.count, count)
    }

    @MainActor private func storeProbe(_ app: XCUIApplication) throws -> StoreProbe {
        try StoreProbe(namespace: XCTUnwrap(app.launchEnvironment["FLICK_TEST_STORE"]))
    }

    @MainActor private func configuredApp(dark: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        XCUIApplication().terminate()
        XCUIDevice.shared.orientation = .portrait
        do { try requestSystemAppearance(dark: dark) }
        catch { XCTFail("Appearance fixture failed: \(error)") }
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launchEnvironment["FLICK_TEST_STORE"] = UUID().uuidString
        return app
    }

    @MainActor private func focusEditorAndType(_ app: XCUIApplication, _ text: String) throws {
        let field = input(app)
        waitForElement(field, predicate: "exists == true AND enabled == true AND hittable == true")
        field.tap()
        // Done is present only while CEUI's actual @FocusState is writing.
        waitForElement(app.navigationBars.buttons["Done"], predicate: "exists == true AND hittable == true")
        waitForElement(app.keyboards.element, predicate: "exists == true")
        field.typeText(text)
        XCTAssertEqual(field.value as? String, text)
    }

    @MainActor private func waitForElement(_ element: XCUIElement, predicate: String, timeout: TimeInterval = 15) {
        let observed = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [observed], timeout: timeout), .completed)
    }

    @MainActor private func input(_ app: XCUIApplication) -> XCUIElement {
        app.textFields["thoughtInput"]
    }

    @MainActor private func dismissKeyboard(_ app: XCUIApplication) {
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
    }

    @MainActor private func record(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + "-accessibility"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    @MainActor private func requestSystemAppearance(dark: Bool) throws {
        let directory = try XCTUnwrap(ProcessInfo.processInfo.environment["FLICK_APPEARANCE_FIXTURE"],
            "Run UI tests through scripts/test-ios.sh so the simulator fixture is available")
        let root = URL(fileURLWithPath: directory)
        let ready = root.appendingPathComponent("ready")
        waitForFile(ready)
        let selected = try String(contentsOf: ready, encoding: .utf8)
        XCTAssertEqual(selected, ProcessInfo.processInfo.environment["SIMULATOR_UDID"],
                       "Appearance fixture must control this test's simulator")
        let id = UUID().uuidString
        let request = ["id": id, "appearance": dark ? "dark" : "light"]
        let data = try JSONSerialization.data(withJSONObject: request)
        try data.write(to: root.appendingPathComponent("requests/" + id + ".json"), options: .atomic)
        let response = root.appendingPathComponent("responses/" + id + ".json")
        waitForFile(response)
        let result = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: response)) as? [String: Any])
        XCTAssertEqual(result["id"] as? String, id)
        XCTAssertEqual(result["ok"] as? Bool, true, "System appearance acknowledgement: \(result)")
        XCTAssertEqual(result["actual"] as? String, request["appearance"])
    }

    @MainActor private func waitForFile(_ url: URL) {
        let exists = NSPredicate { _, _ in FileManager.default.fileExists(atPath: url.path) }
        let observed = XCTNSPredicateExpectation(predicate: exists, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [observed], timeout: 30), .completed,
                       "Appearance fixture did not acknowledge its operation")
    }

    @MainActor private func waitForCanvasAppearance(_ app: XCUIApplication, dark: Bool) throws {
        waitForElement(input(app), predicate: "exists == true AND enabled == true AND hittable == true")
        var failure: Error?
        let rendered = NSPredicate { _, _ in
            do {
                let sample = try self.readCanvas(app).sample
                return dark ? sample.isDark : sample.isLight
            } catch { failure = error; return true }
        }
        let observed = XCTNSPredicateExpectation(predicate: rendered, object: nil)
        let result = XCTWaiter.wait(for: [observed], timeout: 15)
        if let failure { throw failure }
        _ = try captureCanvas(app, name: "appearance-ready-" + (dark ? "dark" : "light"))
        XCTAssertEqual(result, .completed, "Requested appearance must reach the app-owned canvas")
    }

    /// Observe the background owned by the empty editor, not the screen edge.
    /// The region lies below the placeholder and inside the editor's padding.
    @MainActor private func captureCanvas(_ app: XCUIApplication, name: String) throws -> CanvasSample {
        let editor = input(app)
        waitForElement(editor, predicate: "exists == true AND hittable == true")
        XCTAssertFalse(app.keyboards.element.exists)
        let value = editor.value as? String
        XCTAssertTrue(value == "" || value == editor.placeholderValue, "Sample only an empty editor")
        let frame = try readCanvas(app)
        recordCanvas(frame.screenshot, cropped: frame.cropped, region: frame.region,
                     sample: frame.sample, app: app, name: name)
        return frame.sample
    }

    @MainActor private func readCanvas(_ app: XCUIApplication) throws
        -> (screenshot: XCUIScreenshot, cropped: CGImage, region: CGRect, sample: CanvasSample) {
        let screenshot = app.screenshot()
        let image = try XCTUnwrap(screenshot.image.cgImage)
        let region = try canvasRegion(editor: input(app).frame, app: app.frame, image: image)
        let cropped = try XCTUnwrap(image.cropping(to: region))
        return (screenshot, cropped, region, try CanvasSample(image: cropped))
    }

    private func canvasRegion(editor: CGRect, app: CGRect, image: CGImage) throws -> CGRect {
        XCTAssertGreaterThanOrEqual(editor.height, 40, "Need blank lines below the placeholder")
        let points = CGRect(x: editor.maxX - 24, y: editor.maxY - 20, width: 8, height: 8)
        XCTAssertTrue(editor.insetBy(dx: 8, dy: 8).contains(points))
        XCTAssertTrue(app.contains(points), "Sample must stay within the app screenshot")
        let xScale = CGFloat(image.width) / app.width
        let yScale = CGFloat(image.height) / app.height
        return CGRect(x: (points.minX - app.minX) * xScale, y: (points.minY - app.minY) * yScale,
                      width: points.width * xScale, height: points.height * yScale).integral
    }

    @MainActor private func recordCanvas(_ screenshot: XCUIScreenshot, cropped: CGImage, region: CGRect,
                                        sample: CanvasSample, app: XCUIApplication, name: String) {
        let full = XCTAttachment(screenshot: screenshot)
        full.name = name + "-app"; full.lifetime = .keepAlways; add(full)
        let patch = XCTAttachment(image: UIImage(cgImage: cropped))
        patch.name = name + "-sampled-region"; patch.lifetime = .keepAlways; add(patch)
        let evidence = """
        test=\(self.name)
        runtime=\(ProcessInfo.processInfo.operatingSystemVersionString)
        simulator=\(ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unavailable")
        reported_device_appearance=\(XCUIDevice.shared.appearance.rawValue)
        app_appearance_trait=not exposed by public XCTest; evaluated from app-owned pixels
        launch_arguments=\(app.launchArguments)
        app_size_classes=\(app.horizontalSizeClass.rawValue),\(app.verticalSizeClass.rawValue)
        app_state=\(app.state.rawValue)
        app_frame=\(app.frame); editor_frame=\(input(app).frame)
        image_pixels=\(screenshot.image.cgImage!.width)x\(screenshot.image.cgImage!.height)
        image_orientation=\(screenshot.image.imageOrientation.rawValue); uiimage_scale=\(screenshot.image.scale)
        sampled_pixel_rect=\(region)
        source=empty editor background; 8x8 points, inset from text/border
        mean_rgb=\(sample.red),\(sample.green),\(sample.blue)
        mean_brightness=\(sample.mean); spread=\(sample.spread); opaque=\(sample.opaque)
        dark_predicate=\(sample.isDark); light_predicate=\(sample.isLight)
        """
        print("CANVAS_EVIDENCE\n" + evidence)
        let metadata = XCTAttachment(string: evidence)
        metadata.name = name + "-metadata"; metadata.lifetime = .keepAlways; add(metadata)
    }
}

// Simulator-only observation of Schema V1. No app entitlement, dependency,
// launch flag, or production source change is needed. A different schema must
// update this probe explicitly; SQL errors fail closed instead of hiding drift.
private struct StoredCapture: Equatable {
    let id: String
    let state: String
    let text: String
}

private struct StoredNote: Equatable {
    let id: String
    let captureID: String
    let key: String
}

private extension Array {
    var only: Element? { count == 1 ? self[0] : nil }
}

private struct StoreProbe {
    let url: URL

    init(namespace: String) throws {
        let id = try XCTUnwrap(UUID(uuidString: namespace))
        let root = try XCTUnwrap(ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"])
        let groups = URL(fileURLWithPath: root).appendingPathComponent("Containers/Shared/AppGroup")
        let candidates = try FileManager.default.contentsOfDirectory(at: groups, includingPropertiesForKeys: nil)
        let suffix = "Library/Application Support/Flick/UITests/\(id.uuidString)/TextV1.store"
        let matches = candidates.map { $0.appendingPathComponent(suffix) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        url = try XCTUnwrap(matches.only, "Expected exactly one store for this test's UUID")
    }

    func isAtBoundary(state: String, text: String) throws -> Bool {
        let rows = try captures()
        let outputs = try notes()
        return rows.only?.state == state && rows.only?.text == text && outputs.isEmpty
    }

    func hasCompletedNotes(text: String, count: Int) throws -> Bool {
        let rows = try captures()
        let outputs = try notes()
        return rows.count == count && outputs.count == count
            && rows.allSatisfy { $0.state == "filed" && $0.text == text }
            && Set(outputs.map(\.captureID)) == Set(rows.map(\.id))
    }

    func captures() throws -> [StoredCapture] {
        try query("SELECT hex(ZID), ZSTATUS, ZTEXT FROM ZCAPTURERECORD ORDER BY ZID")
            .map { StoredCapture(id: $0[0], state: $0[1], text: $0[2]) }
    }

    func notes() throws -> [StoredNote] {
        try query("SELECT hex(ZID), hex(ZSOURCECAPTUREID), ZKEY FROM ZNOTERECORD ORDER BY ZID")
            .map { StoredNote(id: $0[0], captureID: $0[1], key: $0[2]) }
    }

    func holdWriter() throws -> StoreWriterLock { try StoreWriterLock(url: url) }

    private func query(_ sql: String) throws -> [[String]] {
        let connection = try SQLiteConnection(url: url, flags: SQLITE_OPEN_READONLY)
        return try connection.rows(sql)
    }
}

private final class StoreWriterLock {
    private var connection: SQLiteConnection?

    init(url: URL) throws {
        let database = try SQLiteConnection(url: url, flags: SQLITE_OPEN_READWRITE)
        try database.execute("BEGIN IMMEDIATE")
        connection = database
    }

    // Closing the connection rolls back the empty transaction and releases its
    // writer reservation. It never inserts, updates, or deletes a capture/note.
    func release() { connection = nil }
}

private final class SQLiteConnection {
    private var handle: OpaquePointer?

    init(url: URL, flags: Int32) throws {
        let result = sqlite3_open_v2(url.path, &handle, flags, nil)
        guard result == SQLITE_OK else {
            sqlite3_close(handle)
            handle = nil
            throw SQLiteProbeError(code: result)
        }
    }

    deinit { sqlite3_close(handle) }

    func execute(_ sql: String) throws {
        let result = sqlite3_exec(handle, sql, nil, nil, nil)
        guard result == SQLITE_OK else { throw SQLiteProbeError(code: result) }
    }

    func rows(_ sql: String) throws -> [[String]] {
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        var result: [[String]] = []
        while try advance(statement) {
            result.append((0..<sqlite3_column_count(statement)).map {
                String(cString: sqlite3_column_text(statement, $0))
            })
        }
        return result
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        guard result == SQLITE_OK else { throw SQLiteProbeError(code: result) }
        return try XCTUnwrap(statement)
    }

    private func advance(_ statement: OpaquePointer) throws -> Bool {
        switch sqlite3_step(statement) {
        case SQLITE_ROW: return true
        case SQLITE_DONE: return false
        default: throw SQLiteProbeError(code: sqlite3_errcode(handle))
        }
    }
}

private struct SQLiteProbeError: Error { let code: Int32 }


private struct CanvasSample {
    let red: Double
    let green: Double
    let blue: Double
    let spread: Double
    let opaque: Bool
    var mean: Double { (red + green + blue) / 3 }
    var isDark: Bool { opaque && spread <= 12 && mean < 80 }
    var isLight: Bool { opaque && spread <= 12 && mean > 200 }

    init(image: CGImage) throws {
        let count = image.width * image.height
        var bytes = [UInt8](repeating: 0, count: count * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress,
                width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        let pixels = stride(from: 0, to: bytes.count, by: 4)
        red = pixels.reduce(0.0) { $0 + Double(bytes[$1]) } / Double(count)
        green = pixels.reduce(0.0) { $0 + Double(bytes[$1 + 1]) } / Double(count)
        blue = pixels.reduce(0.0) { $0 + Double(bytes[$1 + 2]) } / Double(count)
        let brightness = pixels.map { (Double(bytes[$0]) + Double(bytes[$0 + 1]) + Double(bytes[$0 + 2])) / 3 }
        spread = try XCTUnwrap(brightness.max()) - XCTUnwrap(brightness.min())
        opaque = pixels.allSatisfy { bytes[$0 + 3] == 255 }
    }
}
