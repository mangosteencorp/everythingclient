import Tests_Shared_Helpers
@testable import TMDB_MovieDetail
import TMDB_Shared_Backend
import XCTest

@MainActor
final class MovieWatchProvidersViewModelTests: XCTestCase {
    private func makeAPI(movieId: Int = 1) throws -> StubTMDBAPIRequester {
        let api = StubTMDBAPIRequester()
        api.stub(
            .watchProviders(movie: movieId),
            with: try JSONFixture.decode(WatchProviderResponse.self, from: TMDBJSON.watchProviders(id: movieId))
        )
        return api
    }

    func testLoadPublishesProvidersKeyedByRegion() async throws {
        let api = try makeAPI()
        let viewModel = MovieWatchProvidersViewModel(apiService: api)

        await viewModel.load(movieId: 1)

        let response = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(response.results["US"]?.flatrate?.map(\.providerName), ["Netflix"])
        XCTAssertEqual(api.requestedPaths, ["movie/1/watch/providers"])
    }

    func testLoadIsIdempotent() async throws {
        let api = try makeAPI()
        let viewModel = MovieWatchProvidersViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.load(movieId: 1)

        XCTAssertEqual(api.requestedPaths.count, 1)
    }

    func testReloadRefetches() async throws {
        let api = try makeAPI()
        let viewModel = MovieWatchProvidersViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.reload(movieId: 1)

        XCTAssertEqual(api.requestedPaths.count, 2)
    }

    func testLoadSurfacesAFailure() async {
        let api = StubTMDBAPIRequester()
        api.stub(.watchProviders(movie: 1), failingWithMessage: "boom")
        let viewModel = MovieWatchProvidersViewModel(apiService: api)

        await viewModel.load(movieId: 1)

        XCTAssertNotNil(viewModel.state.errorMessage)
    }
}
