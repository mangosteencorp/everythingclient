import XCTest

/// On the iPhone Duo the system puts the status bar, the navigation bar's buttons and the tab bar
/// in a rail beside the camera. Paged Tabs used a paging `TabView`, which laid its pages out inside
/// that safe area, so their navigation bars never reached the rail and kept the design shuffle
/// button in the page instead. On a compact iPhone the same inset put the paged bar 10pt lower.
///
/// Run it on the iPhone Duo and on a compact iPhone such as the iPhone 18 Pro Max.
final class TMDBPagedShellShuffleTests: XCTestCase {
    @MainActor
    func testPagedShellPutsShuffleButtonWhereTheTabBarShellDoes() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)"]
        app.launch()
        addTeardownBlock { app.terminate() }

        // The app root seeds the bottom tab bar, the reference for where the button belongs.
        let shuffle = app.buttons["design.shuffle.button"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 15), "No design shuffle button")
        let tabBarFrame = shuffle.frame

        shuffle.press(forDuration: 1)
        app.buttons["App Shell"].tap()
        app.buttons["Paged Tabs"].tap()
        XCTAssertTrue(app.pageIndicators.firstMatch.waitForExistence(timeout: 10), "Paged Tabs did not open")
        XCTAssertTrue(shuffle.waitForExistence(timeout: 10), "Paged Tabs lost the design shuffle button")
        assertSameSpot(shuffle.frame, tabBarFrame)

        // Turning away and back rebuilds the page, which must land in the same spot again.
        app.swipeLeft()
        XCTAssertTrue(shuffle.waitForNonExistence(timeout: 5), "Swiping did not turn the page")
        let dots = app.pageIndicators["paged.shell.dots"]
        XCTAssertTrue(dots.exists, "No page dots on the second page")
        dots.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        XCTAssertTrue(shuffle.waitForExistence(timeout: 5), "The dots did not turn back to Movies")
        assertSameSpot(shuffle.frame, tabBarFrame)
    }

    private func assertSameSpot(_ paged: CGRect, _ tabBar: CGRect, line: UInt = #line) {
        XCTAssertEqual(paged.midX, tabBar.midX, accuracy: 1, "Paged \(paged) vs tab bar \(tabBar)", line: line)
        XCTAssertEqual(paged.midY, tabBar.midY, accuracy: 1, "Paged \(paged) vs tab bar \(tabBar)", line: line)
    }
}
