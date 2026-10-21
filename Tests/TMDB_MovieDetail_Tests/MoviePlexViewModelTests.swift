import PlexIntegration
@testable import TMDB_MovieDetail
import XCTest

@MainActor
final class MoviePlexViewModelTests: XCTestCase {
    func testStartsHiddenSoSignedOutUsersNeverSeeASpinner() {
        let viewModel = MoviePlexViewModel(service: StubPlexLibraryService())

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadStaysHiddenWithoutSearchingWhenNobodyIsSignedIn() async {
        let service = StubPlexLibraryService(signedIn: false)
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "Dune", year: 2021)

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertFalse(viewModel.isVisible)
        XCTAssertTrue(service.searchedTitles.isEmpty)
    }

    func testLoadHidesTheSectionWhenTheSessionTurnsOutNotConnected() async {
        let service = StubPlexLibraryService(findResult: .failure(PlexLibraryError.notConnected))
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "Dune", year: 2021)

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadSearchesTheTrimmedTitleAndYearAndPublishesTheMatch() async {
        let match = PlexMovieMatch.stub(playedFraction: 0.35, resumeSeconds: 3260)
        let service = StubPlexLibraryService(findResult: .success(match))
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "  Dune  ", year: 2021)

        XCTAssertEqual(service.searchedTitles, ["Dune"])
        XCTAssertEqual(service.searchedYears, [2021])
        XCTAssertEqual(viewModel.state, .found(match))
        XCTAssertTrue(viewModel.isVisible)
    }

    func testLoadHidesTheSectionWhenTheMovieIsNotInTheLibrary() async {
        let viewModel = MoviePlexViewModel(service: StubPlexLibraryService(findResult: .success(nil)))

        await viewModel.load(title: "Dune", year: 2021)

        XCTAssertEqual(viewModel.state, .notInLibrary)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadSkipsARepeatOfTheSameQuery() async {
        let service = StubPlexLibraryService(findResult: .success(.stub()))
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "Dune", year: 2021)
        await viewModel.load(title: " Dune ", year: 2021)

        XCTAssertEqual(service.searchedTitles, ["Dune"])
    }

    func testLoadSearchesAgainWhenThePlaceholderResolvesOrTheYearDiffers() async {
        let service = StubPlexLibraryService(findResult: .success(.stub()))
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "...", year: nil)
        await viewModel.load(title: "Dune", year: 2021)
        await viewModel.load(title: "Dune", year: 1984)

        XCTAssertEqual(service.searchedTitles, ["...", "Dune", "Dune"])
        XCTAssertEqual(service.searchedYears, [nil, 2021, 1984])
    }

    func testLoadSurfacesAFailureAndReloadRetriesIt() async {
        let service = StubPlexLibraryService(findResult: .failure(StubError()))
        let viewModel = MoviePlexViewModel(service: service)

        await viewModel.load(title: "Dune", year: 2021)
        XCTAssertEqual(viewModel.state, .error("stub failure"))
        XCTAssertTrue(viewModel.isVisible)

        service.findResult = .success(.stub())
        await viewModel.reload(title: "Dune", year: 2021)

        XCTAssertEqual(viewModel.state, .found(.stub()))
        XCTAssertEqual(service.searchedTitles, ["Dune", "Dune"])
    }

    func testDismissalRefreshesCurrentMovieProgress() async {
        let service = StubPlexLibraryService(findResult: .success(.stub()))
        let viewModel = MoviePlexViewModel(service: service)
        await viewModel.load(title: "Dune", year: 2021)
        let refreshed = PlexMovieMatch.stub(playedFraction: 0.75, resumeSeconds: 6986)
        service.findResult = .success(refreshed)

        await viewModel.reloadIfCurrent(title: " Dune ", year: 2021)

        XCTAssertEqual(viewModel.state, .found(refreshed))
        XCTAssertEqual(service.searchedYears, [2021, 2021])
    }

    func testOldMovieDismissalDoesNotSupersedeCurrentMovie() async {
        let service = StubPlexLibraryService(findResult: .success(.stub()))
        let viewModel = MoviePlexViewModel(service: service)
        await viewModel.load(title: "Dune", year: 2021)
        let currentMatch = PlexMovieMatch.stub(id: "dune-1984")
        service.findResult = .success(currentMatch)
        await viewModel.load(title: "Dune", year: 1984)

        await viewModel.reloadIfCurrent(title: "Dune", year: 2021)

        XCTAssertEqual(viewModel.state, .found(currentMatch))
        XCTAssertEqual(service.searchedYears, [2021, 1984])
    }

    func testReloadSupersedesSameQueryWhileLookupIsLoading() async {
        let service = DelayedPlexLibraryService()
        let viewModel = MoviePlexViewModel(service: service)
        let first = Task { await viewModel.load(title: "Dune", year: 2021) }
        await service.waitForRequests(1)
        let refreshed = Task { await viewModel.reload(title: "Dune", year: 2021) }
        await service.waitForRequests(2)
        let currentMatch = PlexMovieMatch.stub(id: "current")

        await service.completeRequest(1, with: .success(currentMatch))
        await refreshed.value
        await service.completeRequest(0, with: .success(.stub(id: "stale")))
        await first.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
    }

    func testCancelledLateSuccessIsIgnoredAndSameQueryCanRetry() async {
        let service = DelayedPlexLibraryService()
        let viewModel = MoviePlexViewModel(service: service)
        let cancelled = Task { await viewModel.load(title: "Dune", year: 2021) }
        await service.waitForRequests(1)
        cancelled.cancel()
        await service.completeRequest(0, with: .success(.stub(id: "cancelled")))
        await cancelled.value
        XCTAssertEqual(viewModel.state, .loading)

        let retried = Task { await viewModel.load(title: "Dune", year: 2021) }
        await service.waitForRequests(2)
        let currentMatch = PlexMovieMatch.stub(id: "current")
        await service.completeRequest(1, with: .success(currentMatch))
        await retried.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
    }

    func testSupersededNotConnectedErrorDoesNotHideNewerMovie() async {
        let service = DelayedPlexLibraryService()
        let viewModel = MoviePlexViewModel(service: service)
        let first = Task { await viewModel.load(title: "Dune", year: 2021) }
        await service.waitForRequests(1)
        let second = Task { await viewModel.load(title: "Dune", year: 1984) }
        await service.waitForRequests(2)
        let currentMatch = PlexMovieMatch.stub(id: "dune-1984")
        await service.completeRequest(1, with: .success(currentMatch))
        await second.value
        await service.completeRequest(0, with: .failure(PlexLibraryError.notConnected))
        await first.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
        XCTAssertTrue(viewModel.isVisible)
    }
}
