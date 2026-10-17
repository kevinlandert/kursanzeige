import XCTest

/// The top bar during a refresh. The test starts a real refresh, so it
/// needs the network. It waits for the end of the refresh, so the next
/// test starts without a refresh.
@MainActor
final class RefreshButtonUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
    }

    func testTopBarButtonsKeepSizeAndPlaceDuringRefresh() {
        let settingsButton = app.buttons["settingsButton"]
        let framesBefore = [settingsButton.frame, refreshButton.frame]

        refreshButton.tap()
        waitForLabel(beginningWith: "Lädt", timeout: 2)

        XCTAssertEqual([settingsButton.frame, refreshButton.frame], framesBefore)
        waitForLabel(beginningWith: "Aktualisieren", timeout: 120)
    }

    /// The progress shows in place of the time of the last refresh. The
    /// group buttons under the top bar must not move. On an 11-inch iPad in
    /// portrait, the time takes two lines and the progress takes less space.
    func testGroupButtonsKeepPlaceDuringRefresh() {
        let startOrientation = XCUIDevice.shared.orientation
        addTeardownBlock { XCUIDevice.shared.orientation = startOrientation }
        XCUIDevice.shared.orientation = .portrait
        let groupButton = app.buttons["Index"]
        let frameBefore = groupButton.frame

        refreshButton.tap()
        waitForLabel(beginningWith: "Lädt", timeout: 2)

        XCTAssertEqual(groupButton.frame, frameBefore)
        waitForLabel(beginningWith: "Aktualisieren", timeout: 120)
    }

    private var refreshButton: XCUIElement {
        app.buttons["refresh"]
    }

    /// The start of the label only: VoiceOver can add the state of the
    /// spinner to the text.
    private func waitForLabel(beginningWith text: String, timeout: TimeInterval) {
        let hasLabel = NSPredicate(format: "label BEGINSWITH %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: hasLabel, object: refreshButton)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }
}
