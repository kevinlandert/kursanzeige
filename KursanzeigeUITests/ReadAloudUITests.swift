import XCTest

/// The on and off state of "Vorlesen" on the chart page. The tests do
/// not check the voice: the button value shows the state.
@MainActor
final class ReadAloudUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testReadAloudIsOffWhenChartOpens() {
        openChartOfFirstRow()

        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    func testFirstTapSetsReadAloudOnAndSecondTapSetsItOff() {
        openChartOfFirstRow()

        readAloudButton.tap()
        XCTAssertEqual(readAloudButton.value as? String, "Ein")

        readAloudButton.tap()
        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    func testReadAloudStaysOnForNextChart() {
        openChartOfFirstRow()
        let firstTitle = app.staticTexts["chartTitle"].label
        readAloudButton.tap()

        app.buttons["Nächster"].tap()
        waitForTitle(otherThan: firstTitle)

        XCTAssertEqual(readAloudButton.value as? String, "Ein")
    }

    func testReadAloudIsOffAfterChartIsClosedAndOpenedAgain() {
        openChartOfFirstRow()
        readAloudButton.tap()

        app.buttons["Schliessen"].tap()
        openChartOfFirstRow()

        XCTAssertEqual(readAloudButton.value as? String, "Aus")
    }

    /// Waits until the next chart shows. During the slide, the old and the
    /// new chart both have a button, so a check then has no clear result.
    private func waitForTitle(otherThan oldTitle: String) {
        let changed = NSPredicate(format: "label != %@", oldTitle)
        let expectation = XCTNSPredicateExpectation(predicate: changed, object: app.staticTexts["chartTitle"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private var readAloudButton: XCUIElement {
        app.buttons["readAloud"]
    }

    private func openChartOfFirstRow() {
        app.descendants(matching: .any)["tableRow"].firstMatch.tap()
        XCTAssertTrue(readAloudButton.waitForExistence(timeout: 5))
    }
}
