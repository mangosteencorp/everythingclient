@testable import TMDB_MovieDetail
import third_party
import XCTest

@MainActor
final class MovieJellyfinViewModelTests: XCTestCase {
    func testLoadReportsUnavailableWithoutSearchingWhenSwiftfinIsNotInTheBuild() async {
        let service = StubJellyfinLibraryService(available: false)
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertFalse(viewModel.isVisible)
        XCTAssertTrue(service.searchedTitles.isEmpty)
    }

    func testLoadHidesTheSectionWhenNoServerIsConnected() async {
        let service = StubJellyfinLibraryService(findResult: .failure(JellyfinLibraryError.notConnected))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadSearchesTheResolvedTitleAndPublishesTheMatch() async {
        let match = JellyfinMovieMatch.stub(playedFraction: 0.35, resumeSeconds: 3260)
        let service = StubJellyfinLibraryService(findResult: .success(match))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "  Dune  ", tmdbID: 438_631)

        XCTAssertEqual(service.searchedTitles, ["Dune"])
        XCTAssertEqual(service.searchedTMDBIDs, [438_631])
        XCTAssertEqual(viewModel.state, .found(match))
        XCTAssertTrue(viewModel.isVisible)
    }

    func testLoadHidesTheSectionWhenTheMovieIsNotInTheLibrary() async {
        let service = StubJellyfinLibraryService(findResult: .success(nil))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .notInLibrary)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadSkipsARepeatOfTheSameTitle() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub()))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)
        await viewModel.load(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(service.searchedTitles, ["Dune"])
    }

    func testLoadSearchesAgainWhenThePlaceholderTitleResolves() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub()))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "...", tmdbID: 438_631)
        await viewModel.load(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(service.searchedTitles, ["...", "Dune"])
    }

    func testLoadSurfacesAFailureAndReloadRetriesIt() async {
        let service = StubJellyfinLibraryService(findResult: .failure(StubError()))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)
        XCTAssertEqual(viewModel.state, .error("stub failure"))
        XCTAssertTrue(viewModel.isVisible)

        service.findResult = .success(.stub())
        await viewModel.reload(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .found(.stub()))
        XCTAssertEqual(service.searchedTitles, ["Dune", "Dune"])
    }
}
