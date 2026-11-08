import XCTest

/// Runs against the bundled IGN feed and a silent player (`-PodcastDemoFixtures`), so it needs no network and makes
/// no sound. Every test keeps a screenshot for review.
final class PodcastDemoUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor func testListShowsTheFeedsEpisodes() {
        let app = launch()

        XCTAssertTrue(episode("Clayface Review", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(episode("Superman Review", in: app).exists)
        XCTAssertFalse(app.descendants(matching: .any)["podcastDemo.matchedReview"].exists)
        attach(app, name: "Episode list")
    }

    @MainActor func testSearchingAMovieShowsItsReviewOnTopAndFilters() {
        let app = launch()
        XCTAssertTrue(episode("Clayface Review", in: app).waitForExistence(timeout: 10))

        search("Superman", in: app)

        let matched = app.descendants(matching: .any)["podcastDemo.matchedReview"]
        XCTAssertTrue(matched.waitForExistence(timeout: 5))
        XCTAssertTrue(matched.descendants(matching: .any).matching(titled("Superman Review")).firstMatch.exists)
        XCTAssertTrue(episode("Superman & Lois Season 4 Review", in: app).exists)
        XCTAssertFalse(episode("Clayface Review", in: app).exists)
        attach(app, name: "Search Superman")
    }

    @MainActor func testTappingAnEpisodeShowsTheMiniPlayer() {
        let app = launch()
        let clayface = episode("Clayface Review", in: app)
        XCTAssertTrue(clayface.waitForExistence(timeout: 10))

        clayface.tap()

        let miniPlayer = app.descendants(matching: .any)["podcastDemo.miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 5))
        let playPause = miniPlayer.buttons["podcast.player.playPause"]
        // The silent engine never reports the audio ready, so the episode stays loading until paused.
        XCTAssertEqual(playPause.label, "Loading")
        playPause.tap()
        XCTAssertTrue(playPause.wait(for: \.label, toEqual: "Play", timeout: 5))
        XCTAssertTrue(miniPlayer.descendants(matching: .any)["podcast.player.progress"].exists)
        attach(app, name: "Mini player paused")
    }

    @MainActor func testComponentsTabOpensAPreview() {
        let app = launch()
        let tab = app.tabBars.buttons["Components"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()

        let preview = app.buttons["podcastDemo.catalog.cardPlaying"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        preview.tap()

        XCTAssertTrue(app.descendants(matching: .any)["podcast.episode.card"].waitForExistence(timeout: 5))
        attach(app, name: "Card playing preview")
    }

    @MainActor private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-PodcastDemoFixtures"]
        app.launch()
        return app
    }

    /// An episode row; its accessibility label starts with the title, then the show, date and summary.
    @MainActor private func episode(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(identifier: "podcastDemo.episode").matching(titled(title)).firstMatch
    }

    private func titled(_ title: String) -> NSPredicate {
        NSPredicate(format: "label BEGINSWITH %@", title)
    }

    @MainActor private func search(_ text: String, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    @MainActor private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
