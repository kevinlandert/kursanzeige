import XCTest

/// The bottom bar of the table and of the chart page: the status line and
/// the four buttons. The tests do not check the voice: the status line
/// and the button names show the state.
@MainActor
final class BottomBarUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.startCursorsOnFirstRow()
        app.launch()
        XCTAssertTrue(statusLine.waitForExistence(timeout: 5))
        app.buttons["Index"].tap()
    }

    func testTableShowsStatusLineAndFourButtons() {
        XCTAssertTrue(statusLine.label.hasPrefix("Nummer 1 von "))
        XCTAssertTrue(statusLine.label.hasSuffix(" ausgewählt"))
        XCTAssertEqual(app.buttons["table.previousButton"].label, "Vorherige")
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Vorlesen")
        XCTAssertEqual(app.buttons["table.nextButton"].label, "Nächste")
        XCTAssertEqual(app.buttons["table.openButton"].label, "Öffnen")
    }

    func testNextAndPreviousMoveTheCursor() {
        app.buttons["table.nextButton"].tap()
        waitForStatus(prefix: "Nummer 2 von ")

        app.buttons["table.previousButton"].tap()
        waitForStatus(prefix: "Nummer 1 von ")
    }

    func testReadingButtonSwitchesBetweenVorlesenAndPause() {
        app.buttons["table.readingButton"].tap()
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Pause")
        waitForStatus(prefix: "Liest vor · Nummer 1 von ")

        app.buttons["table.readingButton"].tap()
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Vorlesen")
    }

    func testOpenShowsChartOfCursorRowAndCloseKeepsTheCursor() {
        app.buttons["table.nextButton"].tap()

        app.buttons["table.openButton"].tap()
        XCTAssertTrue(app.staticTexts["chartTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["chart.closeButton"].label, "Schliessen")
        waitForStatus(prefix: "Nummer 2 von ", page: "chart")

        app.buttons["chart.closeButton"].tap()
        XCTAssertTrue(app.buttons["table.openButton"].waitForExistence(timeout: 5))
        waitForStatus(prefix: "Nummer 2 von ")
    }

    func testTapOnRowOpensItsChart() {
        app.descendants(matching: .any)["tableRow"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["chartTitle"].waitForExistence(timeout: 5))
        waitForStatus(prefix: "Nummer 1 von ", page: "chart")
    }

    func testNextOnChartPageShowsNextChart() {
        app.buttons["table.openButton"].tap()
        let title = app.staticTexts["chartTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let firstTitle = title.label

        app.buttons["chart.nextButton"].tap()

        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", firstTitle), object: title)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        waitForStatus(prefix: "Nummer 2 von ", page: "chart")
    }

    private var statusLine: XCUIElement {
        statusLine(page: "table")
    }

    private func statusLine(page: String) -> XCUIElement {
        app.descendants(matching: .any)["\(page).statusLine"]
    }

    private func waitForStatus(prefix: String, page: String = "table", file: StaticString = #filePath, line: UInt = #line) {
        let status = statusLine(page: page)
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH %@", prefix), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [matches], timeout: 5), .completed, "Status: \(status.label)", file: file, line: line)
    }
}
