import Tests_Shared_Helpers
@testable import TMDB_MovieDetail
import TMDB_Shared_Backend
import XCTest

@MainActor
final class MovieCastingViewModelTests: XCTestCase {
    private func makeAPI(movieId: Int = 1) throws -> StubTMDBAPIRequester {
        let api = StubTMDBAPIRequester()
        api.stub(
            .credits(movie: movieId),
            with: try JSONFixture.decode(MovieCreditsModel.self, from: TMDBJSON.movieCredits(id: movieId))
        )
        return api
    }

    func testLoadMapsCastMembersOntoPeople() async throws {
        let viewModel = MovieCastingViewModel(apiService: try makeAPI())

        await viewModel.load(movieId: 1)

        let cast = try XCTUnwrap(viewModel.state.value?.cast)
        XCTAssertEqual(cast.map(\.name), ["Timothee"])
        // Cast members carry a character and no department; crew is the other way around.
        XCTAssertEqual(cast.first?.character, "Paul")
        XCTAssertNil(cast.first?.department)
        XCTAssertEqual(cast.first?.profilePath, "/cast.jpg")
    }

    func testLoadMapsCrewMembersOntoPeople() async throws {
        let viewModel = MovieCastingViewModel(apiService: try makeAPI())

        await viewModel.load(movieId: 1)

        let crew = try XCTUnwrap(viewModel.state.value?.crew)
        XCTAssertEqual(crew.map(\.name), ["Denis"])
        XCTAssertEqual(crew.first?.department, "Directing")
        XCTAssertNil(crew.first?.character)
    }

    func testLoadRequestsTheCreditsEndpointOnlyOnce() async throws {
        let api = try makeAPI()
        let viewModel = MovieCastingViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.load(movieId: 1)

        XCTAssertEqual(api.requestedPaths, ["movie/1/credits"])
    }

    func testReloadRefetches() async throws {
        let api = try makeAPI()
        let viewModel = MovieCastingViewModel(apiService: api)

        await viewModel.load(movieId: 1)
        await viewModel.reload(movieId: 1)

        XCTAssertEqual(api.requestedPaths.count, 2)
    }

    func testLoadSurfacesAFailure() async {
        let api = StubTMDBAPIRequester()
        api.stub(.credits(movie: 1), failingWithMessage: "boom")
        let viewModel = MovieCastingViewModel(apiService: api)

        await viewModel.load(movieId: 1)

        XCTAssertNotNil(viewModel.state.errorMessage)
    }
}
