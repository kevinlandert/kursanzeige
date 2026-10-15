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
        let appearanceButton = app.buttons["appearance"]
        let settingsButton = app.buttons["Einstellungen öffnen"]
        let framesBefore = [appearanceButton.frame, settingsButton.frame, refreshButton.frame]

        refreshButton.tap()
        waitForLabel(beginningWith: "Lädt", timeout: 2)

        XCTAssertEqual([appearanceButton.frame, settingsButton.frame, refreshButton.frame], framesBefore)
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
