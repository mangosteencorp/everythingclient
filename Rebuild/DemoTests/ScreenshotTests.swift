import Integration_test
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

    // MARK: - Preview catalogs

    // Every module's Xcode previews, each filed as `<module>_<preview>`.

    @MainActor
    func testPreviewsTMDB() { captureCatalog("TMDB") }

    @MainActor
    func testPreviewsTMDBFeed() { captureCatalog("TMDBFeed") }

    @MainActor
    func testPreviewsTMDBSearch() { captureCatalog("TMDBSearch") }

    @MainActor
    func testPreviewsTMDBDiscover() { captureCatalog("TMDBDiscover") }

    @MainActor
    func testPreviewsTMDBProfile() { captureCatalog("TMDBProfile") }

    @MainActor
    func testPreviewsTMDBMovieDetail() { captureCatalog("TMDBMovieDetail") }

    @MainActor
    func testPreviewsTMDBTVShowDetail() { captureCatalog("TMDBTVShowDetail") }

    @MainActor
    func testPreviewsTMDBPerson() { captureCatalog("TMDBPerson") }

    @MainActor
    func testPreviewsPhotoListViewer() { captureCatalog("PhotoListViewer") }

    @MainActor
    func testPreviewsTMDBSharedUI() { captureCatalog("TMDBSharedUI") }

    @MainActor
    func testPreviewsTMDBSharedBackend() { captureCatalog("TMDBSharedBackend") }

    @MainActor
    func testPreviewsSharedUISupport() { captureCatalog("SharedUISupport") }

    @MainActor
    func testPreviewsCoreFeatures() { captureCatalog("CoreFeatures") }

    @MainActor
    func testPreviewsPokedex() { captureCatalog("Pokedex") }

    @MainActor
    func testPreviewsPokedexPokelist() { captureCatalog("PokedexPokelist") }

    @MainActor
    func testPreviewsPokedexDetail() { captureCatalog("PokedexDetail") }

    @MainActor
    func testPreviewsEverythingClient() { captureCatalog("EverythingClient") }

    /// The same views as demos captured above, so capturing them again would only duplicate them.
    private static let capturedAsDemos: Set<String> = [
        "TMDB/tabsNormal",
        "TMDBSearch/allScopes",
        "TMDBDiscover/demo",
        "TMDBMovieDetail/demo",
        "TMDBTVShowDetail/demo",
        "PokedexPokelist/demo",
        "PokedexDetail/demo",
    ]

    @MainActor
    private func captureCatalog(_ module: String) {
        // One preview that fails to render is reported by name without losing the rest.
        continueAfterFailure = true
        setupSnapshot(app)
        app.launchArguments += Self.defaultDesigns

        for entry in IntegrationTestLauncher.previewCatalog(module: module) where !Self.capturedAsDemos.contains(entry.id) {
            XCTContext.runActivity(named: entry.id) { _ in
                launchApp(withDemo: entry.id)
                let root = app.descendants(matching: .any)[entry.accessibilityIdentifier].firstMatch
                XCTAssertTrue(root.waitForExistence(timeout: 20), "\(entry.id) did not render")
                snapshot(entry.snapshotName, timeWaitingForIdle: 10)
            }
        }
    }

    /// Some previews pick a design in the shared, saved design store; every capture starts from
    /// the default designs so one capture's pick never shows up in another.
    private static let defaultDesigns = ["-design_coordinator_selections", "{}"]

    @MainActor
    private func capture(_ demo: String, waitingFor identifier: String? = nil) {
        setupSnapshot(app)
        app.launchArguments += Self.defaultDesigns
        launchAppAndWait(withDemo: demo, timeout: 20)
        waitForElement(withIdentifier: identifier ?? "integration.preview.\(demo)", timeout: 20)
        snapshot(demo, timeWaitingForIdle: 20)
    }
}
