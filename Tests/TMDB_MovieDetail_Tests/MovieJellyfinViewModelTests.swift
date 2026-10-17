import SwiftfinLauncher
@testable import TMDB_MovieDetail
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

    func testLoadSearchesAgainForDifferentTMDBIDWithSameTitle() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub()))
        let viewModel = MovieJellyfinViewModel(service: service)

        await viewModel.load(title: "Dune", tmdbID: 438_631)
        await viewModel.load(title: "Dune", tmdbID: 841)

        XCTAssertEqual(service.searchedTitles, ["Dune", "Dune"])
        XCTAssertEqual(service.searchedTMDBIDs, [438_631, 841])
    }

    func testReloadRevalidatesSameMovieAndUpdatesProgress() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub(id: "old-session-item")))
        let viewModel = MovieJellyfinViewModel(service: service)
        await viewModel.load(title: "Dune", tmdbID: 438_631)
        let refreshed = JellyfinMovieMatch.stub(id: "current-session-item", playedFraction: 0.75, resumeSeconds: 6986)
        service.findResult = .success(refreshed)

        await viewModel.reload(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .found(refreshed))
        XCTAssertEqual(service.searchedTitles, ["Dune", "Dune"])
    }

    func testDismissalRefreshesCurrentMovieProgress() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub()))
        let viewModel = MovieJellyfinViewModel(service: service)
        await viewModel.load(title: "Dune", tmdbID: 438_631)
        let refreshed = JellyfinMovieMatch.stub(playedFraction: 0.75, resumeSeconds: 6986)
        service.findResult = .success(refreshed)

        await viewModel.reloadIfCurrent(title: " Dune ", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .found(refreshed))
        XCTAssertEqual(service.searchedTMDBIDs, [438_631, 438_631])
    }

    func testOldMovieDismissalDoesNotSupersedeCurrentMovie() async {
        let service = StubJellyfinLibraryService(findResult: .success(.stub()))
        let viewModel = MovieJellyfinViewModel(service: service)
        await viewModel.load(title: "Dune", tmdbID: 438_631)
        let currentMatch = JellyfinMovieMatch.stub(id: "dune-1984")
        service.findResult = .success(currentMatch)
        await viewModel.load(title: "Dune", tmdbID: 841)

        await viewModel.reloadIfCurrent(title: "Dune", tmdbID: 438_631)

        XCTAssertEqual(viewModel.state, .found(currentMatch))
        XCTAssertEqual(service.searchedTMDBIDs, [438_631, 841])
    }

    func testReloadSupersedesSameQueryWhileLookupIsLoading() async {
        let service = DelayedJellyfinLibraryService()
        let viewModel = MovieJellyfinViewModel(service: service)
        let first = Task { await viewModel.load(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(1)
        let refreshed = Task { await viewModel.reload(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(2)
        let currentMatch = JellyfinMovieMatch.stub(id: "current-session-item")

        await service.completeRequest(1, with: .success(currentMatch))
        await refreshed.value
        await service.completeRequest(0, with: .success(.stub(id: "old-session-item")))
        await first.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
    }

    func testCancelledLateSuccessIsIgnoredAndSameQueryCanRetry() async {
        let service = DelayedJellyfinLibraryService()
        let viewModel = MovieJellyfinViewModel(service: service)
        let cancelled = Task { await viewModel.load(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(1)
        cancelled.cancel()
        await service.completeRequest(0, with: .success(.stub(id: "cancelled-item")))
        await cancelled.value
        XCTAssertEqual(viewModel.state, .loading)

        let retried = Task { await viewModel.load(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(2)
        let currentMatch = JellyfinMovieMatch.stub(id: "current-item")
        await service.completeRequest(1, with: .success(currentMatch))
        await retried.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
    }

    func testCancelledLateFailureDoesNotOverwriteNewerMatch() async {
        let service = DelayedJellyfinLibraryService()
        let viewModel = MovieJellyfinViewModel(service: service)
        let cancelled = Task { await viewModel.load(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(1)
        cancelled.cancel()
        let current = Task { await viewModel.reload(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(2)
        let currentMatch = JellyfinMovieMatch.stub(id: "current-item")
        await service.completeRequest(1, with: .success(currentMatch))
        await current.value
        await service.completeRequest(0, with: .failure(StubError()))
        await cancelled.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
    }

    func testSupersededNotConnectedErrorDoesNotHideNewerMovie() async {
        let service = DelayedJellyfinLibraryService()
        let viewModel = MovieJellyfinViewModel(service: service)
        let first = Task { await viewModel.load(title: "Dune", tmdbID: 438_631) }
        await service.waitForRequests(1)
        let second = Task { await viewModel.load(title: "Dune", tmdbID: 841) }
        await service.waitForRequests(2)
        let currentMatch = JellyfinMovieMatch.stub(id: "dune-1984")
        await service.completeRequest(1, with: .success(currentMatch))
        await second.value
        await service.completeRequest(0, with: .failure(JellyfinLibraryError.notConnected))
        await first.value

        XCTAssertEqual(viewModel.state, .found(currentMatch))
        XCTAssertTrue(viewModel.isVisible)
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
