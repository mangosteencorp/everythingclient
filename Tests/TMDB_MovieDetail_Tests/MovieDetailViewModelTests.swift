import Tests_Shared_Helpers
@testable import TMDB_MovieDetail
import TMDB_Shared_Backend
import XCTest

@MainActor
final class MovieDetailViewModelTests: XCTestCase {
    private func makeAPI(movieId: Int = 1) throws -> StubTMDBAPIRequester {
        let api = StubTMDBAPIRequester()
        api.stub(.movieDetail(movie: movieId), with: try JSONFixture.decode(Movie.self, from: TMDBJSON.movieDetail(id: movieId)))
        return api
    }

    func testLoadPublishesTheMovie() async throws {
        let api = try makeAPI()
        let viewModel = MovieDetailViewModel(apiService: api)

        await viewModel.load(movieId: 1)

        XCTAssertEqual(viewModel.state.value?.id, 1)
        XCTAssertEqual(api.requestedPaths, ["movie/1"])
    }

    func testLoadIsIdempotentSoSeveralTaskModifiersCannotStack() async throws {
        let api = try makeAPI()
        let viewModel = MovieDetailViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.load(movieId: 1)

        XCTAssertEqual(api.requestedPaths.count, 1)
    }

    func testReloadFetchesAgainAfterASuccessfulLoad() async throws {
        let api = try makeAPI()
        let viewModel = MovieDetailViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.reload(movieId: 1)

        XCTAssertEqual(api.requestedPaths, ["movie/1", "movie/1"])
    }

    func testLoadSurfacesAFailureAndReloadRecoversFromIt() async throws {
        let api = StubTMDBAPIRequester()
        api.stub(.movieDetail(movie: 1), failingWithMessage: "boom")
        let viewModel = MovieDetailViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        XCTAssertNotNil(viewModel.state.errorMessage)

        api.stub(.movieDetail(movie: 1), with: try JSONFixture.decode(Movie.self, from: TMDBJSON.movieDetail()))
        await viewModel.reload(movieId: 1)

        XCTAssertEqual(viewModel.state.value?.id, 1)
    }

    func testAnUnstubbedEndpointIsReportedAsAnError() async {
        let viewModel = MovieDetailViewModel(apiService: StubTMDBAPIRequester())

        await viewModel.load(movieId: 99)

        XCTAssertNotNil(viewModel.state.errorMessage)
    }
}
