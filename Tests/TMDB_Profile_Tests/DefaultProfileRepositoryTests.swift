import RxSwift
import Tests_Shared_Helpers
@testable import TMDB_Profile
import TMDB_Shared_Backend
import XCTest

final class DefaultProfileRepositoryTests: XCTestCase {
    private var disposeBag = DisposeBag()
    /// `asyncSingle` captures the repository weakly, so the test has to own it for the request's
    /// lifetime the way the Swinject container does in the app.
    private var repository: DefaultProfileRepository!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func makeRepository(_ api: StubTMDBAPIRequester) -> DefaultProfileRepository {
        repository = DefaultProfileRepository(apiService: api, authRepository: DefaultAuthRepository())
        return repository
    }

    private func value<T>(of single: Single<T>) -> Result<T, Error> {
        let expectation = expectation(description: "single")
        var outcome: Result<T, Error>!
        single.subscribe(
            onSuccess: { outcome = .success($0); expectation.fulfill() },
            onFailure: { outcome = .failure($0); expectation.fulfill() }
        )
        .disposed(by: disposeBag)
        wait(for: [expectation], timeout: 2)
        return outcome
    }

    func testGetAccountInfoMapsTheAvatarOutOfItsNesting() throws {
        let api = StubTMDBAPIRequester()
        api.stub(.accountInfo, with: try JSONFixture.decode(AccountInfoModel.self, from: TMDBJSON.accountInfo(id: 7)))

        let account = try value(of: makeRepository(api).getAccountInfo()).get()

        XCTAssertEqual(account.id, 7)
        XCTAssertEqual(account.username, "mrclient")
        XCTAssertEqual(account.avatarPath, "/avatar.jpg")
    }

    func testGetFavoriteMoviesMapsTheResponseOntoEntities() throws {
        let api = StubTMDBAPIRequester()
        api.stub(
            .getFavoriteMovies(accountId: "7"),
            with: try JSONFixture.decode(MovieListResultModel.self, from: TMDBJSON.movieList(ids: [1, 2]))
        )

        let movies = try value(of: makeRepository(api).getFavoriteMovies(accountId: "7")).get()

        XCTAssertEqual(movies.map(\.id), [1, 2])
        XCTAssertEqual(movies.first?.title, "Arrival 1")
        XCTAssertEqual(movies.first?.posterPath, "/p1.jpg")
    }

    func testGetFavoriteTVShowsMapsTheResponseOntoEntities() throws {
        let api = StubTMDBAPIRequester()
        api.stub(
            .getFavoriteTVShows(accountId: "7"),
            with: try JSONFixture.decode(TVShowListResultModel.self, from: TMDBJSON.tvShowList(ids: [10]))
        )

        let shows = try value(of: makeRepository(api).getFavoriteTVShows(accountId: "7")).get()

        XCTAssertEqual(shows.map(\.id), [10])
        XCTAssertEqual(shows.first?.firstAirDate, "2015-02-08")
    }

    func testGetWatchlistTVShowsUsesTheWatchlistEndpoint() throws {
        let api = StubTMDBAPIRequester()
        api.stub(
            .getWatchlistTVShows(accountId: "7"),
            with: try JSONFixture.decode(TVShowListResultModel.self, from: TMDBJSON.tvShowList(ids: [11]))
        )

        let shows = try value(of: makeRepository(api).getWatchlistTVShows(accountId: "7")).get()

        XCTAssertEqual(shows.map(\.id), [11])
        XCTAssertEqual(api.requestedPaths, ["account/7/watchlist/tv"])
    }

    func testAFailingRequestFailsTheSingle() {
        let api = StubTMDBAPIRequester()
        api.stub(.accountInfo, failingWithMessage: "not signed in")

        let outcome = value(of: makeRepository(api).getAccountInfo())

        XCTAssertNotNil(outcome.failureError)
    }

    /// Disposing has to cancel the underlying task, otherwise a dismissed screen keeps requesting.
    func testDisposingBeforeCompletionEmitsNothing() throws {
        let api = StubTMDBAPIRequester()
        api.stub(.accountInfo, with: try JSONFixture.decode(AccountInfoModel.self, from: TMDBJSON.accountInfo()))
        var emitted = false

        let disposable = makeRepository(api).getAccountInfo()
            .subscribe(onSuccess: { _ in emitted = true }, onFailure: { _ in emitted = true })
        disposable.dispose()

        let settled = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        XCTAssertFalse(emitted)
    }
}

private extension Result {
    var failureError: Failure? {
        if case let .failure(error) = self { return error }
        return nil
    }
}
