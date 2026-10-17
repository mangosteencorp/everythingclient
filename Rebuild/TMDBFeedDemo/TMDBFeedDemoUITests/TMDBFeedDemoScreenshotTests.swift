import XCTest

/// The live `demo` feed in every feed layout, for `bundle exec fastlane screenshots`.
/// The layout comes from the argument domain, which overrides the saved `DesignCoordinator` picks.
final class TMDBFeedDemoScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFeedList() {
        captureFeed(design: "list", as: "01_feed_list")
    }

    @MainActor
    func testFeedGrid() {
        captureFeed(design: "grid", as: "02_feed_grid")
    }

    @MainActor
    func testFeedCompactRows() {
        captureFeed(design: "compactRows", as: "03_feed_compact_rows")
    }

    @MainActor
    func testFeedPaletteCards() {
        captureFeed(design: "paletteCards", as: "04_feed_palette_cards")
    }

    @MainActor
    private func captureFeed(design: String, as name: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-design_coordinator_selections", "{ FeedContentDesign = \(design); }"]
        app.launch()
        app.buttons["demo"].tap()

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'movielist1.movierow'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 30), "The feed never loaded")
        captureScreen(named: name)
    }
}

extension XCTestCase {
    /// Attaches the whole screen as `name`. `fastlane screenshots` exports it from the result
    /// bundle and files it as `<run>/<demo>/<name>/<device>.png`.
    @MainActor
    func captureScreen(named name: String) {
        // Posters fade in from the network with nothing to wait on, so give them a moment.
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
