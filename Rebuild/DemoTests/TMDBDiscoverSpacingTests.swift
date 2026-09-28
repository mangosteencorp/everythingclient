import XCTest

/// The Discover tab's rows — movie genres, TV genres, popular people, trending — scroll
/// sideways, and each item needs clear space from the next one instead of touching it.
final class TMDBDiscoverSpacingTests: XCTestCase {
    @MainActor
    func testDiscoverRowItemsDoNotTouch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["INTEGRATION_TEST_NAME"] = "TMDBTabsSavedShell"
        app.launchArguments += [
            "--uitesting", "-AppleLanguages", "(en)",
            "-design_coordinator_selections", "{ AppShellDesign = bottomTabBar; }",
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        // The system tab bar sometimes exposes its buttons without their identifiers.
        let discoverTab = app.buttons.matching(
            NSPredicate(format: "identifier == 'tab.marketplace' OR label == 'Discover'")
        ).firstMatch
        XCTAssertTrue(discoverTab.waitForExistence(timeout: 15), "No Discover tab")
        discoverTab.tap()
        // The first movie and TV genres TMDB lists; every row fills in at once.
        XCTAssertTrue(app.staticTexts["Adventure"].waitForExistence(timeout: 15), "Movie genres did not load")
        XCTAssertTrue(app.staticTexts["Action & Adventure"].exists, "TV genres did not load")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "discover_rows"
        attachment.lifetime = .keepAlways
        add(attachment)

        // One snapshot of the whole tree: cheaper than asking every cell for its frame.
        let discover = app.collectionViews.containing(NSPredicate(format: "label == 'Movie Genres'")).firstMatch
        let rows = Dictionary(grouping: try discover.snapshot().cells) {
            Int($0.frame.midY.rounded())
        }
        XCTAssertGreaterThanOrEqual(rows.count(where: { $0.value.count > 1 }), 2, "Found no genre rows")
        for row in rows.values {
            let items = row.sorted { $0.frame.minX < $1.frame.minX }
            for (left, right) in zip(items, items.dropFirst()) {
                XCTAssertGreaterThanOrEqual(
                    right.frame.minX - left.frame.maxX, 8, "\"\(left.text)\" and \"\(right.text)\" touch"
                )
            }
        }
    }
}

private extension XCUIElementSnapshot {
    /// Every cell below this element, however deep its row's own scroll view nests it.
    var cells: [XCUIElementSnapshot] {
        children.flatMap { $0.elementType == .cell ? [$0] : $0.cells }
    }

    /// The first text inside, for failure messages: the cells carry no label of their own.
    var text: String {
        elementType == .staticText ? label : children.lazy.map(\.text).first { !$0.isEmpty } ?? ""
    }
}
