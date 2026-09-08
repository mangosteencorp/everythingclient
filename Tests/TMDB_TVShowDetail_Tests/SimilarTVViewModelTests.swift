import Tests_Shared_Helpers
import TMDB_Shared_Backend
@testable import TMDB_TVShowDetail
import XCTest

@available(iOS 17, *)
@MainActor
final class SimilarTVViewModelTests: XCTestCase {
    private func similarStub(ids: [Int]) throws -> TVShowListResultModel {
        try JSONFixture.decode(TVShowListResultModel.self, from: TMDBJSON.tvShowList(ids: ids))
    }

    /// Signed out: the account lookup fails, so favourites are unknown rather than "not a favourite".
    func testLoadWithoutAnAccountLeavesFavouriteStateUnknown() async throws {
        let api = StubTMDBAPIRequester()
        api.stub(.similarTVShows(show: 1, page: nil), with: try similarStub(ids: [10, 11]))
        let viewModel = SimilarTVViewModel(apiService: api, tvShowId: 1)

        await viewModel.load()

        let items = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(items.map(\.showId), [10, 11])
        XCTAssertEqual(items.map(\.isFavorite), [nil, nil])
    }

    func testLoadMarksTheShowsThatAreFavourites() async throws {
        let api = StubTMDBAPIRequester()
        api.stub(.similarTVShows(show: 1, page: nil), with: try similarStub(ids: [10, 11]))
        api.stub(.accountInfo, with: try JSONFixture.decode(AccountInfoModel.self, from: TMDBJSON.accountInfo(id: 42)))
        api.stub(.getFavoriteTVShows(accountId: "42"), with: try similarStub(ids: [11]))
        let viewModel = SimilarTVViewModel(apiService: api, tvShowId: 1)

        await viewModel.load()

        let items = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(items.map(\.isFavorite), [false, true])
    }

    func testLoadPrefersThePosterAndFallsBackToTheBackdrop() async throws {
        let api = StubTMDBAPIRequester()
        let json = TMDBJSON.tvShowList(ids: [10]).replacingOccurrences(of: #""poster_path": "/poster10.jpg""#, with: #""poster_path": null"#)
        api.stub(.similarTVShows(show: 1, page: nil), with: try JSONFixture.decode(TVShowListResultModel.self, from: json))
        let viewModel = SimilarTVViewModel(apiService: api, tvShowId: 1)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.first?.tmdbImagePath, "/backdrop10.jpg")
    }

    func testLoadSurfacesAFailure() async {
        let api = StubTMDBAPIRequester()
        api.stub(.similarTVShows(show: 1, page: nil), failingWithMessage: "boom")
        let viewModel = SimilarTVViewModel(apiService: api, tvShowId: 1)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadOnlyRunsOnceFromInitial() async throws {
        let api = StubTMDBAPIRequester()
        api.stub(.similarTVShows(show: 1, page: nil), with: try similarStub(ids: [10]))
        let viewModel = SimilarTVViewModel(apiService: api, tvShowId: 1)

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(api.requestedPaths.filter { $0 == "tv/1/similar" }.count, 1)
    }

    func testPlaceholdersAreDistinctAndCarryALoadingTitle() {
        XCTAssertEqual(SimilarTVShowEntity.placeholders.count, 7)
        XCTAssertEqual(Set(SimilarTVShowEntity.placeholders.map(\.id)).count, 7)
        XCTAssertEqual(SimilarTVShowEntity.placeholders.first?.title, "Loading...")
    }
}
