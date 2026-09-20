import XCTest

/// Captured by `bundle exec fastlane screenshots`; outside fastlane `snapshot` only waits and does nothing else.
final class ScreenshotTests: BaseTestCase {
    @MainActor
    func testTMDBTabs() { capture("TMDBTabsNormal", waitingFor: "movies_list") }

    @MainActor
    func testTMDBSearch() { capture("TMDBSearch", waitingFor: "search_results") }

    @MainActor
    func testTMDBDiscover() { capture("TMDBDiscover") }

    @MainActor
    func testTMDBMovieDetail() { capture("TMDBMovieDetail", waitingFor: "movieDetail.demo.page") }

    @MainActor
    func testTMDBTVShowDetail() { capture("TMDBTVShowDetail") }

    @MainActor
    func testTMDBPersonDetail() { capture("TMDBPersonDetail", waitingFor: "personDetail.demo.page") }

    @MainActor
    func testTMDBSettings() { capture("TMDBSettings", waitingFor: "settings.page") }

    @MainActor
    func testPokedexList() { capture("PokedexList") }

    @MainActor
    func testPokedexDetail() { capture("PokedexDetail") }

    @MainActor
    private func capture(_ demo: String, waitingFor identifier: String? = nil) {
        setupSnapshot(app)
        launchAppAndWait(withDemo: demo, timeout: 20)
        waitForElement(withIdentifier: identifier ?? "integration.preview.\(demo)", timeout: 20)
        snapshot(demo, timeWaitingForIdle: 20)
    }
}
