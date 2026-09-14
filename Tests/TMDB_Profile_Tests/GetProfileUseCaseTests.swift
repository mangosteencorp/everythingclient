import RxSwift
@testable import TMDB_Profile
import XCTest

final class GetProfileUseCaseTests: XCTestCase {
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    private func run(_ useCase: GetProfileUseCaseProtocol) -> Result<ProfileEntity, Error> {
        let expectation = expectation(description: "profile")
        var outcome: Result<ProfileEntity, Error>!
        useCase.execute()
            .subscribe(
                onSuccess: { outcome = .success($0); expectation.fulfill() },
                onFailure: { outcome = .failure($0); expectation.fulfill() }
            )
            .disposed(by: disposeBag)
        wait(for: [expectation], timeout: 1)
        return outcome
    }

    func testExecuteCombinesTheAccountWithItsThreeLists() throws {
        let repository = StubProfileRepository()
        repository.favoriteMovies = .success([
            MovieEntity(id: 1, title: "Arrival", overview: "", posterPath: nil, voteAverage: 7.9, releaseDate: nil),
        ])
        repository.favoriteTVShows = .success([
            TVShowEntity(id: 2, name: "Fargo", overview: "", posterPath: nil, firstAirDate: "2014-04-15", voteAverage: 8.3),
        ])
        repository.watchlistTVShows = .success([
            TVShowEntity(id: 3, name: "Severance", overview: "", posterPath: nil, firstAirDate: "2022-02-18", voteAverage: 8.4),
        ])

        let profile = try run(DefaultGetProfileUseCase(repository: repository)).get()

        XCTAssertEqual(profile.accountInfo.username, "mrclient")
        XCTAssertEqual(profile.favoriteMovies?.map(\.title), ["Arrival"])
        XCTAssertEqual(profile.favoriteTVShows?.map(\.name), ["Fargo"])
        XCTAssertEqual(profile.watchlistTVShows?.map(\.name), ["Severance"])
    }

    func testExecutePassesTheResolvedAccountIdToEveryListCall() throws {
        let repository = StubProfileRepository()

        _ = try run(DefaultGetProfileUseCase(repository: repository)).get()

        XCTAssertEqual(repository.requestedAccountIds, ["42", "42", "42"])
    }

    func testExecuteFailsWhenTheAccountLookupFails() {
        let repository = StubProfileRepository()
        repository.accountInfo = .failure(ProfileTestError(message: "not signed in"))

        let outcome = run(DefaultGetProfileUseCase(repository: repository))

        XCTAssertEqual(outcome.testError?.message, "not signed in")
        XCTAssertTrue(repository.requestedAccountIds.isEmpty)
    }

    func testExecuteFailsWhenAnyListFails() {
        let repository = StubProfileRepository()
        repository.favoriteTVShows = .failure(ProfileTestError(message: "tv is down"))

        let outcome = run(DefaultGetProfileUseCase(repository: repository))

        XCTAssertEqual(outcome.testError?.message, "tv is down")
    }
}

private extension Result {
    var testError: ProfileTestError? {
        if case let .failure(error) = self { return error as? ProfileTestError }
        return nil
    }
}
