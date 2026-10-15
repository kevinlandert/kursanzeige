import XCTest

/// A sideways swipe on the main page goes to the neighbor group, as on
/// the chart page. The selected group button shows the result.
@MainActor
final class GroupSwipeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Index"].waitForExistence(timeout: 5))
        app.buttons["Index"].tap()
    }

    func testSwipeToTheLeftShowsNextGroup() {
        firstRow.swipeLeft()

        XCTAssertTrue(app.buttons["Währungen"].isSelected)
    }

    func testSwipeToTheRightShowsPreviousGroup() {
        app.buttons["Währungen"].tap()

        firstRow.swipeRight()

        XCTAssertTrue(app.buttons["Index"].isSelected)
    }

    func testSwipeToTheRightOnFirstGroupKeepsTheGroup() {
        firstRow.swipeRight()

        XCTAssertTrue(app.buttons["Index"].isSelected)
    }

    private var firstRow: XCUIElement {
        app.descendants(matching: .any)["tableRow"].firstMatch
    }
}
