import XCTest

/// The title of the table page, as in Schlagzeilen.
@MainActor
final class TopBarUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 5))
    }

    func testUpdateLineIsUnderTitleKurse() {
        let title = app.staticTexts["Kurse"]
        let updateLine = app.staticTexts["updateLine"]

        XCTAssertTrue(title.exists)
        XCTAssertTrue(updateLine.exists)
        XCTAssertGreaterThanOrEqual(updateLine.frame.minY, title.frame.maxY)
        XCTAssertEqual(updateLine.frame.minX, title.frame.minX, accuracy: 1)
        XCTAssertGreaterThanOrEqual(updateLine.frame.minY, app.buttons["refresh"].frame.maxY)
    }

    /// The label has the month name, because VoiceOver reads „16.10.26“ as three numbers.
    func testUpdateLineTellsVoiceOverTheDayInWords() {
        let label = app.staticTexts["updateLine"].label

        XCTAssertTrue(label.hasPrefix("Aktualisiert ") || label == "Noch nicht aktualisiert", label)
        XCTAssertNil(label.range(of: #"\d\.\d"#, options: .regularExpression), label)
    }
}
