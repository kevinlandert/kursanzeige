import XCTest

/// The settings page. The app stores the settings, so each test sets back
/// what it changes: light mode, the tempo „Normal“, and Kurs and Tag read.
@MainActor
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 5))
    }

    func testSettingsButtonIsLeftOfRefreshWithWideGap() {
        let settingsButton = app.buttons["settingsButton"]
        let refreshButton = app.buttons["refresh"]

        XCTAssertEqual(settingsButton.label, "Einstellungen")
        XCTAssertGreaterThanOrEqual(refreshButton.frame.minX - settingsButton.frame.maxX, 40)
        XCTAssertEqual(settingsButton.frame.midY, refreshButton.frame.midY, accuracy: 1)
    }

    func testBackButtonClosesSettings() {
        openSettings()

        app.buttons["settingsCloseButton"].tap()

        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 5))
    }

    func testDarkChoiceIsSelectedAndStaysAfterAppStartsAgain() {
        openSettings()
        app.buttons["appearanceChoice.dark"].tap()
        XCTAssertTrue(app.buttons["appearanceChoice.dark"].isSelected)
        XCTAssertEqual(app.staticTexts["appearanceHint"].label, "Die App bleibt dunkel.")

        app.terminate()
        app.launch()
        openSettings()

        XCTAssertTrue(app.buttons["appearanceChoice.dark"].isSelected)
        app.buttons["appearanceChoice.light"].tap()
        XCTAssertTrue(app.buttons["appearanceChoice.light"].isSelected)
    }

    func testTempoStepsStopAtTheFastestTempo() {
        openSettings()
        let faster = app.buttons["Schneller"]

        faster.tap()
        XCTAssertEqual(app.otherElements["Sprechtempo"].value as? String, "Schnell")
        faster.tap()
        XCTAssertEqual(app.otherElements["Sprechtempo"].value as? String, "Schnell")

        app.buttons["Langsamer"].tap()
        XCTAssertEqual(app.otherElements["Sprechtempo"].value as? String, "Normal")
    }

    func testPriceCheckboxChangesTheSample() {
        openSettings()
        let sample = app.staticTexts["speechSample"]
        let priceCheckbox = app.switches["readColumn.price"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        let sampleWithPrice = sample.label

        priceCheckbox.tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", sampleWithPrice), object: sample)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)

        priceCheckbox.tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", sampleWithPrice), object: sample)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 5), .completed)
    }

    private func openSettings() {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        XCTAssertTrue(app.buttons["settingsCloseButton"].waitForExistence(timeout: 5))
    }
}
