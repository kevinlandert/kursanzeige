import XCTest

/// The bottom bar of the table and of the chart page: the status line and
/// the four buttons. The tests do not check the voice: the status line
/// and the button names show the state. The status line shows the name of
/// the cursor row, e.g. „Nestlé ausgewählt“.
@MainActor
final class BottomBarUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.startCursorsOnFirstRow()
        app.launch()
        XCTAssertTrue(statusLine(page: "table").waitForExistence(timeout: 5))
        app.buttons["Index"].tap()
    }

    func testTableShowsStatusLineAndFourButtons() {
        XCTAssertTrue(statusLine(page: "table").label.hasSuffix(" ausgewählt"))
        XCTAssertEqual(app.buttons["table.previousButton"].label, "Vorherige")
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Vorlesen")
        XCTAssertEqual(app.buttons["table.nextButton"].label, "Nächste")
        XCTAssertEqual(app.buttons["table.openButton"].label, "Öffnen")
    }

    func testNextAndPreviousMoveTheCursor() {
        let firstStatus = statusLine(page: "table").label

        app.buttons["table.nextButton"].tap()
        waitForStatus(page: "table", otherThan: firstStatus)

        app.buttons["table.previousButton"].tap()
        waitForStatus(page: "table", equalTo: firstStatus)
    }

    func testReadingButtonSwitchesBetweenVorlesenAndPause() {
        app.buttons["table.readingButton"].tap()
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Pause")
        XCTAssertTrue(statusLine(page: "table").label.hasPrefix("Liest vor · "))

        app.buttons["table.readingButton"].tap()
        XCTAssertEqual(app.buttons["table.readingButton"].label, "Vorlesen")
    }

    func testOpenShowsChartOfCursorRowAndCloseKeepsTheCursor() {
        app.buttons["table.nextButton"].tap()
        let tableStatus = statusLine(page: "table").label

        app.buttons["table.openButton"].tap()
        let title = waitForChartTitle()
        XCTAssertEqual(tableStatus, "\(title) ausgewählt")
        XCTAssertEqual(app.buttons["chart.closeButton"].label, "Schliessen")
        waitForStatus(page: "chart", equalTo: tableStatus)

        app.buttons["chart.closeButton"].tap()
        XCTAssertTrue(app.buttons["table.openButton"].waitForExistence(timeout: 5))
        waitForStatus(page: "table", equalTo: tableStatus)
    }

    func testTapOnRowOpensItsChart() {
        app.descendants(matching: .any)["tableRow"].firstMatch.tap()

        let title = waitForChartTitle()
        waitForStatus(page: "chart", equalTo: "\(title) ausgewählt")
    }

    func testNextOnChartPageShowsNextChart() {
        app.buttons["table.openButton"].tap()
        let firstTitle = waitForChartTitle()

        app.buttons["chart.nextButton"].tap()

        let title = app.staticTexts["chartTitle"]
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", firstTitle), object: title)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        waitForStatus(page: "chart", equalTo: "\(title.label) ausgewählt")
    }

    private func statusLine(page: String) -> XCUIElement {
        app.descendants(matching: .any)["\(page).statusLine"]
    }

    private func waitForChartTitle() -> String {
        let title = app.staticTexts["chartTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        return title.label
    }

    private func waitForStatus(page: String, equalTo text: String, file: StaticString = #filePath, line: UInt = #line) {
        waitForStatus(page: page, matching: NSPredicate(format: "label == %@", text), file: file, line: line)
    }

    private func waitForStatus(page: String, otherThan text: String, file: StaticString = #filePath, line: UInt = #line) {
        waitForStatus(page: page, matching: NSPredicate(format: "label != %@", text), file: file, line: line)
    }

    private func waitForStatus(page: String, matching predicate: NSPredicate, file: StaticString, line: UInt) {
        let status = statusLine(page: page)
        let matches = XCTNSPredicateExpectation(predicate: predicate, object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [matches], timeout: 5), .completed, "Status: \(status.label)", file: file, line: line)
    }
}
