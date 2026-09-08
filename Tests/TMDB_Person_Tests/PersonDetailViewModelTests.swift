import Tests_Shared_Helpers
@testable import TMDB_Person
import TMDB_Shared_Backend
import XCTest

@MainActor
final class PersonDetailViewModelTests: XCTestCase {
    private func makeAPI(personId: Int = 287) throws -> StubTMDBAPIRequester {
        let api = StubTMDBAPIRequester()
        api.stub(
            .personDetail(person: personId),
            with: try JSONFixture.decode(PersonDetail.self, from: TMDBJSON.personDetail(id: personId))
        )
        api.stub(
            .personMovieCredits(person: personId),
            with: try JSONFixture.decode(PersonMovieCredits.self, from: TMDBJSON.personMovieCredits(id: personId))
        )
        return api
    }

    func testLoadFetchesTheDetailAndTheCredits() async throws {
        let api = try makeAPI()
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()

        let payload = try XCTUnwrap(viewModel.state.loadedPayload)
        XCTAssertEqual(payload.detail.name, "Brad Pitt")
        XCTAssertEqual(payload.credits.cast.map(\.title), ["Se7en"])
        XCTAssertEqual(api.requestedPaths, ["person/287", "person/287/movie_credits"])
    }

    func testLoadOnlyRunsOnceFromInitial() async throws {
        let api = try makeAPI()
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(api.requestedPaths.count, 2)
    }

    func testReloadRefetchesBothEndpoints() async throws {
        let api = try makeAPI()
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()
        await viewModel.reload()

        XCTAssertEqual(api.requestedPaths.count, 4)
    }

    func testAFailingCreditsRequestFailsTheWholeLoad() async throws {
        let api = try makeAPI()
        api.stub(.personMovieCredits(person: 287), failingWithMessage: "credits are down")
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.errorMessage, "credits are down")
    }

    func testTheDetailRequestFailingSkipsTheCreditsRequest() async {
        let api = StubTMDBAPIRequester()
        api.stub(.personDetail(person: 287), failingWithMessage: "boom")
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()

        XCTAssertEqual(api.requestedPaths, ["person/287"])
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testReloadRecoversFromAnError() async throws {
        let api = try makeAPI()
        api.stub(.personDetail(person: 287), failingWithMessage: "boom")
        let viewModel = PersonDetailViewModel(apiService: api, personId: 287)

        await viewModel.load()
        api.stub(.personDetail(person: 287), with: try JSONFixture.decode(PersonDetail.self, from: TMDBJSON.personDetail()))
        await viewModel.reload()

        XCTAssertNotNil(viewModel.state.loadedPayload)
    }
}

private extension PersonDetailState {
    var loadedPayload: PersonDetailPayload? { if case let .loaded(payload) = self { return payload }; return nil }
    var errorMessage: String? { if case let .error(message) = self { return message }; return nil }
}
