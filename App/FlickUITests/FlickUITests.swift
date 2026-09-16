import XCTest
import UIKit

final class FlickUITests: XCTestCase {
    @MainActor func testCaptureRelaunchAndDelete() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.otherElements["emptyFeed"].waitForExistence(timeout: 15) || app.staticTexts["No notes yet."].exists)
        record(app, "01-empty-light")
        try enter(app, "Walk by the river this evening")
        XCTAssertEqual(app.buttons["saveThought"].label, "Save Note")
        record(app, "02-text-entry")
        // Dismiss before observing the brief acknowledgement: keyboard/navigation
        // settling can consume its two-second lifetime before XCTest resumes.
        dismissKeyboard(app)
        app.buttons["saveThought"].tap()
        waitForSaved(app)
        record(app, "16-saved")
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        record(app, "03-note-ready")
        app.staticTexts["Walk by the river this evening"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Original capture")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Walk by the river this evening").count, 2)
        record(app, "15-note-original-capture")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Walk by the river this evening"].exists)
        let row = app.buttons.matching(identifier: "captureRow").firstMatch
        if row.exists { row.swipeLeft() } else { app.staticTexts["Walk by the river this evening"].swipeLeft() }
        app.buttons["Delete"].firstMatch.tap()
        app.buttons["Delete note"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
    }

    @MainActor func testKillAfterDurableSaveBeforeProcessing() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-save"
        app.launch()
        try enter(app, "Keep the original across a kill")
        app.buttons["saveThought"].tap()
        waitForSaved(app)
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Saved · Finishing note…"].waitForExistence(timeout: 10))
        record(app, "04-durable-pending")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Keep the original across a kill").count, 1)
    }

    @MainActor func testKillWhileProcessingRecoversWithoutDuplicate() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-claim"
        app.launch()
        try enter(app, "One thought, one local note")
        app.buttons["saveThought"].tap()
        waitForSaved(app)
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Saved · Finishing note…"].waitForExistence(timeout: 10))
        record(app, "05-processing")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "FLICK_TEST_PAUSE")
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts.matching(identifier: "One thought, one local note").count, 1)
    }

    @MainActor func testFailureDoesNotClaimSavedAndRetryRetainsText() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
        app.terminate()
        app.launchEnvironment["FLICK_TEST_READ_ONLY"] = "1"
        app.launch()
        try enter(app, "Do not lose this draft")
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
        try enter(app, "Wait for the real save")
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
    }

    @MainActor func testExistingDataLoadFailureAndRecovery() throws {
        let app = configuredApp()
        app.launch()
        try enter(app, "Existing data stays safe")
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
        for _ in 0..<2 {
            try enter(app, "Same words, another thought")
            app.buttons["saveThought"].tap()
            waitForSaved(app)
        }
        dismissKeyboard(app)
        let ready = app.staticTexts.matching(identifier: "Note ready")
        let predicate = NSPredicate(format: "count == 2")
        expectation(for: predicate, evaluatedWith: ready)
        waitForExpectations(timeout: 10)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Note ready"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(ready.count, 2)
    }

    @MainActor func testDarkAndAccessibilityTextLayout() throws {
        let app = configuredApp()
        XCUIDevice.shared.appearance = .dark
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        try enter(app, "A longer thought stays readable with larger text.")
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
        let app = configuredApp()
        XCUIDevice.shared.appearance = .dark
        app.launch()
        try enter(app, "Take a quiet moment tomorrow.")
        app.buttons["saveThought"].tap()
        dismissKeyboard(app)
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 10))
        record(app, "10-dark-feed")
        assertDarkCanvas()
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
    }

    @MainActor func testLightAccessibilityAudit() throws {
        let app = configuredApp()
        app.launch()
        XCTAssertTrue(app.staticTexts["No notes yet."].waitForExistence(timeout: 15))
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .trait, .textClipped])
        record(app, "12-light-accessibility-audit")
    }

    @MainActor func testLandscapeCaptureRemainsReachable() throws {
        let app = configuredApp()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        try enter(app, "A thought in landscape")
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
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Original capture")).firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor func testProcessingFailureKeepsDurableThoughtAndCanRecover() throws {
        let app = configuredApp()
        app.launchEnvironment["FLICK_TEST_PAUSE"] = "after-save"
        app.launch()
        try enter(app, "Safe while processing cannot write")
        app.buttons["saveThought"].tap()
        waitForSaved(app)
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
        XCTAssertTrue(app.staticTexts["Note ready"].waitForExistence(timeout: 15))
    }

    @MainActor private func waitForSaved(_ app: XCUIApplication) {
        let saved = NSPredicate(format: "label == %@", "Saved")
        let observed = expectation(for: saved, evaluatedWith: app.buttons["saveThought"])
        wait(for: [observed], timeout: 5)
    }

    @MainActor private func configuredApp() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        XCUIDevice.shared.appearance = .light
        let app = XCUIApplication()
        app.launchEnvironment["FLICK_TEST_STORE"] = UUID().uuidString
        return app
    }

    @MainActor private func enter(_ app: XCUIApplication, _ text: String) throws {
        let field = input(app)
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText(text)
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

    /// A mode-setting API returning success is insufficient: inspect rendered
    /// canvas pixels independently of the application's token implementation.
    @MainActor private func assertDarkCanvas() {
        guard let image = XCUIScreen.main.screenshot().image.cgImage else {
            XCTFail("Missing rendered screen image")
            return
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        pixel.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.translateBy(x: -CGFloat(image.width) * 0.02, y: -CGFloat(image.height) * 0.5)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        XCTAssertEqual(pixel[3], 255)
        XCTAssertLessThan((Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])) / 3, 80,
                          "The rendered canvas must actually be dark")
    }
}
