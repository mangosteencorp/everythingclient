@testable import TMDB_MovieDetail
import XCTest

@MainActor
final class MovieOSTViewModelTests: XCTestCase {
    // MARK: - Authorization

    func testLoadStaysNotDeterminedWhenAuthorizationNotDetermined() async {
        let service = StubMusicCatalogService(authorization: .notDetermined)
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertTrue(viewModel.state.isNotDetermined)
        XCTAssertTrue(service.searchedTerms.isEmpty)
    }

    func testLoadReportsDeniedWithoutSearching() async {
        let service = StubMusicCatalogService(authorization: .denied)
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertTrue(viewModel.state.isDenied)
        XCTAssertTrue(service.searchedTerms.isEmpty)
    }

    func testRequestAuthorizationGrantedSearchesTheRememberedTitle() async {
        let service = StubMusicCatalogService(
            authorization: .notDetermined,
            requestedAuthorization: .authorized,
            searchResult: .success([.stub(title: "Dune (Original Motion Picture Soundtrack)")])
        )
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")
        await viewModel.requestAuthorization()

        XCTAssertEqual(service.requestAuthorizationCallCount, 1)
        XCTAssertEqual(service.searchedTerms, ["Dune soundtrack"])
        XCTAssertEqual(viewModel.state.albums?.count, 1)
    }

    func testRequestAuthorizationDeniedWithoutAPriorLoadStaysDenied() async {
        let service = StubMusicCatalogService(authorization: .notDetermined, requestedAuthorization: .denied)
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.requestAuthorization()

        XCTAssertTrue(viewModel.state.isDenied)
    }

    func testRequestAuthorizationGrantedWithoutAPriorLoadHasNothingToSearch() async {
        let service = StubMusicCatalogService(authorization: .notDetermined, requestedAuthorization: .authorized)
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.requestAuthorization()

        XCTAssertTrue(viewModel.state.isNotDetermined)
        XCTAssertTrue(service.searchedTerms.isEmpty)
    }

    // MARK: - Searching

    func testLoadKeepsOnlySoundtrackAlbums() async {
        let service = StubMusicCatalogService(searchResult: .success([
            .stub(id: "1", title: "Dune (Original Motion Picture Soundtrack)"),
            .stub(id: "2", title: "Dune Sketchbook"),
            .stub(id: "3", title: "Dune OST"),
        ]))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertEqual(viewModel.state.albums?.map(\.id), ["1", "3"])
    }

    func testLoadCapsResultsAtFiveAlbums() async {
        let service = StubMusicCatalogService(searchResult: .success(
            (1 ... 8).map { .stub(id: "\($0)", title: "Dune Soundtrack \($0)") }
        ))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertEqual(viewModel.state.albums?.count, 5)
        XCTAssertEqual(service.searchedLimits, [10])
    }

    func testLoadReportsEmptyWhenNothingLooksLikeASoundtrack() async {
        let service = StubMusicCatalogService(searchResult: .success([.stub(title: "Dune Sketchbook")]))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertTrue(viewModel.state.isEmpty)
    }

    func testLoadSurfacesSearchFailure() async {
        let service = StubMusicCatalogService(searchResult: .failure(StubError()))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")

        XCTAssertEqual(viewModel.state.errorMessage, "stub failure")
    }

    // MARK: - Reload guards

    func testLoadIgnoresBlankTitles() async {
        let service = StubMusicCatalogService()
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "   ")

        XCTAssertTrue(service.searchedTerms.isEmpty)
    }

    func testLoadTrimsTheTitleBeforeSearching() async {
        let service = StubMusicCatalogService(searchResult: .success([.stub(title: "Dune Soundtrack")]))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "  Dune  ")

        XCTAssertEqual(service.searchedTerms, ["Dune soundtrack"])
    }

    func testRepeatedLoadOfTheSameTitleDoesNotSearchTwice() async {
        let service = StubMusicCatalogService(searchResult: .success([.stub(title: "Dune Soundtrack")]))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")
        await viewModel.load(for: "Dune")

        XCTAssertEqual(service.searchedTerms.count, 1)
    }

    func testLoadingADifferentTitleSearchesAgain() async {
        let service = StubMusicCatalogService(searchResult: .success([.stub(title: "Soundtrack")]))
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")
        await viewModel.load(for: "Arrival")

        XCTAssertEqual(service.searchedTerms, ["Dune soundtrack", "Arrival soundtrack"])
    }

    func testLoadRetriesTheSameTitleAfterADeniedResult() async {
        let service = StubMusicCatalogService(authorization: .denied)
        let viewModel = MovieOSTViewModel(catalogService: service)

        await viewModel.load(for: "Dune")
        service.authorization = .authorized
        service.searchResult = .success([.stub(title: "Dune Soundtrack")])
        await viewModel.load(for: "Dune")

        XCTAssertEqual(service.searchedTerms, ["Dune soundtrack"])
        XCTAssertEqual(viewModel.state.albums?.count, 1)
    }
}

// Pattern matching helpers so the assertions above read as one line each.
private extension MovieOSTState {
    var isNotDetermined: Bool { if case .notDetermined = self { return true }; return false }
    var isDenied: Bool { if case .denied = self { return true }; return false }
    var isEmpty: Bool { if case .empty = self { return true }; return false }
    var albums: [MovieOSTAlbumDisplayModel]? { if case let .success(albums) = self { return albums }; return nil }
    var errorMessage: String? { if case let .error(message) = self { return message }; return nil }
}
