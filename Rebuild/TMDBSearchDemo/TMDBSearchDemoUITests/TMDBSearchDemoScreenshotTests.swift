import XCTest

/// Search pages backed by `StubSearchService`, so every run captures the same results,
/// for `bundle exec fastlane screenshots`.
final class TMDBSearchDemoScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSearchResults() {
        capture(preview: "allScopes", waitingFor: "search_results", as: "01_search_results")
    }

    @MainActor
    func testSearchMoviesFiltered() {
        capture(preview: "moviesFiltered", waitingFor: "search_filter_bar", as: "02_search_movies_filtered")
    }

    @MainActor
    func testSearchPeople() {
        capture(preview: "people", waitingFor: "search_results", as: "03_search_people")
    }

    @MainActor
    func testSearchIdle() {
        capture(preview: "idleRecentsAndTrending", waitingFor: "search_idle", as: "04_search_idle")
    }

    /// Opens one `TMDBSearchPreviewCatalog` entry from the demo's launcher list.
    @MainActor
    private func capture(preview: String, waitingFor identifier: String, as name: String) {
        let app = XCUIApplication()
        app.launch()
        app.buttons[preview].tap()

        let content = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(content.waitForExistence(timeout: 20), "\(preview) never showed \(identifier)")
        captureScreen(named: name)
    }
}

extension XCTestCase {
    /// Attaches the whole screen as `name`. `fastlane screenshots` exports it from the result
    /// bundle and files it as `<run>/<demo>/<name>/<device>.png`.
    @MainActor
    func captureScreen(named name: String) {
        // Artwork fades in with nothing to wait on, so give it a moment.
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
