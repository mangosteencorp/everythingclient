import XCTest

final class TMDBFeedNavigationTests: XCTestCase {
    @MainActor
    func testOpenFeedAndSwitchCategories() {
        verifyCategorySwitching(demo: "TMDBFeed")
    }

    @MainActor
    func testSwitchCategoriesInsideAppTabs() {
        verifyCategorySwitching(demo: "TMDBTabsNormal")
    }

    @MainActor
    private func verifyCategorySwitching(demo: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = demo
        // Argument-domain defaults keep the test independent of saved design choices.
        // On Catalyst, also exercise migration from the broken nested system tabs.
        #if targetEnvironment(macCatalyst)
        let tabDesign = "systemTabs"
        #else
        let tabDesign = "topSegments"
        #endif
        app.launchArguments += [
            "--uitesting", "-AppleLanguages", "(en)",
            "-design_coordinator_selections",
            "{ FeedTabDesign = \(tabDesign); FeedContentDesign = list; AppNavigationDesign = splitView; }",
        ]
        app.launch()
        defer { app.terminate() }

        let initialTab = app.buttons["feed_tab_segment_nowPlaying"]
        XCTAssertTrue(initialTab.waitForExistence(timeout: 15))
        XCTAssertTrue(initialTab.isSelected)

        var selectedTab = initialTab
        // Search is no longer one of these: it is a root tab of its own (TMDB_Search).
        for tab in ["popular", "topRated", "upcoming", "onTheAir", "airingToday", "nowPlaying"] {
            let button = app.buttons["feed_tab_segment_\(tab)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing category \(tab)")
            // The bar centres the selected segment, so by `airingToday` the first ones sit off the
            // leading edge, where XCUITest cannot tap. Swipe the (always on-screen) selection instead.
            for _ in 0 ..< 3 where !app.frame.contains(CGPoint(x: button.frame.midX, y: button.frame.midY)) {
                if button.frame.midX < app.frame.midX {
                    selectedTab.swipeRight()
                } else {
                    selectedTab.swipeLeft()
                }
            }
            button.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: button
            )
            XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed, "Cannot select \(tab)")
            selectedTab = button
        }
    }
}
