import XCTest

extension XCUIApplication {
    /// The app saves the cursor of each group. These arguments override
    /// the saved rows for one launch, so each group starts on its first
    /// row and a test does not depend on an earlier test.
    func startCursorsOnFirstRow() {
        let groups = ["Index", "Währungen", "Schweiz", "USA", "Europa", "Welt"]
        launchArguments += groups.flatMap { ["-cursorRowId.\($0)", ""] }
    }
}
