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

        for tab in ["popular", "topRated", "upcoming", "onTheAir", "airingToday", "search", "nowPlaying"] {
            let button = app.buttons["feed_tab_segment_\(tab)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing category \(tab)")
            button.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: button
            )
            XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed, "Cannot select \(tab)")

            // Catalyst propagates the page identifier onto its content. Query the
            // field by type, and verify navigation without depending on API data.
            if tab == "search" {
                XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5))
            } else if tab == "nowPlaying" {
                let searchDismissed = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "exists == false"), object: app.textFields.firstMatch
                )
                XCTAssertEqual(XCTWaiter.wait(for: [searchDismissed], timeout: 5), .completed)
            }
        }
    }
}
