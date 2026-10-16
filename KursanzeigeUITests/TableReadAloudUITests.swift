import XCTest

/// The on and off state of "Vorlesen" below the table. The tests do not
/// check the voice: the button value shows the state.
@MainActor
final class TableReadAloudUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(readAloudButton.waitForExistence(timeout: 5))
        app.buttons["Index"].tap()
    }

    func testReadAloudIsOffWhenAppOpens() {
        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    func testFirstTapSetsReadAloudOnAndSecondTapSetsItOff() {
        readAloudButton.tap()
        XCTAssertEqual(readAloudButton.value as? String, "Ein")

        readAloudButton.tap()
        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    func testReadAloudStaysOnForNextGroup() {
        readAloudButton.tap()

        app.buttons["Währungen"].tap()

        XCTAssertEqual(readAloudButton.value as? String, "Ein")
    }

    func testOpenChartSetsTableReadAloudOff() {
        readAloudButton.tap()

        app.descendants(matching: .any)["tableRow"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Schliessen"].waitForExistence(timeout: 5))
        app.buttons["Schliessen"].tap()

        XCTAssertTrue(readAloudButton.waitForExistence(timeout: 5))
        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    private var readAloudButton: XCUIElement {
        app.buttons["tableReadAloud"]
    }
}
