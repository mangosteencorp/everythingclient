import XCTest

/// The live movie detail page, top and scrolled, for `bundle exec fastlane screenshots`.
final class TMDBMovieDetailDemoScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMovieDetail() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["demo"].tap()

        let page = app.descendants(matching: .any)["movieDetail.demo.page"].firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 20), "The movie detail page never opened")
        // The page is titled with a blank placeholder movie until TMDB answers.
        let titled = app.navigationBars.matching(NSPredicate(format: "identifier != ''")).firstMatch
        XCTAssertTrue(titled.waitForExistence(timeout: 20), "The movie never loaded")
        captureScreen(named: "01_movie_detail")

        app.collectionViews.firstMatch.swipeUp()
        app.collectionViews.firstMatch.swipeUp()
        captureScreen(named: "02_movie_detail_scrolled")
    }

    /// The `pager` catalog case: three sample movies, opened on the middle one, then swiped to
    /// the next. The title has to follow the page on screen.
    @MainActor
    func testMovieDetailPager() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["pager"].tap()

        let pager = app.descendants(matching: .any)["movieDetail.pager"].firstMatch
        XCTAssertTrue(pager.waitForExistence(timeout: 20), "The pager never opened")
        XCTAssertTrue(app.navigationBars["Kingdom of the Planet of the Apes"].waitForExistence(timeout: 5))
        captureScreen(named: "03_movie_detail_pager")

        pager.swipeLeft()
        XCTAssertTrue(app.navigationBars["Pokémon Detective Pikachu"].waitForExistence(timeout: 5), "Swiping did not move to the next movie")
        captureScreen(named: "04_movie_detail_pager_swiped")
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
