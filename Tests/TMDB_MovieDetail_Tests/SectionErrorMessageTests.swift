import SwiftUI
import Tests_Shared_Helpers
@testable import TMDB_MovieDetail
import XCTest

/// A failed section names what could not load; the view model's error text is never put on screen.
@MainActor
final class SectionErrorMessageTests: XCTestCase {
    private let rawError = "The operation couldn’t be completed. (TMDB_Shared_Backend.TMDBAPIError error 0.)"

    func testCreditSectionShowsFriendlyMessage() {
        let viewModel = MovieCastingViewModel(apiService: StubTMDBAPIRequester())
        viewModel.state = .error(rawError)

        assertFriendly(MovieCreditSection<Int>(movieId: 1, creditsViewModel: viewModel), shows: L10n.castLoadFailed)
    }

    func testWatchProvidersSectionShowsFriendlyMessage() {
        let viewModel = MovieWatchProvidersViewModel(apiService: StubTMDBAPIRequester())
        viewModel.state = .error(rawError)

        assertFriendly(
            MovieWatchProvidersSection(movieId: 1, watchProvidersViewModel: viewModel),
            shows: L10n.watchProvidersLoadFailed
        )
    }

    func testJellyfinSectionShowsFriendlyMessage() {
        let viewModel = MovieJellyfinViewModel(service: StubJellyfinLibraryService())
        viewModel.state = .error(rawError)

        assertFriendly(
            MovieJellyfinSection(movieTitle: "Dune", movieId: 1, jellyfinViewModel: viewModel),
            shows: L10n.jellyfinLoadFailed
        )
    }

    func testOSTSectionShowsFriendlyMessage() {
        let viewModel = MovieOSTViewModel(catalogService: StubMusicCatalogService())
        viewModel.state = .error(rawError)

        assertFriendly(MovieOSTSection(ostViewModel: viewModel), shows: L10n.soundtrackLoadFailed)
    }

    /// `dump` prints every stored value in the body, including the strings held by `Text`, in their
    /// quoted and escaped debug form.
    private func assertFriendly(_ section: some View, shows message: String, line: UInt = #line) {
        var rendered = ""
        dump(section.body, to: &rendered)

        XCTAssertTrue(rendered.contains(String(reflecting: message)), line: line)
        XCTAssertFalse(rendered.contains("TMDBAPIError"), line: line)
    }
}
