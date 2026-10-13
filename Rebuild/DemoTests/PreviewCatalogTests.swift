import Integration_test
import XCTest

/// Launches every entry of each module's preview catalog — the views behind its Xcode previews —
/// and checks it rendered. One test per module; a broken entry is reported by name and does not
/// stop the rest of its module from being checked.
final class PreviewCatalogTests: BaseTestCase {
    @MainActor
    func testTMDB() { verifyCatalog("TMDB") }

    @MainActor
    func testTMDBFeed() { verifyCatalog("TMDBFeed") }

    @MainActor
    func testTMDBSearch() { verifyCatalog("TMDBSearch") }

    @MainActor
    func testTMDBDiscover() { verifyCatalog("TMDBDiscover") }

    @MainActor
    func testTMDBProfile() { verifyCatalog("TMDBProfile") }

    @MainActor
    func testTMDBMovieDetail() { verifyCatalog("TMDBMovieDetail") }

    @MainActor
    func testTMDBTVShowDetail() { verifyCatalog("TMDBTVShowDetail") }

    @MainActor
    func testTMDBPerson() { verifyCatalog("TMDBPerson") }

    @MainActor
    func testPhotoListViewer() { verifyCatalog("PhotoListViewer") }

    @MainActor
    func testTMDBSharedUI() { verifyCatalog("TMDBSharedUI") }

    @MainActor
    func testTMDBSharedBackend() { verifyCatalog("TMDBSharedBackend") }

    @MainActor
    func testSharedUISupport() { verifyCatalog("SharedUISupport") }

    @MainActor
    func testCoreFeatures() { verifyCatalog("CoreFeatures") }

    @MainActor
    func testPokedex() { verifyCatalog("Pokedex") }

    @MainActor
    func testPokedexPokelist() { verifyCatalog("PokedexPokelist") }

    @MainActor
    func testPokedexDetail() { verifyCatalog("PokedexDetail") }

    @MainActor
    func testEverythingClient() { verifyCatalog("EverythingClient") }

    @MainActor
    private func verifyCatalog(_ module: String) {
        continueAfterFailure = true
        // Some previews pick a design in the shared, saved design store; starting every launch
        // from the defaults keeps one entry's pick out of the next.
        app.launchArguments += ["-design_coordinator_selections", "{}"]
        let entries = IntegrationTestLauncher.previewCatalog(module: module)
        XCTAssertFalse(entries.isEmpty, "\(module) has no preview catalog")

        for entry in entries {
            XCTContext.runActivity(named: entry.id) { _ in
                launchApp(withDemo: entry.id)
                let root = app.descendants(matching: .any)[entry.accessibilityIdentifier].firstMatch
                XCTAssertTrue(root.waitForExistence(timeout: 20), "\(entry.id) did not render")
            }
        }
    }
}
