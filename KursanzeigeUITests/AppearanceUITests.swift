import XCTest

/// The light and dark button next to the settings button. The tests do
/// not check the colors: the button value shows the appearance. The app
/// stores the appearance, so each test starts in light mode.
@MainActor
final class AppearanceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(appearanceButton.waitForExistence(timeout: 5))
        if appearanceButton.value as? String == "Ein" {
            appearanceButton.tap()
        }
    }

    func testFirstTapSetsDarkAndSecondTapSetsLight() {
        appearanceButton.tap()
        XCTAssertEqual(appearanceButton.value as? String, "Ein")

        appearanceButton.tap()
        XCTAssertEqual(appearanceButton.value as? String, "Aus")
    }

    func testDarkAppearanceStaysAfterAppStartsAgain() {
        appearanceButton.tap()

        app.terminate()
        app.launch()

        XCTAssertTrue(appearanceButton.waitForExistence(timeout: 5))
        XCTAssertEqual(appearanceButton.value as? String, "Ein")
    }

    func testButtonIsOnTheLeftOfSettingsButtonInTheSameRow() {
        let settingsButton = app.buttons["Einstellungen öffnen"]

        XCTAssertLessThan(appearanceButton.frame.maxX, settingsButton.frame.minX)
        XCTAssertEqual(appearanceButton.frame.midY, settingsButton.frame.midY, accuracy: 1)
    }

    /// A wide gap makes a tap on the wrong button less probable.
    func testWideGapSeparatesEachButtonInTopBar() {
        let settingsButton = app.buttons["Einstellungen öffnen"]
        let refreshButton = app.buttons["Aktualisieren"]

        XCTAssertGreaterThanOrEqual(settingsButton.frame.minX - appearanceButton.frame.maxX, Self.minimumButtonGap)
        XCTAssertGreaterThanOrEqual(refreshButton.frame.minX - settingsButton.frame.maxX, Self.minimumButtonGap)
    }

    private static let minimumButtonGap: CGFloat = 40

    private var appearanceButton: XCUIElement {
        app.buttons["appearance"]
    }
}
