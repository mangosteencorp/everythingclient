import XCTest

/// Unfolding the iPhone Duo flips both size classes in one trait change, and the sectioned shell
/// swaps its whole tab structure on the horizontal one. UIKit then rebuilt the tab bar from the
/// outgoing tabs mid-update and crashed inserting a nil item.
///
/// XCUITest cannot fold a device, but rotating a Max-size iPhone makes the same jump (compact
/// width, regular height ↔ regular width, compact height), so run this on one, e.g. iPhone 18 Pro
/// Max. Elsewhere rotation keeps the width class and the test passes without exercising the swap.
final class TMDBSectionedShellRotationTests: XCTestCase {
    @MainActor
    func testRotatingSectionedShellKeepsAppAlive() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)"]
        app.launch()
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }

        // The app root seeds the bottom tab bar, so the shell is picked from the shuffle menu.
        let shuffle = app.buttons["design.shuffle.button"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 15), "No design shuffle button")
        shuffle.press(forDuration: 1)
        app.buttons["App Shell"].tap()
        app.buttons["Sectioned Sidebar"].tap()
        let discover = app.buttons["tab.marketplace"]
        XCTAssertTrue(discover.waitForExistence(timeout: 10), "The sectioned shell did not open")

        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(discover.waitForExistence(timeout: 10), "The app did not survive rotating to \(orientation.rawValue)")
        }
    }
}
