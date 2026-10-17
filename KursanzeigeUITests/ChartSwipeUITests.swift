import XCTest

/// Swipes on the chart page, as a finger does. The table order comes from
/// the bundled constituents, so the tests compare titles, not names.
@MainActor
final class ChartSwipeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.startCursorsOnFirstRow()
        app.launch()
    }

    func testSwipeToTheLeftShowsNextRowAndSwipeToTheRightGoesBack() {
        let firstTitle = openChartOfFirstRow()

        app.swipeLeft()
        let secondTitle = waitForTitle(otherThan: firstTitle)
        app.swipeRight()

        XCTAssertNotEqual(secondTitle, firstTitle)
        XCTAssertEqual(waitForTitle(otherThan: secondTitle), firstTitle)
    }

    func testSwipeToTheRightOnFirstRowKeepsTheChart() {
        let firstTitle = openChartOfFirstRow()

        app.swipeRight()

        XCTAssertEqual(title(after: 1), firstTitle)
    }

    func testSwipeKeepsTheChosenRange() {
        let firstTitle = openChartOfFirstRow()
        app.buttons["5 Jahre"].tap()

        app.swipeLeft()
        _ = waitForTitle(otherThan: firstTitle)

        XCTAssertTrue(app.buttons["5 Jahre"].isSelected)
    }

    /// Opens the chart of the top row and gives its title.
    private func openChartOfFirstRow() -> String {
        app.descendants(matching: .any)["tableRow"].firstMatch.tap()
        let title = app.staticTexts["chartTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        return title.label
    }

    private func waitForTitle(otherThan oldTitle: String) -> String {
        let changed = NSPredicate(format: "label != %@", oldTitle)
        let expectation = XCTNSPredicateExpectation(predicate: changed, object: app.staticTexts["chartTitle"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        return app.staticTexts["chartTitle"].label
    }

    /// The title after the slide animation had time to finish.
    private func title(after seconds: TimeInterval) -> String {
        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: seconds)
        return app.staticTexts["chartTitle"].label
    }
}
