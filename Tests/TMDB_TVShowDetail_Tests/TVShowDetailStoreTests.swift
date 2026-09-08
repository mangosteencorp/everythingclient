import Tests_Shared_Helpers
import TMDB_Shared_Backend
@testable import TMDB_TVShowDetail
import XCTest

@available(iOS 15, *)
@MainActor
final class TVShowDetailStoreTests: XCTestCase {
    private func makeAPI(showId: Int = 1399) throws -> StubTMDBAPIRequester {
        let api = StubTMDBAPIRequester()
        api.stub(
            .tvShowDetail(show: showId),
            with: try JSONFixture.decode(TVShowDetailModel.self, from: TMDBJSON.tvShowDetail(id: showId))
        )
        return api
    }

    func testLoadPublishesTheShow() async throws {
        let api = try makeAPI()
        let store = TVShowDetailView.Store(apiService: api, tvShowId: 1399)

        await store.load()

        XCTAssertEqual(store.state.loadedShow?.name, "Game of Thrones")
        XCTAssertEqual(api.requestedPaths, ["tv/1399"])
    }

    func testLoadOnlyRunsOnceFromInitial() async throws {
        let api = try makeAPI()
        let store = TVShowDetailView.Store(apiService: api, tvShowId: 1399)

        await store.load()
        await store.load()

        XCTAssertEqual(api.requestedPaths.count, 1)
    }

    func testReloadRefetchesAfterASuccessfulLoad() async throws {
        let api = try makeAPI()
        let store = TVShowDetailView.Store(apiService: api, tvShowId: 1399)

        await store.load()
        await store.reload()

        XCTAssertEqual(api.requestedPaths.count, 2)
    }

    func testLoadSurfacesTheUnderlyingErrorMessage() async {
        let api = StubTMDBAPIRequester()
        api.stub(.tvShowDetail(show: 1399), failingWithMessage: "the server is down")
        let store = TVShowDetailView.Store(apiService: api, tvShowId: 1399)

        await store.load()

        XCTAssertEqual(store.state.errorMessage, "the server is down")
    }

    func testReloadRecoversFromAnError() async throws {
        let api = StubTMDBAPIRequester()
        api.stub(.tvShowDetail(show: 1399), failingWithMessage: "boom")
        let store = TVShowDetailView.Store(apiService: api, tvShowId: 1399)

        await store.load()
        api.stub(.tvShowDetail(show: 1399), with: try JSONFixture.decode(TVShowDetailModel.self, from: TMDBJSON.tvShowDetail()))
        await store.reload()

        XCTAssertNotNil(store.state.loadedShow)
    }
}

@available(iOS 15, *)
private extension TVShowDetailView.ViewState {
    var loadedShow: TVShowDetailModel? { if case let .loaded(show) = self { return show }; return nil }
    var errorMessage: String? { if case let .error(message) = self { return message }; return nil }
}
